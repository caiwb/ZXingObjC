//
//  CCQRDetector.h
//  Demo-Pods
//
//  Created by caiwb on 2019/1/24.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CCQRDetector;

@protocol CCQRDetectorDelegate <NSObject>

@optional

- (void)didDetectQRCode:(CCQRDetector *)detector fromImage:(UIImage *)image;

- (void)didDecodeQRCode:(CCQRDetector *)detector resultContent:(NSString *)content;

@end

@interface CCQRDetector : NSObject

+ (instancetype)detectQRCodeFromImage:(UIImage *)image delegate:(id <CCQRDetectorDelegate>)delegate;

@end

