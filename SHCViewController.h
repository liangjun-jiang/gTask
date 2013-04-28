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

@interface SHCViewController : UIViewController <SHCTableViewCellDelegate, SHCTableViewDataSource>
@property (weak, nonatomic) IBOutlet SHCTableView *tableView;
@property (nonatomic,strong) GTLServiceTasks *tasksService;
@end
