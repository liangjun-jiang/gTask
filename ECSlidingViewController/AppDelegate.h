//
//  AppDelegate.h
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECSlidingViewController.h"

#import "Constants.h"
#import "GTLTasks.h"
@class GTMOAuth2Authentication;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *rootViewController;

@property (readonly) GTLServiceTasks *tasksService;
//-(UIViewController *)rootViewController;
+(AppDelegate *)appDelegate;
- (UIStoryboard *)storyBoard;
- (GTMOAuth2Authentication *)auth;
- (void)signOut;

@end
