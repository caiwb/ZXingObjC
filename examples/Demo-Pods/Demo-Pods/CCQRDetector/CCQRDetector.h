//
//  CCQRDetector.h
//  Demo-Pods
//
//  Created by caiwb on 2019/1/22.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCQRDetector : NSObject

+ (instancetype)detector;

- (UIImage *)cropQRCodeFromImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
