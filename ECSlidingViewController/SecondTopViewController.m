//
//  SecondTopViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "SecondTopViewController.h"
#import "TaskListViewController.h"

@implementation SecondTopViewController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[TaskListViewController class]]) {
        TaskListViewController *taskListViewController = [[TaskListViewController alloc] initWithNibName:@"TaskListViewController" bundle:nil];
        self.slidingViewController.underLeftViewController  =  taskListViewController;
    }

  self.slidingViewController.underRightViewController = nil;
  
  [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

- (IBAction)revealMenu:(id)sender
{
  [self.slidingViewController anchorTopViewTo:ECRight];
}

@end
