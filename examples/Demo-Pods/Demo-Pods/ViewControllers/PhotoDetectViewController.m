//
//  PhotoDetectViewController.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/21.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "PhotoDetectViewController.h"
#import "ZXingObjCQRCode.h"

@import AssetsLibrary;
@import Photos;

@interface PhotoDetectViewController ()

@end

@implementation PhotoDetectViewController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Do any additional setup after loading the view.
#define UseAL 0
#if UseAL
    [self getFistAssetByALLib];
#else
    [self getFistAssetByPHLib];
#endif
}

- (void)getFistAssetByALLib {
    ALAssetsLibrary *assetsLibrary = [ALAssetsLibrary new];
    __weak typeof(self) weakSelf = self;
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!group.numberOfAssets) {
            return;
        }
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                [weakSelf gotAsset:result];
                *stop = YES;
            }
        }];
    } failureBlock:^(NSError *error) {
        NSLog(@"Read asset failed");
    }];
}

- (void)getFistAssetByPHLib {
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.fetchLimit = 1;
    NSSortDescriptor *endDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    option.sortDescriptors = @[endDateSort];
    
    PHFetchResult *assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:option];
    PHAsset *asset = assets.firstObject;
    if (!asset) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    PHImageRequestOptions *reqOption = [[PHImageRequestOptions alloc] init];
    reqOption.synchronous = YES;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeAspectFit options:reqOption resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        [weakSelf gotAsset:result];
    }];
}

#pragma mark - Detect QR Code

- (void)gotAsset:(id)asset {
    CGImageRef img = nil;
    
    if ([asset isKindOfClass:[ALAsset class]]) {
        img = ((ALAsset *)asset).thumbnail;
    }
    else if ([asset isKindOfClass:[UIImage class]]) {
        img = ((UIImage *)asset).CGImage;
    }
    if (!img) {
        return;
    }
    
    ZXQRCodeReader *reader = [[ZXQRCodeReader alloc] init];
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:img];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    ZXResult *result = [reader decode:bitmap
                                hints:hints
                                error:&error];
    NSString *contents = result.text;
    ZXBarcodeFormat format = result.barcodeFormat;
    
    if (contents.length && format == kBarcodeFormatQRCode) {
        NSLog(@"detect qrcode: %@", contents);
    }
    else {
        NSLog(@"error: %@", error);
    }
}

#pragma clang diagnostic pop

@end
