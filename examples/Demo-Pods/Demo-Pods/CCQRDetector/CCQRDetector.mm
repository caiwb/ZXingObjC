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
#import "TagDetector.h"
#import "qrcode.h"
#import "ZXingObjCQRCode.h"

@implementation CCQRDetector

+ (instancetype)detector {
    return [[CCQRDetector alloc] init];
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

// 通过at找正方形（不太好用）
bool localizationAT(cv::Mat src, std::vector<std::vector<cv::Point>> &contours) {
    TagFamily f("Tag36h11");
    TagDetectorParams params;
    TagDetector detector(f, params);
    
    QuadArray atquads = detector.processQR(src);
    std::vector<ccqr::QRQuad> quads;
    for (int i = 0; i < atquads.size(); i ++) {
        ccqr::QRQuad quad(atquads[i]->p);
        if (quad.selectSelf()) {
            quads.push_back(quad);
        }
    }
    sort(quads.begin(), quads.end(), [](const ccqr::QRQuad& q1, const ccqr::QRQuad& q2) {return q1.areas > q2.areas;});

    std::map<int, std::vector<int>> select;
    for (int i = 0; i < quads.size() - 1; i ++) {
        for (int j = i + 1; j < quads.size(); j ++) {
            if (quads[i].selectSimilar(quads[j]))
                select[i].push_back(j);
        }
    }
    if (select.size() > 0) {
        for (auto sel : select) {
            if (sel.second.size() > 1) {
                return true;
            }
        }
    }
    else {
        // 没有找到二维码，从 quads 中最大的正方形开始找
//        for (int i = 0; i < quads.size() - 1; i ++) {
//
//        }
        for (int i = 0; i < quads.size() - 1; i ++) {
            ccqr::QRQuad quad = quads[i];
            
            std::vector<cv::Point> points(quad.p, quad.p + 4);
            contours.push_back(points);
        }
//        contours[0].push_back(bigest);
    }
    return false;
}

// 将二维码剪裁出来
- (std::vector<cv::Mat>)cropQRCodeFrameFromImage:(cv::Mat)src {
    cv::Mat srcOrigin = src.clone();
    cv::Mat output, resultAll;
    std::vector<cv::Mat> results;
    
    cv::cvtColor(src, output, CV_BGR2GRAY);
//    cv::threshold(output, output, 10, 255, cv::THRESH_OTSU);
    cv::adaptiveThreshold(output, output, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 83, 2);
    
    resultAll = output.clone();
    cv::Mat resultAllScaled;
    double scale = 256.f / min(resultAll.rows, resultAll.cols);
    cv::Size size = cv::Size(resultAll.cols * scale, resultAll.rows * scale);
    cv::resize(resultAll, resultAllScaled, size);
    results.push_back(resultAllScaled);
    
    cv::GaussianBlur(output, output, cv::Size(5, 5), cv::BORDER_CONSTANT);
    cv::Canny(output, output, 100, 200);
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    
//    cv::Mat result = cv::Mat::zeros(src.size(), CV_8UC3);
    for (int i = 0; i < contours.size(); i ++) {
//        cv::drawContours(result, contours, i, cv::Scalar(255, 0, 0), 2, 8);
    }
    cv::findContours(output, contours, hierarchy, RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE, cv::Point(0, 0));

    for (size_t i = 0; i < contours.size(); i++) {
        if (!isSquare(contours[i])) {
            continue;
        }
        cv::Rect rect = cv::boundingRect(contours[i]);
        cv::Mat result = resultAll(rect);
        int minLine = min(result.rows, result.cols);
        
        double scale = 256.f / minLine;
        cv::Size size = cv::Size(result.cols * scale, result.rows * scale);
        cv::resize(result, result, size);
        
        results.push_back(result);
        
//        cv::drawContours(threshold, contours, static_cast<int>(i), cv::Scalar(255, 0, 0), 2, 8);
    }
//    results.push_back(threshold);
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

- (UIImage *)cropQRCodeFromImage:(UIImage *)image {
    if (![self detectQRCodeFromImage:image]) {
        cv::Mat src;
        UIImageToMat(image, src);
        std::vector<cv::Mat> results = [self cropQRCodeFrameFromImage:src];
        for (int i = 0; i < results.size(); i ++) {
            cv::Mat result = results[i];
            UIImage *output = MatToUIImage(result);
//            return output;
            if ([self detectQRCodeFromImage:output]) {
                return output;
            }
        }
        NSLog(@"CCQRDetector: detect failed");
        return nil;
    }
    return image;
}

@end
