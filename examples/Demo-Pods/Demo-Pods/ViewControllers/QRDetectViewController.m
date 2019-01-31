//
//  QRDetectViewController.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/22.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "QRDetectViewController.h"
#import "CCQRCodeReader.h"
#import "UIView+Tips.h"

@interface QRDetectViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, CCQRDetectorDelegate>

@end

@implementation QRDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
//    UIImage *image = [UIImage imageNamed:@"scene"];
//    [CCQRCodeReader detectQRCodeFromImage:image delegate:self];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.allowsEditing = YES;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - CCQRDetectorDelegate

- (void)didDetectQRCode:(CCQRCodeReader *)reader fromImage:(UIImage *)image {
    UIImageView *imgv = [[UIImageView alloc] initWithImage:image];
    imgv.contentMode = UIViewContentModeScaleAspectFit;
    imgv.frame = self.view.bounds;
    [self.view addSubview:imgv];
}

- (void)didDecodeQRCode:(CCQRCodeReader *)reader resultContent:(NSString *)content {
    if (content.length) {
        [KEY_WINDOW showTextHUD:content duration:2];
    }
}

- (void)didDecodeQRCode:(CCQRCodeReader *)reader fromImage:(UIImage *)image resultContent:(NSString *)content {
    
    UIImageView *imgv = [[UIImageView alloc] initWithImage:image];
    imgv.contentMode = UIViewContentModeScaleAspectFit;
    imgv.frame = self.view.bounds;
    [self.view addSubview:imgv];
    
    if (content.length) {
        [KEY_WINDOW showTextHUD:content duration:2];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [CCQRCodeReader detectQRCodeFromImage:originalImage delegate:self];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
