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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startBenchmark];
    });
}

- (void)startBenchmark {
    // load imgs
    NSInteger count = 185;
    NSMutableArray *imgs = [[NSMutableArray alloc] initWithCapacity:count];
    for (NSInteger i = 1; i <= count; i ++) {
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
    
    __block NSInteger sucCount = 0;
    NSMutableArray *zxingFailedArr = [[NSMutableArray alloc] init];
    
    // ZXing
    benchmark(^{
        ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
        [imgs enumerateObjectsUsingBlock:^(UIImage *img, NSUInteger idx, BOOL * _Nonnull stop) {
            ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:img.CGImage];
            ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
            
            NSError *error = nil;
            ZXDecodeHints *hints = [ZXDecodeHints hints];
            
            ZXResult *result = [reader decode:bitmap hints:hints error:&error];
            NSString *contents = result.text;
            if (contents.length) {
                sucCount ++;
            }
            else {
                [zxingFailedArr addObject:@(idx + 1)];
            }
            [reader reset];
        }];
    }, ^(double ms) {
        NSLog(@"**********************");
        NSLog(@"ZXing detecte suc: %zd", sucCount);
        NSLog(@"ZXing cost: %lf ms", ms);
        sucCount = 0;
        
        NSLog(@"**********************");
        NSLog(@"ZXing failed list:");
        NSMutableString *names = [NSMutableString string];
        for (NSString *name in zxingFailedArr) {
            [names appendString:[NSString stringWithFormat:@"%@, ", name]];
        }
        NSLog(@"%@", names);
        NSLog(@"**********************");
        NSLog(@"\n");
    });
    
    NSMutableArray *cidetFailedArr = [[NSMutableArray alloc] init];
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
        
        NSLog(@"**********************");
        NSLog(@"CIDetector failed list:");
        NSMutableString *names = [NSMutableString string];
        for (NSString *name in cidetFailedArr) {
            [names appendString:[NSString stringWithFormat:@"%@, ", name]];
        }
        NSLog(@"%@", names);
        NSLog(@"**********************");
        NSLog(@"\n");
    });
    
    NSMutableDictionary<NSNumber *, NSError *> *mixedFailedList = [[NSMutableDictionary alloc] init];
    // Optimize ZXing + CIDetector
    benchmark(^{
        NSArray *angles = @[@(0), @(90), @(1800), @(270), @(360)];
        
        ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        
        [imgs enumerateObjectsUsingBlock:^(UIImage *img, NSUInteger idx, BOOL * _Nonnull stop) {
            
            for (NSNumber *rotateAngles in angles) {
                CGImageRef cgimage = [self rotateImage:img.CGImage degrees:rotateAngles.doubleValue];
                ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:cgimage];
                ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
                
                NSError *error = nil;
                ZXDecodeHints *hints = [ZXDecodeHints hints];
                hints.tryHarder = YES;
                ZXDecodeHints *pureHints = [hints copy];
                pureHints.pureBarcode = YES;
                
                ZXResult *result = [reader decode:bitmap hints:hints error:&error];
                if (!result) {
                    result = [reader decode:bitmap hints:pureHints error:&error];
                }
                NSString *contents = result.text;
                
                if (!result) {
                    CIQRCodeFeature *features = (CIQRCodeFeature *)[[detector featuresInImage:[CIImage imageWithCGImage:cgimage]] firstObject];
                    contents = features.messageString;
                }
                
                if (contents.length) {
                    sucCount ++;
                    break;
                }
                else if ([rotateAngles isEqualToNumber:@(360)]) {
                    [mixedFailedList setObject:error forKey:@(idx + 1)];
                }
                [reader reset];
            }
        }];
    }, ^(double ms) {
        NSLog(@"**********************");
        NSLog(@"Mix detecte suc: %zd", sucCount);
        NSLog(@"Mix cost: %lf ms", ms);
        sucCount = 0;
        
        NSLog(@"**********************");
        NSLog(@"Mix failed list:");
        NSMutableString *names = [NSMutableString string];
        for (NSNumber *name in mixedFailedList.allKeys) {
            [names appendString:[NSString stringWithFormat:@"%@: %zd, ", name, mixedFailedList[name].code]];
        }
        NSLog(@"%@", names);
        NSLog(@"**********************");
        NSLog(@"\n");
    });
}

- (CGImageRef)rotateImage:(CGImageRef)original degrees:(double)degrees {
    if (degrees == 0.0f) {
        return original;
    }
    double radians = -1 * degrees * (M_PI / 180);
    
    CGRect imgRect = CGRectMake(0, 0, CGImageGetWidth(original), CGImageGetHeight(original));
    CGAffineTransform transform = CGAffineTransformMakeRotation(radians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 rotatedRect.size.width,
                                                 rotatedRect.size.height,
                                                 CGImageGetBitsPerComponent(original),
                                                 0,
                                                 colorSpace,
                                                 kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(context, FALSE);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGColorSpaceRelease(colorSpace);
    
    CGContextTranslateCTM(context,
                          +(rotatedRect.size.width/2),
                          +(rotatedRect.size.height/2));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-imgRect.size.width / 2,
                                           -imgRect.size.height / 2,
                                           imgRect.size.width,
                                           imgRect.size.height), original);
    
    CGImageRef rotatedImage = CGBitmapContextCreateImage(context);
    CFRelease(context);
    
    return rotatedImage;
}

@end
