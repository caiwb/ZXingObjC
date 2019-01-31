//
//  CCQRCodeReader.h
//  Demo-Pods
//
//  Created by caiwb on 2019/1/24.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CCQRCodeReader;

@protocol CCQRDetectorDelegate <NSObject>

@optional

- (void)didDetectQRCode:(CCQRCodeReader *)reader fromImage:(UIImage *)image;

- (void)didDecodeQRCode:(CCQRCodeReader *)reader fromImage:(UIImage *)image resultContent:(NSString *)content;

@end

@interface CCQRCodeReader : NSObject

+ (instancetype)detectQRCodeFromImage:(UIImage *)image delegate:(id <CCQRDetectorDelegate>)delegate;

@end

