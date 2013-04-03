//
//  TaskTasksViewController.m
//  gTask
//
//  Created by LIANGJUN JIANG on 3/26/13.
//
//

#import "TaskTasksViewController.h"
#import "SVProgressHUD.h"
#import "TaskNoteViewController.h"

@interface TaskTasksViewController ()<UIAlertViewDelegate, UIActionSheetDelegate>
{
    UIBarButtonItem *addTaskButton_;
    UIBarButtonItem *renameTaskButton_;
     UIBarButtonItem *deleteTaskButton_;
     UIBarButtonItem *completeTaskButton_;
     UIBarButtonItem *clearTasksButton_;
     UIBarButtonItem *completeAllTasksButton_;
     UIBarButtonItem *deleteAllTasksButton_;
}
@property (strong) GTLTasksTasks *tasks;
@property (strong) GTLServiceTicket *tasksTicket;
@property (strong) NSError *tasksFetchError;

@property (strong) GTLServiceTicket *editTaskTicket;
@property (strong) NSIndexPath *selectedIndexPath;

@end

@implementation TaskTasksViewController
@synthesize selectedTasklist;
@synthesize tasksService;
@synthesize selectedIndexPath;

#pragma mark - 
- (void)displayAlert:(NSString *)title format:(NSString *)format, ... {
    NSString *result = format;
    if (format) {
        va_list argList;
        va_start(argList, format);
        result = [[NSString alloc] initWithFormat:format
                                        arguments:argList];
        va_end(argList);
    }
    [[[UIAlertView alloc] initWithTitle:title message:result delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] show];
}

- (void)displayAlertWithMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"gTask"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - IBAction
- (IBAction)completeTaskClicked:(id)sender {
    [self completeSelectedTask];
}

- (IBAction)clearTasksClicked:(id)sender {
    [self hideCompletedTasks];
}

- (IBAction)completeAllTasksClicked:(id)sender {
    [self completeAllTasks];
}

- (IBAction)deleteAllTasksClicked:(id)sender {
    [self deleteAllTasks];
}

//- (IBAction)showTasksCheckboxClicked:(id)sender {
//    [self fetchTasksForSelectedList];
//}

#pragma mark - UI Related
- (void)updateUI
{
    if (self.tasksTicket != nil) {
        [SVProgressHUD showWithStatus:@"Loading..."];
    } else {
        [SVProgressHUD dismiss];
    }
    
    // Get the description of the selected item, or the feed fetch error
    NSString *resultStr = @"";
    if (self.tasksFetchError) {
        resultStr = [self.tasksFetchError description];
    } else {
        GTLTasksTask *item = [self selectedTask];
        if (item) {
            resultStr = [item description];
        }
    }
    //    [tasksResultTextView_ setString:resultStr];
    
    // Enable tasks buttons
    GTLTasksTask *selectedTask = [self selectedTask];
    BOOL hasTasks = (self.tasks != nil);
    BOOL isTaskSelected = (selectedTask != nil);
    BOOL hasTaskTitle = ([selectedTask.title length] > 0);
    
    [addTaskButton_ setEnabled:(hasTaskTitle && hasTasks)];
    [renameTaskButton_ setEnabled:(hasTaskTitle && isTaskSelected)];
    [deleteTaskButton_ setEnabled:(isTaskSelected)];
    
    BOOL isCompleted = [selectedTask.status isEqual:kTaskStatusCompleted];
    [completeTaskButton_ setEnabled:isTaskSelected];
    [completeTaskButton_ setTitle:(isCompleted ? @"Uncomplete" : @"Complete")];
//    [completeTaskButton_ setTitle:(isCompleted ? @"UC" : @"C")];

    
    NSArray *completedTasks = [self completedTasks];
    NSUInteger numberOfCompletedTasks = [completedTasks count];
    [clearTasksButton_ setEnabled:(numberOfCompletedTasks > 0)];
    
    NSUInteger numberOfTasks = [self.tasks.items count];
    [deleteAllTasksButton_ setEnabled:(numberOfTasks > 0)];
    
    BOOL areAllTasksCompleted = (numberOfCompletedTasks == numberOfTasks);
    [completeAllTasksButton_ setEnabled:(numberOfTasks > 0)];
    [completeAllTasksButton_ setTitle:(areAllTasksCompleted ?
                                       @"Uncomplete All" : @"Complete All")];
//    [completeAllTasksButton_ setTitle:(areAllTasksCompleted ?
//                                       @"UA" : @"CA")];
    
    [self.tableView reloadData];
}

