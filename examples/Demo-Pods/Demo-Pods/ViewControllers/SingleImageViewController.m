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
    
    NSInteger i = 13;
    NSString *name = [NSString stringWithFormat:@"qr_%zd", i];
    UIImage *img = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"png"]] ?:
    [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"jpg"]];
    
    ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
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
        
    }
    else {
        NSLog(@"error: %@", error);
    }
}

@end
