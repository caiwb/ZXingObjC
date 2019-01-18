//
//  AppDelegate.h
//  Demo-Pods
//
//  Created by caiwb on 2019/1/18.
//  Copyright © 2019 caiwb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

