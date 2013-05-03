//
//  TaskListViewController.h
//  gTask
//
//  Created by LIANGJUN JIANG on 3/22/13.
//
//

#import <UIKit/UIKit.h>
#import "GTLTasks.h"
#import "ECSlidingViewController.h"

@interface TaskListViewController : UITableViewController

@property (nonatomic,strong) GTLServiceTasks *tasksService;
@property (nonatomic, weak) IBOutlet UINavigationBar *navBar;
@end