- (NSArray *)toolbarItems
{
    // can we add 7 bar item?
    // Toolbar
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
//    addTaskButton_ = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonSystemItemAdd target:self action:@selector(addATask)];
//    renameTaskButton_ = [[UIBarButtonItem alloc] initWithTitle:@"R" style:UIBarButtonSystemItemEdit target:self action:@selector(renameATask)];
//    deleteTaskButton_ = [[UIBarButtonItem alloc] initWithTitle:@"X" style:UIBarButtonSystemItemDone target:self action:@selector(deleteSelectedTask:)];
//    completeTaskButton_ = [[UIBarButtonItem alloc] initWithTitle:@"C" style:UIBarButtonItemStylePlain target:self action:@selector(completeTaskClicked:)];
//    clearTasksButton_ = [[UIBarButtonItem alloc] initWithTitle:@"Archieve Completed" style:UIBarButtonItemStyleBordered target:self action:@selector(clearTasksClicked:)];
    completeAllTasksButton_ = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"COMPLETE_ALL", @"complete all") style:UIBarButtonItemStyleBordered target:self action:@selector(completeAllTasksClicked:)];
    deleteAllTasksButton_ = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DELETE_ALL", @"delete all") style:UIBarButtonItemStyleBordered target:self action:@selector(deleteAllTasksClicked:)];
    
    
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                             target:nil
                                                                                             action:nil];
//    [items addObject:flexibleSpaceButtonItem];
//    [items addObject:addTaskButton_];
//    [items addObject:flexibleSpaceButtonItem];
//    [items addObject:renameTaskButton_];
//    [items addObject:flexibleSpaceButtonItem];
//    [items addObject:deleteTaskButton_];
//    [items addObject:flexibleSpaceButtonItem];
//
//    [items addObject:completeTaskButton_];
//    [items addObject:flexibleSpaceButtonItem];
//    [items addObject:clearTasksButton_];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:completeAllTasksButton_];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:deleteAllTasksButton_];
    [items addObject:flexibleSpaceButtonItem];
    
    return items;
}

#pragma mark -
#pragma mark - Gesture
- (void)onLongPress:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        UITableViewCell *cell = (UITableViewCell *)[gesture view];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        self.selectedIndexPath = indexPath;
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTION", @"action") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"EDIT_TASK",@"edit title"), NSLocalizedString(@"DELETE_TASK", @"delete"), NSLocalizedString(@"COMPLETE_TASK",@"complete task"), nil];
        [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
        
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
    } else {
        switch (buttonIndex) {
            case 0:  // Edit
                [self renameATask];
                break;
            case 1:  // Delete
            {
                [self deleteSelectedTask];
                break;
            }
            case 2:  // Complete
                [self completeTaskClicked:nil];
                break;
//            case 3:  // Clear
//                [self clearTasksClicked:nil];
//                break;
            
            default:
                break;
        }
        
    }
    
}


