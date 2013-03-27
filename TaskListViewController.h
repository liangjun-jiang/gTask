//
//  TaskListViewController.h
//  gTask
//
//  Created by LIANGJUN JIANG on 3/22/13.
//
//

#import <UIKit/UIKit.h>
#import "GTLTasks.h"

extern NSString* const kTaskStatusCompleted;
extern NSString* const kTaskStatusNeedsAction;


@interface TaskListViewController : UITableViewController{
    GTLServiceTasks *tasksService;
    
}

@property (nonatomic,strong) GTLServiceTasks *tasksService;
@end
