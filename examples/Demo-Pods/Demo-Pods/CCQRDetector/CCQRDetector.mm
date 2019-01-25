//
//  CCQRDetector.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/24.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "imgcodecs/ios.h"

#import "CCQRDetector.h"
#import "ZXingObjCQRCode.h"
#import "UIView+Tips.h"

typedef NS_ENUM(NSInteger, CCQRDetectorProcessType) {
    CCQRDetectorProcessType_FirstTry,
};

void    showDebugTips(id tips);
double  angleWithSquarePoints(cv::Point pt1, cv::Point pt2, cv::Point pt0);
bool    isGoalSquare(std::vector<cv::Point> points);

#define kBlockSizeInit 11
#define kDeltaInit 27

#define kBlockSizeStep 4
#define kDeltaStep 4

#define kMaxBlockSize kBlockSizeInit
#define kMinDelta -(kDeltaInit)

//#define kMaxBlockSize 81
//#define kMinDelta -25

@interface CCQRDetector ()

@property (nonatomic, assign) id<CCQRDetectorDelegate> delegate;

@property (nonatomic, strong) UIImage *srcImage;

@property (nonatomic, assign) CCQRDetectorProcessType processType;

// threshold
@property (nonatomic, assign) int thBlockSize;

@property (nonatomic, assign) int thDelta;

@end

@implementation CCQRDetector {
    cv::Mat _src;
    cv::Mat _gray;
    std::vector<cv::Mat> _pendingMatrixs;
}

+ (instancetype)detectQRCodeFromImage:(UIImage *)image delegate:(id <CCQRDetectorDelegate>)delegate {
    CCQRDetector *detector = [[CCQRDetector alloc] init];
    detector.delegate = delegate;
    
    // threshold
    detector.thBlockSize = kBlockSizeInit;
    detector.thDelta = kDeltaInit;
    
    [detector detectQRCodeFromImage:image];
    return detector;
}

#pragma mark - CCQRDetector

- (void)detectQRCodeFromImage:(UIImage *)image {
    if ([self detectQRCodeByZXingFromImage:image]) {
        return;
    }
    // 进入图像预处理流程
    cv::Mat src;
    UIImageToMat(image, src);
    _src = src.clone();
    cv::cvtColor(src, _gray, CV_BGR2GRAY);
    
    self.processType = CCQRDetectorProcessType_FirstTry;
    
    for ( ; self.thBlockSize <= kMaxBlockSize; self.thBlockSize += kBlockSizeStep) {
        for ( ; self.thDelta >= kMinDelta; self.thDelta -= kDeltaStep) {
            if ([self processCvMat:_gray]) {
                return;
            }
        }
    }
    NSLog(@"CCQRDetector Failed");
}

- (BOOL)processCvMat:(cv::Mat)src {
    cv::Mat output;
    if (src.type() != CV_8UC1) {
        cv::cvtColor(src, output, CV_BGR2GRAY);
    }
    else {
        output = src.clone();
    }
    
    cv::GaussianBlur(output, output, cv::Size(5, 5), cv::BORDER_CONSTANT);
    cv::adaptiveThreshold(output, output, 255, CV_ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, self.thBlockSize, self.thDelta);
    
    BOOL ret = [self checkCvMat:output];
    if (ret) {
        return YES;
    }
    
    // scale to 265
    cv::Mat scaled;
    double scale = 256.f / std::min(output.rows, output.cols);
    cv::Size size = cv::Size(output.cols * scale, output.rows * scale);
    cv::resize(output, scaled, size);
    ret = [self checkCvMat:scaled];
    if (ret) {
        return YES;
    }

    cv::Canny(output, output, 50, 200);
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_NONE, cv::Point(0, 0));

    // todo: detect pattern
    //
    
    // detect square
    ret = [self detectSquare:output contours:contours hierarchy:hierarchy];
    if (ret) {
        return YES;
    }
    return NO;
}

- (BOOL)detectSquare:(cv::Mat)src contours:(std::vector<std::vector<cv::Point>>)contours hierarchy:(std::vector<cv::Vec4i>)hierarchy {
    cv::Mat output = src.clone();;
    cv::Mat debug = cv::Mat::zeros(src.size(), CV_8UC3);

    for (size_t i = 0; i < contours.size(); i ++) {
        if (!isGoalSquare(contours[i])) {
            continue;
        }
        cv::Rect rect = cv::boundingRect(contours[i]);
        cv::Mat result = _gray(rect);
        int minLine = std::min(result.rows, result.cols);
        
        double scale = 256.f / minLine;
        cv::Size size = cv::Size(result.cols * scale, result.rows * scale);
        cv::resize(result, result, size);
    
        cv::drawContours(debug, contours, static_cast<int>(i), cv::Scalar(255, 0, 0), 2, 8);
    
        cv::Mat toCheck;
        for (int i = 50; i <= 200; i += 50) {
            if ([self checkCvMat:result]) {
                return YES;
            }
            else {
                cv::threshold(result, toCheck, 100, 255, cv::THRESH_OTSU);
            }
        }
    }
    
    return NO;
}

#pragma mark - result

- (BOOL)checkCvMat:(cv::Mat)matrix {
    UIImage *image = MatToUIImage(matrix);
    BOOL ret = [self detectQRCodeByZXingFromImage:image];
    return ret;
}

#pragma mark - detector by zxing

