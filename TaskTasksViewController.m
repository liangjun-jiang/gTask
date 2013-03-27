//
//  TaskTasksViewController.m
//  gTask
//
//  Created by LIANGJUN JIANG on 3/26/13.
//
//

#import "TaskTasksViewController.h"

@interface TaskTasksViewController ()
@property (strong) GTLTasksTasks *tasks;
@property (strong) GTLServiceTicket *tasksTicket;
@property (strong) NSError *tasksFetchError;

@property (strong) GTLServiceTicket *editTaskTicket;

@end

@implementation TaskTasksViewController
@synthesize selectedTasklist;
@synthesize tasksService;

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

- (IBAction)showTasksCheckboxClicked:(id)sender {
    [self fetchTasksForSelectedList];
}

#pragma mark - UI Related
- (void)updateUI
{
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[self toolbarItems]];

    if (self.tasksTicket != nil) {
        DebugLog(@"self.tasksTicket is not nil");
        //        [tasksProgressIndicator_ startAnimation:self];
    } else {
        //        [tasksProgressIndicator_ stopAnimation:self];
        DebugLog(@"self.tasksticket is nil");
    }
    
    // Get the description of the selected item, or the feed fetch error
    NSString *resultStr = @"";
    if (self.tasksFetchError) {
        resultStr = [self.tasksFetchError description];
    } else {
        DebugLog(@"the all tasks %@",self.tasks);
//        GTLTasksTask *item = [self selectedTask];
//        if (item) {
//            resultStr = [item description];
//        }
    }
    //    [tasksResultTextView_ setString:resultStr];
    DebugLog(@"this is the task we got: %@", resultStr);

    
    
    [self.tableView reloadData];
}

- (NSArray *)toolbarItems
{
    // Toolbar
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:9];
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                             target:nil
                                                                                             action:nil];
    //add a task item
    UIBarButtonItem *addATaskItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CIALBrowser.bundle/images/browserBack.png"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(addATask)];
    //rename a task item
    UIBarButtonItem *renameATaskItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CIALBrowser.bundle/images/browserForward.png"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(renameSelectedTask:)];
    
    //complete all tasks
    UIBarButtonItem *completeAllItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                     target:self
                                                                     action:@selector(actionButton:)];
    
    //delete all tasks
    UIBarButtonItem *deleteAllItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                        target:self
                                                                                        action:@selector(viewBookmark:)];
    
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:addATaskItem];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:renameATaskItem];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:completeAllItem];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:deleteAllItem];
    [items addObject:flexibleSpaceButtonItem];
    
    return items;
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchTasksForSelectedList];
    });
   
      
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
    }
    
    // Configure the cell...
    GTLTasksTask *item = self.tasks.items[indexPath.row];
    cell.textLabel.text = item.title;
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
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
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
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

#pragma mark - updat another table
- (GTLTasksTask *)selectedTask {
    //    int rowIndex = [tasksOutline_ selectedRow];
    int rowIndex = 0;
    //    GTLTasksTask *item = [tasksOutline_ itemAtRow:rowIndex];
    
    GTLTasksTask *item = self.tasks.items[rowIndex];
    return item;
    //    return nil;
}

- (NSArray *)completedTasks {
    NSArray *array = [GTLUtilities objectsFromArray:self.tasks.items
                                          withValue:kTaskStatusCompleted
                                         forKeyPath:@"status"];
    return array;
}


- (void)addATask {
    //    NSString *title = [taskNameField_ stringValue];
    NSString *title = @"";
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

// for stupid compatiable purpose
- (GTLTasksTaskList *)selectedTaskList
{
    return self.selectedTasklist;
}

- (void)renameSelectedTask {
    //    NSString *title = [taskNameField_ stringValue];
    NSString *title = @"";
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
                                      //                                          [self displayAlert:@"Task Updated"
                                      //                                                      format:@"Renamed task to \"%@\"", task.title];
                                      //                                          [self fetchTasksForSelectedList];
                                      //                                          [taskNameField_ setStringValue:@""];
                                  } else {
                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                      //                                          [self displayAlert:@"Error"
                                      //                                                      format:@"%@", error];
                                      [self updateUI];
                                  }
                                  
                                  //                                  if (error == nil) {
                                  //                                      [self displayAlert:@"Task Deleted"
                                  //                                                  format:@"Deleted task \"%@\"", taskTitle];
                                  //                                      [self fetchTasksForSelectedList];
                                  //                                  } else {
                                  //                                      [self displayAlert:@"Error"
                                  //                                                  format:@"%@", error];
                                  //                                      [self updateUI];
                                  //                                  }
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

@end