#pragma mark - views

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[self toolbarItems]];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addATask)];
    self.navigationItem.rightBarButtonItem = addItem;
    
    [SSThemeManager customizeTableView:self.tableView];
    
    // Long press recognizer
    UILongPressGestureRecognizer *longpressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    [self.tableView addGestureRecognizer:longpressRecognizer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchTasksForSelectedList];
    });
   
      
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.tasks.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Configure the cell...
    GTLTasksTask *task = self.tasks.items[indexPath.row];
    
    NSString *str = task.title;
    
    if ([str length] == 0) {
        // If the task has no title, make one from its identifier
        str = [NSString stringWithFormat:@"untitiled"];//<task %@>", task.identifier];
    }
    
    if ([task.notes length] > 0) {
        // append a pencil to indicate this task has notes
        str = [str stringByAppendingString:@" \u270E"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if ([task.status isEqual:kTaskStatusCompleted]) {
        // append a checkmark to indicate this task has been completed
        // todo: doesn't work
//        NSMutableAttributedString *attributedSring = [[NSMutableAttributedString alloc] initWithString:str];
//        // we only need to add a strike through
//        [attributedSring addAttribute:NSStrikethroughStyleAttributeName
//                                value:[NSNumber numberWithInt:2]
//                                range:NSMakeRange(0, str.length)];
//        
//        // todo: why this doesn't work?
//        [cell.textLabel setAttributedText:attributedSring];
//        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        str = [str stringByAppendingString:@" \u2713"];
    }
    
    if ([task.hidden boolValue]) {
        // append a moon to indicate this task is hidden
        str = [str stringByAppendingString:@" \u263E"];
    }
    
    if ([task.deleted boolValue]) {
        // prepend an X mark if this is a deleted task
//        str = [NSString stringWithFormat:@"\u2717 %@", str];
        DebugLog(@"should be deleted!");
        str = [str stringByAppendingString:@" \u2717"];
    }

    cell.textLabel.text = str;
    cell.textLabel.font = SYSTEM_TEXT_FONT;
    cell.textLabel.textColor = SYSTEM_TEXT_COLOR;
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    // Configure the cell...
    GTLTasksTask *task = self.tasks.items[indexPath.row];
    if ([task.notes length] > 0) {
        TaskNoteViewController *taskNoteViewController = [[TaskNoteViewController alloc] initWithTask:task];
        // Pass the selected object to the new view controller.
        [self.navigationController pushViewController:taskNoteViewController animated:YES];

    } else {
        // we should show fancy actions!
    }
    
}

#pragma mark - Tasks
- (void)fetchTasksForSelectedList {
    self.tasks = nil;
    self.tasksFetchError = nil;
    
    GTLServiceTasks *service = self.tasksService;
    
//    GTLTasksTaskList *selectedTasklist = self.selectedTasklist; //[self selectedTaskList];
    if (selectedTasklist) {
        NSString *tasklistID = selectedTasklist.identifier;
        
        GTLQueryTasks *query = [GTLQueryTasks queryForTasksListWithTasklist:tasklistID];
        //        query.showCompleted = [showCompletedTasksCheckbox_ state];
        //        query.showHidden = [showHiddenTasksCheckbox_ state];
        //        query.showDeleted = [showDeletedTasksCheckbox_ state];
        
        self.tasksTicket = [service executeQuery:query
                               completionHandler:^(GTLServiceTicket *ticket,
                                                   id tasks, NSError *error) {
                                   // callback
                                   [self createPropertiesForTasks:tasks];
                                   
                                   self.tasks = tasks;
                                   self.tasksFetchError = error;
                                   self.tasksTicket = nil;
                                   
                                   
                                   [self updateUI];
                               }];
        [self updateUI];
    }
}

#pragma mark 
// for stupid compatiable purpose
- (GTLTasksTaskList *)selectedTaskList
{
    return self.selectedTasklist;
}

- (GTLTasksTask *)selectedTask {
    //    int rowIndex = [tasksOutline_ selectedRow];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath == nil) {
        indexPath = self.selectedIndexPath;
    }
    if (indexPath.row > -1) {// != nil){
        GTLTasksTask *item = self.tasks.items[indexPath.row];
        return item;
    } else
        return nil;
}

- (NSArray *)completedTasks {
    NSArray *array = [GTLUtilities objectsFromArray:self.tasks.items
                                          withValue:kTaskStatusCompleted
                                         forKeyPath:@"status"];
    return array;
}

#pragma mark - add a task
- (void)addATask {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"New Task"
                          message:@""
                          delegate:self
                          cancelButtonTitle: @"Cancel"
                          otherButtonTitles:@"OK", nil ];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField* titleField = [alert textFieldAtIndex:0];
    titleField.keyboardType = UIKeyboardAppearanceDefault;
    titleField.placeholder = @"Type...";
    alert.tag = 110;
    [alert show];
    
}


