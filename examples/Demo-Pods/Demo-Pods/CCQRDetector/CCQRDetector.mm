//
//  CCQRDetector.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/22.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "CCQRDetector.h"
#import "imgcodecs/ios.h"
#import "ZXingObjCQRCode.h"
#import "UIView+Tips.h"

//#define QRDebugMode

#define kMaxTryCount 20

@interface CCQRDetector ()

@property (nonatomic, assign) NSInteger retryCount;

@property (nonatomic, strong) NSArray *similarArray;

@end

@implementation CCQRDetector

+ (instancetype)detector {
    return [[CCQRDetector alloc] init];
}

double angleWithSquarePoints(cv::Point pt1, cv::Point pt2, cv::Point pt0);
bool isSquare(std::vector<cv::Point> points);

// 将二维码剪裁出来
- (std::vector<cv::Mat>)cropQRCodeFrameFromImage:(cv::Mat)src {
    cv::Mat srcOrigin = src.clone();
    cv::Mat output, resultAll;
    std::vector<cv::Mat> results;
    
    cv::cvtColor(src, output, CV_BGR2GRAY);
    cv::threshold(output, output, 10, 255, cv::THRESH_OTSU);
//    cv::adaptiveThreshold(output, output, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 83, 2);
    
    resultAll = src.clone();
    cv::Mat resultAllScaled;
    double scale = 256.f / std::min(resultAll.rows, resultAll.cols);
    cv::Size size = cv::Size(resultAll.cols * scale, resultAll.rows * scale);
    cv::resize(resultAll, resultAllScaled, size);
#ifndef QRDebugMode
    results.push_back(resultAllScaled);
#endif
    
    cv::GaussianBlur(output, output, cv::Size(5, 5), cv::BORDER_CONSTANT);
    cv::Canny(output, output, 100, 200);
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(output, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE, cv::Point(0, 0));

#ifdef QRDebugMode
    resultAll = cv::Mat::zeros(src.size(), CV_8UC3);
#endif
    for (size_t i = 0; i < contours.size(); i ++) {
        if (!isSquare(contours[i])) {
            continue;
        }
#ifndef QRDebugMode
        cv::Rect rect = cv::boundingRect(contours[i]);
        cv::Mat result = resultAll(rect);
        int minLine = std::min(result.rows, result.cols);

        double scale = 256.f / minLine;
        cv::Size size = cv::Size(result.cols * scale, result.rows * scale);
        cv::resize(result, result, size);

        results.push_back(result);
    }
#else
        cv::drawContours(resultAll, contours, static_cast<int>(i), cv::Scalar(255, 0, 0), 2, 8);
    }
    results.push_back(resultAll);
#endif

    sort(results.begin(), results.end(), [](const cv::Mat& m1, const cv::Mat& m2) {return m1.rows * m1.cols > m2.rows * m2.cols;});
    return results;
}

- (BOOL)detectQRCodeFromImage:(UIImage *)image {
    // detect src image
    NSError *error;
    BOOL result;
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    ZXBitMatrix *mat = [bitmap blackMatrixWithError:&error];
    
    ZXDecodeHints *hint = [ZXDecodeHints hints];
    hint.tryHarder = YES;
    ZXDecodeHints *pureHint = [hint copy];
    pureHint.pureBarcode = YES;
    
    ZXQRCodeDetector *zxDetector = [[ZXQRCodeDetector alloc] initWithImage:mat];
    result = [zxDetector detect:hint error:&error];
    if (!result) {
        result = [zxDetector detect:pureHint error:&error];
    }
    
    return result;
}

// 可能是QRCode
- (BOOL)isSimilarToQRCode:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    cv::Mat output;
    
    cv::cvtColor(src, output, CV_BGR2GRAY);
//    cv::threshold(output, output, 10, 255, cv::THRESH_OTSU);
//    cv::adaptiveThreshold(output, output, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 83, 2);
    
    threshold(output, output, 112, 255, cv::THRESH_BINARY);
    cv::GaussianBlur(output, output, cv::Size(5, 5), cv::BORDER_CONSTANT);
    cv::Canny(output, output, 100, 200);
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_NONE, cv::Point(0, 0));
//    output = cv::Mat::zeros(src.size(), CV_8UC3);
    
    int count = 0;
    for (size_t t = 0; t < contours.size(); t ++) {
//        cv::drawContours(output, contours, static_cast<int>(t), CV_RGB(255, 255, 255), 1, 8);
        size_t k = t;
        int c = 0;
        std::vector<size_t> indexs;
        while (hierarchy[k][2] != -1) {
            indexs.push_back(k);
            k = hierarchy[k][2];
            c ++;
        }
        if (c >= 5) {
            count ++;
        }
    }
    UIImage *result = MatToUIImage(output);
    if (fabs(result.size.width - result.size.height) < 100) {
        [KEY_WINDOW showViewHUD:[[UIImageView alloc] initWithImage:result] duration:10];
    }
    
    if (count >= 3) {
        return YES;
    }
    
    return NO;
}

- (UIImage *)loopProcessImage:(cv::Mat)src {
    std::vector<cv::Mat> results = [self cropQRCodeFrameFromImage:src];
    
    // 可能是qrcode
    NSMutableArray *similarArray = [[NSMutableArray alloc] initWithCapacity:results.size()];;
    
    for (int i = 0; i < results.size(); i ++) {
        cv::Mat result = results[i];
        UIImage *output = MatToUIImage(result);
#ifdef QRDebugMode
        return output;
#endif
        if ([self detectQRCodeFromImage:output]) {
            NSLog(@"CCQRDetector: detect success");
//            return output;
        }
        if (!self.similarArray.count && [self isSimilarToQRCode:output]) {
            NSLog(@"CCQRDetector: is similar to qrcode");
            [similarArray addObject:output];
        }
    }
    
    if (!similarArray.count) {
        // 相似二维码的正方形都没找到，方案：
        // 1、进行先膨胀再腐蚀处理
        // 2、可能旋转角度过大
        
    }
    else {
        // 已找到，尝试调整二值化阈值
//        self.similarArray = [similarArray copy];
        
    }
    
    NSLog(@"CCQRDetector: detect failed");
    return nil;
}

- (UIImage *)cropQRCodeFromImage:(UIImage *)image {
    if (![self detectQRCodeFromImage:image]) {
        cv::Mat src;
        UIImageToMat(image, src);
        return [self loopProcessImage:src];
    }
    return image;
}

// 计算三点形成的角度
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

// 是否为正方形
bool isSquare(std::vector<cv::Point> points) {
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

@end
