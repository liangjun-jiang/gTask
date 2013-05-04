//
//  SHCViewController.h
//  ClearStyle
//
//  Created by Colin Eberhardt on 23/08/2012.
//  Copyright (c) 2012 Colin Eberhardt. All rights reserved.
//

#import "SHCTableViewCellDelegate.h"
#import "SHCTableView.h"
#import "Constants.h"
#import <UIKit/UIKit.h>
#import "GTLTasks.h"
#import "SecondTopViewController.h"

@interface SHCViewController : SecondTopViewController <SHCTableViewCellDelegate, SHCTableViewDataSource>
@property (weak, nonatomic) IBOutlet SHCTableView *tableView;
@property (nonatomic, strong) GTLTasksTaskList *selectedTasklist;
@property (nonatomic,strong) GTLServiceTasks *tasksService;

@end
