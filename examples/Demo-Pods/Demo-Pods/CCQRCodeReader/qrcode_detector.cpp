//
//  qrcode_detector.cpp
//  Demo-Pods
//
//  Created by caiwb on 2019/1/30.
//  Copyright © 2019 caiwb. All rights reserved.
//

#include "qrcode_detector.hpp"

static int const kBlockSizeInit = 11;
static int const kDeltaInit     = 27;

static int const kMaxBlockSize  = kBlockSizeInit;
static int const kMinDelta      = -(kDeltaInit);

static int const kBlockStep     = 4;
static int const kDeltaStep     = 4;

namespace ccqr {

void QRDetector::setCallback(const DetectQRSquareCallback &callback) {
    m_callback = callback;
}
    
double QRDetector::computeAngle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
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

bool QRDetector::isSimilarSquare(std::vector<cv::Point> points) {
    cv::Mat target = cv::Mat(points);
    std::vector<cv::Point> approx;
    
    cv::approxPolyDP(target, approx, cv::arcLength(target, true) * 0.25 * 0.3, true);
    if (approx.size() == 4 && cv::isContourConvex(cv::Mat(approx))) {
        double area;
        area = fabs(cv::contourArea(cv::Mat(approx)));
        if (area < 50 * 50) {
            return false;
        }
        double maxCosine = 0.0;  // cos 90°
        for (int j = 2; j < 5; j++) {
            // find the maximum cosine of the angle between joint edges
            double cosine = fabs(computeAngle(approx[j % 4], approx[j - 2], approx[j - 1]));
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
    
void QRDetector::detectQRCode(cv::Mat src) {
    CV_Assert(!src.empty());
    CV_Assert(src.depth() == CV_8U);
    
    int cn = src.channels();
    if (cn == 3 || cn == 4) {
        cv::Mat gray;
        cvtColor(src, gray, cv::COLOR_BGR2GRAY);
        m_gray = cv::Mat(gray);
    }
    else {
        m_gray = cv::Mat(src);
    }
    
    cv::Mat input = m_gray.clone();
    if (m_callback(input)) {
        return;
    }
    
    for (m_thresh = 270; m_thresh > 100; m_thresh -= 50) {
        if (tryDetectingQRCode(input)) {
            return;
        }
    }
    
    m_blockSize = kBlockSizeInit;
    m_delta = kDeltaInit;
    
    for (; m_delta >= kMinDelta; m_delta -= kDeltaStep) {
        if (tryDetectingQRCode(input)) {
            return;
        }
    }
}
    
bool QRDetector::tryDetectingQRCode(cv::Mat src) {
    bool ret = false;
    cv::Mat output;
    
    // threshold
    if (m_thresh > 100) {
        cv::ThresholdTypes type = m_thresh > 255 ? cv::THRESH_OTSU : cv::THRESH_BINARY;
        cv::threshold(src, output, m_thresh, 255, type);
        ret = m_callback(output);
        if (ret) {
            return true;
        }
    }
    else {
        cv::adaptiveThreshold(src, output, 255, CV_ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, m_blockSize, m_delta);
    }
    
    
    return ret;
}
    
bool QRDetector::detectSquare(cv::Mat src, std::vector<std::vector<cv::Point>>contours, std::vector<cv::Vec4i>hierarchy) {
    cv::Mat output = cv::Mat(src);
    cv::Mat debug = cv::Mat::zeros(src.size(), CV_8UC3);
    
    for (size_t i = 0; i < contours.size(); i ++) {
        if (!isSimilarSquare(contours[i])) {
            continue;
        }
        cv::Rect rect = cv::boundingRect(contours[i]);
        cv::Mat result = m_gray(rect);
        int minLine = std::min(result.rows, result.cols);
        
        double scale = 256.f / minLine;
        cv::Size size = cv::Size(result.cols * scale, result.rows * scale);
        cv::resize(result, result, size);
        
        cv::drawContours(debug, contours, static_cast<int>(i), cv::Scalar(255, 0, 0), 2, 8);
        
        cv::Mat toCheck = cv::Mat(result);
        for (int i = -1; i < 255; i += 50) {
            if (m_callback(toCheck)) {
                return true;
            }
            else {
                int type = i <= 0 ? cv::THRESH_OTSU : cv::THRESH_BINARY;
                cv::threshold(result, toCheck, i, 255, type);
            }
        }
    }
    
    return false;
}
    
} // namespace ccqr


/*
 cv::Mat output;
 if (src.type() != CV_8UC1) {
 cv::cvtColor(src, output, CV_BGR2GRAY);
 }
 else {
 output = src.clone();
 }
 
 cv::GaussianBlur(output, output, cv::Size(5, 5), cv::BORDER_CONSTANT);
 if (self.thresholdType == CCQRDetectorThresholdTypeCommon) {
 int type = self.thresh <= 0 ? cv::THRESH_OTSU : cv::THRESH_BINARY;
 cv::threshold(output, output, self.thresh, 255, type);
 }
 else {
 cv::adaptiveThreshold(output, output, 255, CV_ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, self.thBlockSize, self.thDelta);
 }
 
 if ([self.delegate respondsToSelector:@selector(didDetectQRCode:fromImage:)]) {
 [self.delegate didDetectQRCode:self fromImage:MatToUIImage(output)];
 }
 return YES;
 
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
 else if (self.processType == CCQRDetectorProcessTypeHasDetect) {
 // 如果已经找到二维码，但是解码失败，则不进入下一步，直接重试
 return NO;
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
 */

/*
 
 //    for (int thresh = -1; thresh < 255; thresh += 50) {
 //        self.thresh = thresh;
 //        if ([self processCvMat:_gray]) {
 //            return;
 //        }
 //    }
 
 self.thresholdType = CCQRDetectorThresholdTypeAdaptive;
 
 for ( ; self.thBlockSize <= kMaxBlockSize; self.thBlockSize += kBlockSizeStep) {
 for ( ; self.thDelta >= kMinDelta; self.thDelta -= kDeltaStep) {
 if ([self processCvMat:_gray]) {
 return;
 }
 }
 }
 */
