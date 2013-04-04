//


#import <UIKit/UIKit.h>
#import "GTLTasks.h"

@interface TaskTasksDetailViewController : UITableViewController
@property (nonatomic, strong) GTLTasksTask *task;
-(id)initWithTask:(GTLTasksTask *)mTask;
@end
