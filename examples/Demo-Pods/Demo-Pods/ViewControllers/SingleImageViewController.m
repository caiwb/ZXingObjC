//
//  SingleImageViewController.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/18.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "SingleImageViewController.h"
#import "ZXingObjCQRCode.h"

@interface SingleImageViewController ()

@end

@implementation SingleImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSInteger i = 30;
    NSString *name = [NSString stringWithFormat:@"qr_%zd", i];
    UIImage *img = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"png"]] ?:
                   [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"jpg"]];
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:img.CGImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    NSError *error = nil;
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    hints.tryHarder = YES;
    
    ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
    ZXResult *result = [reader decode:bitmap
                                hints:hints
                                error:&error];
    NSString *contents = result.text;
    ZXBarcodeFormat format = result.barcodeFormat;
    
    if (contents.length && format == kBarcodeFormatQRCode) {
        
    }
    else {
        NSLog(@"error: %@", error);
    }
    
    // CIDetector
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    CIQRCodeFeature *features = (CIQRCodeFeature *)[[detector featuresInImage:[CIImage imageWithCGImage:img.CGImage]] firstObject];
    contents = features.messageString;
    NSLog(@"");
}

@end
