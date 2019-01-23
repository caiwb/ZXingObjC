//
//  UIView+Tips.m
//  Demo-Pods
//
//  Created by caiwb on 2019/1/23.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import "UIView+Tips.h"
#import "MBProgressHUD.h"
#import <objc/runtime.h>

static const void *CCTipsHelperHUDKey = &CCTipsHelperHUDKey;

@implementation UIView (Tips)

- (void)showTextHUD:(NSString *)text duration:(NSTimeInterval)duration {
    [self showHUD:text customView:nil autoNewLine:YES duration:duration];
}

- (void)showViewHUD:(UIView *)customView duration:(NSTimeInterval)duration {
    [self showHUD:nil customView:customView autoNewLine:YES duration:duration];
}

- (void)showHUD:(NSString *)text customView:(UIView *)customView autoNewLine:(BOOL)autoNewLine duration:(NSTimeInterval)duration {
    if (![self.subviews containsObject:self.hud]) {
        [self addSubview:self.hud];
    }
    self.hud.mode = customView ? MBProgressHUDModeCustomView : MBProgressHUDModeText;
    if (autoNewLine) {
        self.hud.detailsLabelText = text;
        self.hud.labelText = @"";
    }
    else {
        self.hud.labelText = text;
        self.hud.detailsLabelText = @"";
    }
    self.hud.customView = customView;
    [self bringSubviewToFront:self.hud];
    self.hud.userInteractionEnabled = NO;
    [self.hud show:YES];
    [self.hud hide:YES afterDelay:duration];
}

- (void)hideHUD {
    if ([self.subviews containsObject:self.hud]) {
        [self.hud hide:NO];
        [self.hud removeFromSuperview];
    }
}

- (MBProgressHUD *)hud {
    MBProgressHUD *hud = objc_getAssociatedObject(self, CCTipsHelperHUDKey);
    if (!hud) {
        hud = [[MBProgressHUD alloc] init];
        hud.mode = MBProgressHUDModeText;
        hud.userInteractionEnabled = NO;
        objc_setAssociatedObject(self, CCTipsHelperHUDKey, hud, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return hud;
}

@end