- (BOOL)detectQRCodeByZXingFromImage:(UIImage *)image {
    NSError *error;
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    ZXBitMatrix *mat = [bitmap blackMatrixWithError:&error];
    
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    hints.tryHarder = YES;
    ZXDecodeHints *pureHints = [hints copy];
    pureHints.pureBarcode = YES;
    
    ZXQRCodeDetector *zxDetector = [[ZXQRCodeDetector alloc] initWithImage:mat];
    ZXDetectorResult *detectResult = [zxDetector detect:hints error:&error];
    if (!detectResult) {
        detectResult = [zxDetector detect:pureHints error:&error];
    }
    if (!detectResult) {
        return NO;
    }
    if ([self.delegate respondsToSelector:@selector(didDetectQRCode:fromImage:)]) {
        [self.delegate didDetectQRCode:self fromImage:image];
    }
    
//    CGImageRef cgimage = [self rotateImage:img.CGImage degrees:rotateAngles.doubleValue];
    ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
    ZXResult *decodeResult = [reader decode:bitmap hints:hints error:&error];
    if (!decodeResult) {
        decodeResult = [reader decode:bitmap hints:pureHints error:&error];
    }
    NSString *contents = decodeResult.text;

    if (!decodeResult) {
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        CIQRCodeFeature *features = (CIQRCodeFeature *)[[detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]] firstObject];
        contents = features.messageString;
    }
    
    if (contents.length) {
        if ([self.delegate respondsToSelector:@selector(didDecodeQRCode:resultContent:)]) {
            [self.delegate didDecodeQRCode:self resultContent:contents];
        }
        return YES;
    }
    NSLog(@"CCQRDetector Failed: %@", error);
    return NO;
}


/*
 - (BOOL)detectQRCodePattern:(cv::Mat)src contours:(std::vector<std::vector<cv::Point>>)contours
 hierarchy:(std::vector<cv::Vec4i>)hierarchy shouldPending:(BOOL)shouldPending
 patternContours:(std::vector<size_t> &)patternContours {
 cv::Mat output = src.clone();;
 cv::Mat debug = cv::Mat::zeros(src.size(), CV_8UC3);
 
 std::vector<std::vector<size_t>> allDectedContours;
 std::vector<size_t> allDectedIndexs;
 
 //    showDebugTips(MatToUIImage(output));
 
 for (size_t t = 0; t < contours.size(); t ++) {
 if (std::find(allDectedIndexs.begin(), allDectedIndexs.end(), t) != allDectedIndexs.end()) {
 // contains
 continue;
 }
 
 cv::drawContours(debug, contours, static_cast<int>(t), CV_RGB(255, 255, 255), 1, 8);
 size_t k = t;
 int c = 0;
 
 std::vector<size_t> dectedContour;
 while (hierarchy[k][2] != -1) {
 dectedContour.push_back(k);
 k = hierarchy[k][2];
 c ++;
 }
 if (c >= 5) {
 allDectedContours.push_back(dectedContour);
 patternContours.push_back(dectedContour[0]);
 allDectedIndexs.insert(allDectedIndexs.end(), dectedContour.begin(), dectedContour.end());
 }
 }
 for (size_t t = 0; t < allDectedContours.size(); t ++) {
 for (size_t m = 0; m < allDectedContours[t].size(); m ++) {
 cv::drawContours(debug, contours, static_cast<int>(allDectedContours[t][m]), CV_RGB(0, 0, 255), 1, 8);
 }
 }
 
 showDebugTips(MatToUIImage(debug));
 if (patternContours.size() == 3) {
 return YES;
 }
 
 return NO;
 }*/

@end

#pragma mark - Utils

double angleWithSquarePoints(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    double ratio;
    ratio = (dx1 * dx1 + dy1 * dy1) / (dx2 * dx2 + dy2 * dy2);
    if (ratio < 0.5 || 1.5 < ratio) {
        return -1;
    }
    return (dx1 * dx2 + dy1 * dy2) / sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
}

bool isGoalSquare(std::vector<cv::Point> points) {
    cv::Mat target = cv::Mat(points);
    std::vector<cv::Point> approx;
    
    // 0.05为将毛边拉直的系数
    cv::approxPolyDP(target, approx, cv::arcLength(target, true) * 0.02, true);
    if (approx.size() == 4 && cv::isContourConvex(cv::Mat(approx))) {
        double area;
        area = fabs(cv::contourArea(cv::Mat(approx)));
        if (area < 50 * 50) {
            return false;
        }
        double maxCosine = 0.0;  // cos 90°
        for (int j = 2; j < 5; j++) {
            // find the maximum cosine of the angle between joint edges
            double cosine = fabs(angleWithSquarePoints(approx[j % 4], approx[j - 2], approx[j - 1]));
            maxCosine = MAX(maxCosine, cosine);
            if (maxCosine >= 1.0) {
                break;
            }
        }
        
        // if cosines of all angles are small
        // (all angles are ~90 degree) then write quandrange
        // vertices to resultant sequence
        if (maxCosine < 0.1) {
            return true;
        }
    }
    return false;
}

//#define DEBUG_WINDOW

void showDebugTips(id tips) {
#ifdef DEBUG_WINDOW
    NSTimeInterval time = 2;
    if ([tips isKindOfClass:[NSString class]]) {
        [KEY_WINDOW showTextHUD:(NSString *)tips duration:time];
    }
    else if ([tips isKindOfClass:[UIView class]]) {
        [KEY_WINDOW showViewHUD:(UIView *)tips duration:time];
    }
    else if ([tips isKindOfClass:[UIImage class]]) {
        [KEY_WINDOW showViewHUD:[[UIImageView alloc] initWithImage:(UIImage *)tips] duration:time];
    }
#endif
}
