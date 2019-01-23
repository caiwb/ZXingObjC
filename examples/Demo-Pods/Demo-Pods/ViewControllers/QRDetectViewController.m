//
//  QRDetectViewController.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/22.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "QRDetectViewController.h"
#import "CCQRDetector.h"

@interface QRDetectViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation QRDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
//    UIImage *image = [UIImage imageNamed:@"screen_shot_1"];
//    image = [[CCQRDetector detector] cropQRCodeFromImage:image];
//
//    UIImageView *imgv = [[UIImageView alloc] initWithImage:image];
//    imgv.contentMode = UIViewContentModeScaleAspectFit;
//    imgv.frame = self.view.bounds;
//    [self.view addSubview:imgv];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    controller.allowsEditing = YES;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *qrcode = [[CCQRDetector detector] cropQRCodeFromImage:originalImage];
    UIImageView *imgv = [[UIImageView alloc] initWithImage:qrcode];
    imgv.contentMode = UIViewContentModeScaleAspectFit;
    imgv.frame = self.view.bounds;
    [self.view addSubview:imgv];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