- (void)addBTask:(NSString *)taskTitle {
    //    NSString *title = [taskNameField_ stringValue];
    NSString *title = taskTitle;
    if ([title length] > 0) {
        // Make a new task
        GTLTasksTask *task = [GTLTasksTask object];
        task.title = title;
        
        GTLTasksTaskList *tasklist = [self selectedTaskList];
        GTLQueryTasks *query = [GTLQueryTasks queryForTasksInsertWithObject:task
                                                                   tasklist:tasklist.identifier];
        GTLServiceTasks *service = self.tasksService;
        self.editTaskTicket = [service executeQuery:query
                                  completionHandler:^(GTLServiceTicket *ticket,
                                                      id item, NSError *error) {
                                      // callback
                                      self.editTaskTicket = nil;
                                      GTLTasksTask *task = item;
                                      
                                      if (error == nil) {
                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"Updated task list \"%@\"", task.title]];
                                          //                                          [self displayAlert:@"Task Added"
                                          //                                                      format:@"Added task \"%@\"", task.title];
                                          [self fetchTasksForSelectedList];
                                          //                                          [taskNameField_ setStringValue:@""];
                                      } else {
                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                          //                                          [self displayAlert:@"Error"
                                          //                                                      format:@"%@", error];
                                          [self updateUI];
                                      }
                                  }];
        [self updateUI];
    }
}

#pragma mark Rename a Task
- (void)renameATask
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Rename A Task"
                          message:@""
                          delegate:self
                          cancelButtonTitle: @"Cancel"
                          otherButtonTitles:@"OK", nil ];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField* titleField = [alert textFieldAtIndex:0];
    titleField.keyboardType = UIKeyboardAppearanceDefault;
    titleField.placeholder = @"Type...";
    alert.tag = 111;
    [alert show];

    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
    } else {
        if (alertView.tag == 110 || alertView.tag == 111) {
            UITextField *taskString = [alertView textFieldAtIndex:0];
            if (alertView.tag  == 110) {
                [self addBTask:taskString.text];
            } else if(alertView.tag == 111)
                [self renameSelectedTask:taskString.text];
        } else
            // from other alertView
            // might do other things
        {
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
            
        }
        
    }
}


- (void)renameSelectedTask:(NSString *)title{
    if ([title length] > 0) {
        // Rename the selected task
        
        // Rather than update the object with a complete replacement, we'll make
        // a patch object containing just the changes
        GTLTasksTask *patchObject = [GTLTasksTask object];
        patchObject.title = title;
        
        GTLTasksTask *task = [self selectedTask];
        GTLTasksTaskList *tasklist = [self selectedTaskList];
        GTLQueryTasks *query = [GTLQueryTasks queryForTasksPatchWithObject:patchObject
                                                                  tasklist:tasklist.identifier
                                                                      task:task.identifier];
        GTLServiceTasks *service = self.tasksService;
        self.editTaskTicket = [service executeQuery:query
                                  completionHandler:^(GTLServiceTicket *ticket,
                                                      id item, NSError *error) {
                                      // callback
                                      self.editTaskTicket = nil;
                                      GTLTasksTask *task = item;
                                      
                                      if (error == nil) {
                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"Renamed task to \"%@\"", task.title]];
                                          [self displayAlert:@"Task Updated"
                                                                                                format:@"Renamed task to \"%@\"", task.title];
                                                                               [self fetchTasksForSelectedList];
                               
                                      } else {
                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                          //                                          [self displayAlert:@"Error"
                                          //                                                      format:@"%@", error];
                                          [self updateUI];
                                      }
                                  }];
        [self updateUI];
    }
}

#pragma mark Delete a Task

