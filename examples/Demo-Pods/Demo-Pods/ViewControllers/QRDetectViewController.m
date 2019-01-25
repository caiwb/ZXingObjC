//
//  QRDetectViewController.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/22.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "QRDetectViewController.h"
#import "CCQRDetector.h"
#import "UIView+Tips.h"

@interface QRDetectViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, CCQRDetectorDelegate>

@end

@implementation QRDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
//    UIImage *image = [UIImage imageNamed:@"scene"];
//    [CCQRDetector detectQRCodeFromImage:image delegate:self];
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

- (void)didDetectQRCode:(CCQRDetector *)detector fromImage:(UIImage *)image {
    UIImageView *imgv = [[UIImageView alloc] initWithImage:image];
    imgv.contentMode = UIViewContentModeScaleAspectFit;
    imgv.frame = self.view.bounds;
    [self.view addSubview:imgv];
}

- (void)didDecodeQRCode:(CCQRDetector *)detector resultContent:(NSString *)content {
    [KEY_WINDOW showTextHUD:content duration:2];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [CCQRDetector detectQRCodeFromImage:originalImage delegate:self];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
