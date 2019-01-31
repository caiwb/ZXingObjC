//
//  CCQRCodeReader.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/24.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "qrcode_detector.hpp"
#import "imgcodecs/ios.h"

#import "CCQRCodeReader.h"
#import "ZXingObjCQRCode.h"

@interface CCQRCodeReader ()

@property (nonatomic, assign) id<CCQRDetectorDelegate> delegate;

@property (nonatomic, strong) dispatch_queue_t readerQueue;

@end

@implementation CCQRCodeReader {
    ccqr::QRDetector _detector;
}

+ (instancetype)detectQRCodeFromImage:(UIImage *)image delegate:(id <CCQRDetectorDelegate>)delegate {
    CCQRCodeReader *reader = [[CCQRCodeReader alloc] init];
    reader.delegate = delegate;
    reader.readerQueue = dispatch_queue_create("cc.qrcode.serial", DISPATCH_QUEUE_SERIAL);
    [reader detectQRCodeFromImage:image];
    return reader;
}

#pragma mark - CCQRDetector

- (void)detectQRCodeFromImage:(UIImage *)image {
    typeof(self) strongSelf = self;
    dispatch_async(self.readerQueue, ^{
        [strongSelf _detectQRCodeFromImage:image];
    });
}

- (void)_detectQRCodeFromImage:(UIImage *)image {
    cv::Mat src;
    UIImageToMat(image, src);
    
    typeof(self) strongSelf = self;
    BOOL (^callbackBlock)(UIImage *) = ^ BOOL (UIImage *image){
        return [strongSelf detectQRCodeByZXingFromImage:image];
    };
    
    _detector.setCallback([callbackBlock](cv::Mat output) {
        
        cv::Mat scaled;
        double scale = 256.f / std::min(output.rows, output.cols);
        cv::Size size = cv::Size(output.cols * scale, output.rows * scale);
        cv::resize(output, scaled, size);
        return callbackBlock(MatToUIImage(scaled));
    });
    _detector.detectQRCode(src);
}

- (BOOL)detectQRCodeByZXingFromImage:(UIImage *)image {
    CGImage *cgImage = image.CGImage;
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:cgImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    hints.tryHarder = YES;
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    
    ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
    ZXResult *result = [reader decode:bitmap hints:hints error:&error];
    NSString *contents = result.text;
    if (!contents.length) {
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        CIQRCodeFeature *features = (CIQRCodeFeature *)[[detector featuresInImage:[CIImage imageWithCGImage:cgImage]] firstObject];
        contents = features.messageString;
    }
    
    typeof(self) strongSelf = self;
    if (contents.length) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([strongSelf.delegate respondsToSelector:@selector(didDecodeQRCode:fromImage:resultContent:)]) {
                [strongSelf.delegate didDecodeQRCode:strongSelf fromImage:image resultContent:contents];
            }
        });
    }
    return contents.length > 0; 
}

@end