- (void)deleteSelectedTask {
    // Delete a task
    GTLTasksTask *task = [self selectedTask];
    NSString *taskTitle = task.title;
    DebugLog(@"%@",taskTitle);
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    GTLQueryTasks *query = [GTLQueryTasks queryForTasksDeleteWithTasklist:tasklist.identifier
                                                                     task:task.identifier];
    GTLServiceTasks *service = self.tasksService;
    self.editTaskTicket = [service executeQuery:query
                              completionHandler:^(GTLServiceTicket *ticket,
                                                  id item, NSError *error) {
                                  // callback
                                  self.editTaskTicket = nil;
                                  
                                  if (error == nil) {
                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"Deleted task \"%@\"", task.title]];
                                      
                                      [self fetchTasksForSelectedList];
                                      
                                  } else {
                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                      //                                          [self displayAlert:@"Error"
                                      //                                                      format:@"%@", error];
                                      [self updateUI];
                                  }
                                  
                            }];
    [self updateUI];
}

#pragma mark Change a Task's Complete Status

- (void)completeSelectedTask {
    // Mark a task as completed or incomplete
    GTLTasksTask *selectedTask = [self selectedTask];
    GTLTasksTask *patchObject = [GTLTasksTask object];
    
    if ([selectedTask.status isEqual:kTaskStatusCompleted]) {
        // Change the status to not complete
        patchObject.status = kTaskStatusNeedsAction;
        patchObject.completed = [GTLObject nullValue]; // remove the completed date
    } else {
        // Change the status to complete
        patchObject.status = kTaskStatusCompleted;
    }
    
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    GTLQueryTasks *query = [GTLQueryTasks queryForTasksPatchWithObject:patchObject
                                                              tasklist:tasklist.identifier
                                                                  task:selectedTask.identifier];
    GTLServiceTasks *service = self.tasksService;
    self.editTaskTicket = [service executeQuery:query
                              completionHandler:^(GTLServiceTicket *ticket,
                                                  id item, NSError *error) {
                                  // callback
                                  self.editTaskTicket = nil;
                                  GTLTasksTask *task = item;
                                  
                                  if (error == nil) {
                                      NSString *displayStatus;
                                      if ([task.status isEqual:kTaskStatusCompleted]) {
                                          displayStatus = @"complete";
                                      } else {
                                          displayStatus = @"incomplete";
                                      }
                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"Deleted task \"%@\"", task.title]];
                                      //                                      [self displayAlert:@"Task Updated"
                                      //                                                  format:@"Marked task \"%@\" %@", task.title, displayStatus];
                                      [self fetchTasksForSelectedList];
                                  } else {
                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                      //                                      [self displayAlert:@"Error"
                                      //                                                  format:@"%@", error];
                                      [self updateUI];
                                  }
                              }];
    [self updateUI];
}

#pragma mark Hide Completed Tasks

- (void)hideCompletedTasks {
    // Make all completed tasks hidden
    NSArray *previouslyCompletedTasks = [self completedTasks];
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    GTLQueryTasks *query = [GTLQueryTasks queryForTasksClearWithTasklist:tasklist.identifier];
    
    GTLServiceTasks *service = self.tasksService;
    self.editTaskTicket = [service executeQuery:query
                              completionHandler:^(GTLServiceTicket *ticket,
                                                  id item, NSError *error) {
                                  // callback
                                  self.editTaskTicket = nil;
                                  
                                  if (error == nil) {
                                      //                                       [self displayAlertWithMessage:[NSString stringWithFormat:@"Task List Clear"]];
                                      [self displayAlert:@"Task List Clear"
                                                  format:@"Made %lu tasks hidden", (unsigned long) [previouslyCompletedTasks count]];
                                      [self fetchTasksForSelectedList];
                                  } else {
                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                      //                                      [self displayAlert:@"Error"
                                      //                                                  format:@"%@", error];
                                      [self updateUI];
                                  }
                              }];
    [self updateUI];
}

#pragma mark Complete All Tasks

