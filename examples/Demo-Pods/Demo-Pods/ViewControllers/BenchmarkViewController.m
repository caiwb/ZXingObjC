//
//  BenchmarkViewController.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/18.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "BenchmarkViewController.h"
#import <sys/time.h>
#import "ZXingObjCQRCode.h"

@interface BenchmarkViewController ()

@end

@implementation BenchmarkViewController

static inline void benchmark(void (^block)(void), void (^complete)(double ms)) {
    struct timeval t0, t1;
    gettimeofday(&t0, NULL);
    block();
    gettimeofday(&t1, NULL);
    double ms = (double)(t1.tv_sec - t0.tv_sec) * 1e3 + (double)(t1.tv_usec - t0.tv_usec) * 1e-3;
    complete(ms);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    // load imgs
    NSMutableArray *imgs = [[NSMutableArray alloc] initWithCapacity:184];
    for (NSInteger i = 1; i < 185; i ++) {
        NSString *name = [NSString stringWithFormat:@"qr_%zd", i];
        UIImage *img = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"png"]] ?:
                       [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"jpg"]];
        if (img) {
            [imgs addObject:img];
        }
        else {
            NSLog(@"img load failed, %@", name);
        }
    }
    
    __block NSInteger sucCount;
    NSMutableArray *zxingFailedArr = [[NSMutableArray alloc] init];
    NSMutableArray *cidetFailedArr = [[NSMutableArray alloc] init];
    // ZXing
    benchmark(^{
        ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
        [imgs enumerateObjectsUsingBlock:^(UIImage *img, NSUInteger idx, BOOL * _Nonnull stop) {
            ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:img.CGImage];
            ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
            
            NSError *error = nil;
            ZXDecodeHints *hints = [ZXDecodeHints hints];
            ZXResult *result = [reader decode:bitmap
                                        hints:hints
                                        error:&error];
            NSString *contents = result.text;
            ZXBarcodeFormat format = result.barcodeFormat;
            
            if (contents.length && format == kBarcodeFormatQRCode) {
                sucCount ++;
            }
            else {
                [zxingFailedArr addObject:@(idx + 1)];
            }
        }];
    }, ^(double ms) {
        NSLog(@"**********************");
        NSLog(@"ZXing detecte suc: %zd", sucCount);
        NSLog(@"ZXing cost: %lf ms", ms);
        sucCount = 0;
    });
    
    
    // CIDetector
    benchmark(^{
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        [imgs enumerateObjectsUsingBlock:^(UIImage *img, NSUInteger idx, BOOL * _Nonnull stop) {
            CIQRCodeFeature *features = (CIQRCodeFeature *)[[detector featuresInImage:[CIImage imageWithCGImage:img.CGImage]] firstObject];
            NSString *contents = features.messageString;
            if (contents.length) {
                sucCount ++;
            }
            else {
                [cidetFailedArr addObject:@(idx + 1)];
            }
        }];
    }, ^(double ms) {
        NSLog(@"**********************");
        NSLog(@"CIDetector detecte suc: %zd", sucCount);
        NSLog(@"CIDetector cost: %lf ms", ms);
        sucCount = 0;
    });
}

@end
