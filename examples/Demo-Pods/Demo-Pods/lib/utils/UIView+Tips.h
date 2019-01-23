//
//  UIView+Tips.h
//  Demo-Pods
//
//  Created by caiwb on 2019/1/23.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define KEY_WINDOW [[[UIApplication sharedApplication] delegate] window]

@interface UIView (Tips)

- (void)showTextHUD:(NSString *)text duration:(NSTimeInterval)duration;

- (void)showViewHUD:(UIView *)customView duration:(NSTimeInterval)duration;

- (void)hideHUD;

@end

NS_ASSUME_NONNULL_END
