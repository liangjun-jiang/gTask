//
//  TaskTasksViewController.h
//  gTask
//
//  Created by LIANGJUN JIANG on 3/26/13.
//
//

#import <UIKit/UIKit.h>
#import "GTLTasks.h"
#import "TaskListViewController.h"

@interface TaskTasksViewController : UITableViewController
{
    GTLTasksTaskList *selectedTasklist;
    GTLServiceTasks *tasksService;
}

@property (nonatomic, strong) GTLTasksTaskList *selectedTasklist;
@property (nonatomic,strong) GTLServiceTasks *tasksService;
@end
