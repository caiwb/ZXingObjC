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
    
    NSInteger i = 187;
    NSString *name = [NSString stringWithFormat:@"qr_%zd", i];
    UIImage *img = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"png"]] ?:
                   [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"jpg"]];
    img = [UIImage imageNamed:@"living_room_clip"];
    if (!img) {
        return;
    }
        
    ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    
    NSArray *angles = @[@(0), @(90), @(1800), @(270), @(360)];
    
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
            NSLog(@"suc");
            break;
        }
        else if ([rotateAngles isEqualToNumber:@(360)]) {
            NSLog(@"failed");
        }
        [reader reset];
    }
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
