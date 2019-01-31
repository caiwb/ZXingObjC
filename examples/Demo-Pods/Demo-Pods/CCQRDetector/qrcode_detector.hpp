//
//  qrcode_detector.hpp
//  Demo-Pods
//
//  Created by caiwb on 2019/1/30.
//  Copyright © 2019 caiwb. All rights reserved.
//

#ifndef qrcode_detector_hpp
#define qrcode_detector_hpp

#include <opencv2/opencv.hpp>
#include <stdio.h>

namespace ccqr {
    
typedef std::function<bool (cv::Mat)> DetectQRSquareCallback;
    
class QRDetector {
    
public:
    // 检测可能为二维码的区域
    void detectQRCode(cv::Mat src);

    void setCallback(const DetectQRSquareCallback &callback);
    
private:
    bool tryDetectingQRCode(cv::Mat src);
    
    // 计算夹角
    double computeAngle(cv::Point pt1, cv::Point pt2, cv::Point pt0);
    
    // 是否是正方形
    bool isSimilarSquare(std::vector<cv::Point> points);
    
    bool detectSquare(cv::Mat src, std::vector<std::vector<cv::Point>>contours, std::vector<cv::Vec4i>hierarchy);
    
    DetectQRSquareCallback m_callback;
    
    cv::Mat m_gray;
};
    
} // namespace ccqr

#endif /* qrcode_detector_hpp */
