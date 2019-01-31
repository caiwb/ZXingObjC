//
//  CCQRDetector.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/24.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "qrcode_detector.hpp"
#import "imgcodecs/ios.h"

#import "CCQRDetector.h"
#import "ZXingObjCQRCode.h"

@interface CCQRDetector ()

@property (nonatomic, assign) id<CCQRDetectorDelegate> delegate;

@end

@implementation CCQRDetector {
    ccqr::QRDetector _detector;
}

+ (instancetype)detectQRCodeFromImage:(UIImage *)image delegate:(id <CCQRDetectorDelegate>)delegate {
    CCQRDetector *detector = [[CCQRDetector alloc] init];
    detector.delegate = delegate;
    [detector detectQRCodeFromImage:image];
    return detector;
}

#pragma mark - CCQRDetector

- (void)detectQRCodeFromImage:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    
    __weak typeof(self) weakSelf = self;
    BOOL (^callbackBlock)(UIImage *) = ^ BOOL (UIImage *image){
        return [weakSelf detectQRCodeByZXingFromImage:image];
    };
    
    _detector.setCallback([callbackBlock](cv::Mat output) {
        UIImage *outImage = MatToUIImage(output);
        return callbackBlock(outImage);
    });
    _detector.detectQRCode(src);
}

- (BOOL)detectQRCodeByZXingFromImage:(UIImage *)image {
    
    [self.delegate didDetectQRCode:self fromImage:image];
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    
    ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
    ZXResult *result = [reader decode:bitmap hints:hints error:&error];
    NSString *contents = result.text;
    if (contents.length) {
        if ([self.delegate respondsToSelector:@selector(didDecodeQRCode:fromImage:resultContent:)]) {
            [self.delegate didDecodeQRCode:self fromImage:image resultContent:contents];
        }
        return YES;
    }
    return NO;
}

@end