- (void)completeAllTasks {
    // Change all tasks to be completed or uncompleted
    NSArray *completedTasks = [self completedTasks];
    NSUInteger numberOfCompletedTasks = [completedTasks count];
    NSUInteger numberOfTasks = [self.tasks.items count];
    BOOL wereAllTasksCompleted = (numberOfCompletedTasks == numberOfTasks);
    
    // Make a batch of queries to set all tasks to completed or uncompleted
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    
    GTLBatchQuery *batchQuery = [GTLBatchQuery batchQuery];
    
    for (GTLTasksTask *task in self.tasks) {
        GTLTasksTask *patchObject = [GTLTasksTask object];
        
        if (wereAllTasksCompleted) {
            // Change the status to not complete
            patchObject.status = kTaskStatusNeedsAction;
            patchObject.completed = [GTLObject nullValue]; // remove the completed date
        } else {
            // Change the status to complete
            patchObject.status = kTaskStatusCompleted;
        }
        
        GTLQueryTasks *query = [GTLQueryTasks queryForTasksPatchWithObject:patchObject
                                                                  tasklist:tasklist.identifier
                                                                      task:task.identifier];
        [batchQuery addQuery:query];
    }
    
    GTLServiceTasks *service = self.tasksService;
    self.editTaskTicket = [service executeQuery:batchQuery
                              completionHandler:^(GTLServiceTicket *ticket,
                                                  id object, NSError *error) {
                                  // callback
                                  self.editTaskTicket = nil;
                                  
                                  if (error == nil) {
                                      GTLBatchResult *batchResults = (GTLBatchResult *)object;
                                      NSString *status = wereAllTasksCompleted ? @"Uncompleted" : @"Completed";
                                      
                                      NSDictionary *successes = batchResults.successes;
                                      NSDictionary *failures = batchResults.failures;
                                      
                                      NSUInteger numberUpdated = [successes count];
                                      NSUInteger numberFailed = [failures count];
                                      
                                      NSArray *successTasks = [successes allValues];
                                      NSArray *titles = [successTasks valueForKey:@"title"];
                                      NSString *titlesStr = [titles componentsJoinedByString:@", "];
                                      
                                      [self displayAlert:@"Tasks Updated"
                                                  format:@"%@: %lu\n%@\nErrors: %lu\n%@",
                                       status,
                                       (unsigned long) numberUpdated, titlesStr,
                                       (unsigned long) numberFailed, failures];
                                      
                                      [self fetchTasksForSelectedList];
                                  } else {
                                      [self displayAlert:@"Error"
                                                  format:@"%@", error];
                                      [self updateUI];
                                  }
                              }];
    [self updateUI];
}

#pragma mark Delete All Tasks

- (void)deleteAllTasks {
    // Make a batch of queries to delete all tasks
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    
    GTLBatchQuery *batch = [GTLBatchQuery batchQuery];
    
    for (GTLTasksTask *task in self.tasks) {
        GTLQueryTasks *query = [GTLQueryTasks queryForTasksDeleteWithTasklist:tasklist.identifier
                                                                         task:task.identifier];
        [batch addQuery:query];
    }
    
    GTLServiceTasks *service = self.tasksService;
    self.editTaskTicket = [service executeQuery:batch
                              completionHandler:^(GTLServiceTicket *ticket,
                                                  id object, NSError *error) {
                                  // callback
                                  self.editTaskTicket = nil;
                                  
                                  if (error == nil) {
                                      GTLBatchResult *batch = (GTLBatchResult *)object;
                                      
                                      NSUInteger numberDeleted = [batch.successes count];
                                      
                                      [self displayAlert:@"Tasks Deleted"
                                                  format:@"Deleted: %lu\nErrors: %@",
                                       (unsigned long) numberDeleted,
                                       batch.failures];
                                      
                                      [self fetchTasksForSelectedList];
                                  } else {
                                      [self displayAlert:@"Error"
                                                  format:@"%@", error];
                                      [self updateUI];
                                  }
                              }];
    [self updateUI];
}

#pragma mark Move Task

