//
//  TaskNoteViewController.h
//  gTask
//
//  Created by LIANGJUN JIANG on 3/31/13.
//
//

#import <UIKit/UIKit.h>
#import "GTLTasks.h"

@interface TaskNoteViewController : UIViewController

@property (nonatomic, strong) GTLTasksTask *task;
-(id)initWithTask:(GTLTasksTask *)mTask;
@end
