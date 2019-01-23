//
//  QRDetectViewController.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/22.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "QRDetectViewController.h"
#import "CCQRDetector.h"

@interface QRDetectViewController ()

@end

@implementation QRDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *image = [UIImage imageNamed:@"screen_shot_1"];
    image = [[CCQRDetector detector] cropQRCodeFromImage:image];
    
    UIImageView *imgv = [[UIImageView alloc] initWithImage:image];
    imgv.contentMode = UIViewContentModeScaleAspectFit;
    imgv.frame = self.view.bounds;
    [self.view addSubview:imgv];
}

@end