- (void)moveTaskWithIdentifier:(NSString *)taskID
                    toParentID:(NSString *)destinationParentIDorNil
                         index:(NSInteger)destinationIndex {
    // Make all completed tasks hidden
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    GTLQueryTasks *query = [GTLQueryTasks queryForTasksMoveWithTasklist:tasklist.identifier
                                                                   task:taskID];
    query.parent = destinationParentIDorNil;
    
    // Determine the ID of the task preceding the new location
    if (destinationIndex > 0) {
        GTLObject *parentTask;
        if (destinationParentIDorNil) {
            parentTask = [self taskWithIdentifier:destinationParentIDorNil
                                        fromTasks:self.tasks];
        } else {
            // There is no parent; it's a top-level task
            parentTask = self.tasks;
        }
        NSArray *children = [self taskChildrenForObject:parentTask];
        
        GTLTasksTask *previousTask = [children objectAtIndex:(destinationIndex - 1)];
        query.previous = previousTask.identifier;
    }
    
    GTLServiceTasks *service = self.tasksService;
    self.editTaskTicket = [service executeQuery:query
                              completionHandler:^(GTLServiceTicket *ticket,
                                                  id item, NSError *error) {
                                  // callback
                                  self.editTaskTicket = nil;
                                  
                                  if (error == nil) {
                                      [self fetchTasksForSelectedList];
                                  } else {
                                      [self displayAlert:@"Error"
                                                  format:@"%@", error];
                                      [self updateUI];
                                  }
                              }];
    [self updateUI];
}

#pragma mark Create ID Map and Ordered Child Arrays

// For the efficient access to tasks in the tasks object, we'll
// build a map from task identifier to each task item, and arrays
// for the children of the top-level object and for the children
// of every parent task

static NSString *const kGTLTaskMapProperty = @"taskMap";
static NSString *const kGTLChildTasksProperty = @"childTasks";

- (void)createPropertiesForTasks:(GTLTasksTasks *)tasks {
    // First, build a dictionary, mapping item identifier strings to items objects
    //
    // This will allow for much faster lookup than would linear search of
    // task list's items
    NSMutableDictionary *taskMap = [NSMutableDictionary dictionary];
    for (GTLTasksTask *task in tasks) {
        [taskMap setObject:task
                    forKey:task.identifier];
    }
    [tasks setProperty:taskMap
                forKey:kGTLTaskMapProperty];
    
    // Make an array for each parent with pointers to its immediate children, in
    // the order the children occur in the list.  We'll store the array in a
    // property of the parent task item.
    //
    // For top-level tasks, we'll store the array in a property of the list
    // object.
    NSMutableArray *topTasks = [NSMutableArray array];
    [tasks setProperty:topTasks
                forKey:kGTLChildTasksProperty];
    
    for (GTLTasksTask *task in tasks) {
        NSString *parentID = task.parent;
        if (parentID == nil) {
            // this is a top-level task in the list, so the task's parent is the
            // main list
            [topTasks addObject:task];
        } else {
            // this task is child of another task; add it to the parent's list
            GTLTasksTask *parentTask = [taskMap objectForKey:parentID];
            NSMutableArray *childTasks = [parentTask propertyForKey:kGTLChildTasksProperty];
            if (childTasks == nil) {
                childTasks = [NSMutableArray array];
                [parentTask setProperty:childTasks
                                 forKey:kGTLChildTasksProperty];
            }
            [childTasks addObject:task];
        }
    }
}

- (GTLTasksTask *)taskWithIdentifier:(NSString *)taskID
                           fromTasks:(GTLTasksTasks *)tasks {
    NSDictionary *taskMap = [tasks propertyForKey:kGTLTaskMapProperty];
    GTLTasksTask *task = [taskMap valueForKey:taskID];
    return task;
}

- (NSArray *)taskChildrenForObject:(GTLObject *)obj {
    // Object is either a GTLTasksTasks (the top-level tasks list)
    // or a GTLTasksTask (a task which may be a parent of other tasks)
    NSArray *array = [obj propertyForKey:kGTLChildTasksProperty];
    return array;
}

#pragma mark OutlineView delegate and data source methods

- (NSArray *)childTasksOfItem:(GTLTasksTask *)item {
    // This is a utility routine for getting the children of a task
    // list or of a task
    //
    // We added child task arrays by calling -createPropertiesForTasks
    // above after fetching the tasks
    NSArray *children;
    if (item == nil) {
        // item is the top level
        children = [self taskChildrenForObject:self.tasks];
    } else {
        // item is a task entry
        children = [self taskChildrenForObject:item];
    }
    return children;
}


//- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
//    NSArray *childTasks = [self childTasksOfItem:item];
//    GTLTasksTask *task = [childTasks objectAtIndex:index];
//    return task;
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
//    NSArray *childTasks = [self childTasksOfItem:item];
//    NSUInteger numberOfChildren = [childTasks count];
//    return (numberOfChildren > 0);
//}
//
//- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
//    NSArray *childTasks = [self childTasksOfItem:item];
//    NSUInteger numberOfChildren = [childTasks count];
//    return numberOfChildren;
//}
//
//- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
//    GTLTasksTask *task = (GTLTasksTask *)item;
//    NSString *str = task.title;
//    
//    if ([str length] == 0) {
//        // If the task has no title, make one from its identifier
//        str = [NSString stringWithFormat:@"<task %@>", task.identifier];
//    }
//    
//    if ([task.notes length] > 0) {
//        // append a pencil to indicate this task has notes
//        str = [str stringByAppendingString:@" \u270E"];
//    }
//    
//    if ([task.status isEqual:kTaskStatusCompleted]) {
//        // append a checkmark to indicate this task has been completed
//        str = [str stringByAppendingString:@" \u2713"];
//    }
//    
//    if ([task.hidden boolValue]) {
//        // append a moon to indicate this task is hidden
//        str = [str stringByAppendingString:@" \u263E"];
//    }
//    
//    if ([task.deleted boolValue]) {
//        // prepend an X mark if this is a deleted task
//        str = [NSString stringWithFormat:@"\u2717 %@", str];
//    }
//    return str;
//}
//
//- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
//    // We want to update the UI when the selection changes, but we need to avoid
//    // doing so immediately as a result of selection changes from reloading the
//    // data when updating the UI, since that would cause recursive calls to
//    // reloadData
//    [self performSelector:@selector(updateUI)
//               withObject:nil
//               afterDelay:0.01];
//}
//
//// OutlineView Dragging Support
//
//- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
//    return NSDragOperationMove;
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView
//         writeItems:(NSArray *)items
//       toPasteboard:(NSPasteboard *)pasteboard {
//    // Only one task can be selected, so one task will be in the items;
//    // we'll put its identifier into an array for the pasteboard
//    NSArray *identifiers = [items valueForKey:@"identifier"];
//    
//    [pasteboard clearContents];
//    [pasteboard writeObjects:identifiers];
//    return YES;
//}
//
//- (NSDragOperation)outlineView:(NSOutlineView *)outlineView
//                  validateDrop:(id <NSDraggingInfo>)info
//                  proposedItem:(id)item
//            proposedChildIndex:(NSInteger)index {
//    // Verify that the item being dragged is a task ID
//    NSPasteboard *pb = [info draggingPasteboard];
//    NSArray *classes = [NSArray arrayWithObject:[NSString class]];
//    NSArray *taskIDs = [pb readObjectsForClasses:classes
//                                         options:nil];
//    if ([taskIDs count] == 1) {
//        NSString *taskID = [taskIDs lastObject];
//        GTLTasksTask *task = [self taskWithIdentifier:taskID
//                                            fromTasks:self.tasks];
//        if (task != nil) {
//            // There is a task object for this ID
//            return NSDragOperationMove;
//        }
//    }
//    return NSDragOperationNone;
//}
//
//- (BOOL)outlineView:(NSOutlineView *)outlineView
//         acceptDrop:(id <NSDraggingInfo>)info
//               item:(id)item
//         childIndex:(NSInteger)index {
//    // A task was dropped at a new location
//    NSPasteboard *pb = [info draggingPasteboard];
//    NSArray *classes = [NSArray arrayWithObject:[NSString class]];
//    NSArray *taskIDs = [pb readObjectsForClasses:classes
//                                         options:nil];
//    
//    [self moveTaskWithIdentifier:[taskIDs objectAtIndex:0]
//                      toParentID:[item identifier]
//                           index:index];
//    return YES;
//}


@end
