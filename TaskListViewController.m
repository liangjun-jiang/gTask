//
//  TaskListViewController.m
//  gTask
//
//  Created by LIANGJUN JIANG on 3/22/13.
//
//

#import "TaskListViewController.h"
#import "TaskTasksViewController.h"
#import "SVProgressHUD.h"

@interface TaskListViewController ()

@property (strong) GTLTasksTaskLists *taskLists;
@property (strong) GTLServiceTicket *taskListsTicket;
@property (strong) NSError *taskListsFetchError;

@property (strong) GTLServiceTicket *editTaskListTicket;

@property (strong) GTLTasksTasks *tasks;
@property (strong) GTLServiceTicket *tasksTicket;
@property (strong) NSError *tasksFetchError;

@property (strong) GTLServiceTicket *editTaskTicket;

@end

// Constants that ought to be defined by the API
NSString *const kTaskStatusCompleted = @"completed";
NSString *const kTaskStatusNeedsAction = @"needsAction";

@implementation TaskListViewController
@synthesize tasksService;

#pragma mark - alert helper
- (void)displayAlertWithMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"gTask"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


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

- (NSArray *)toolbarItems
{
    // Toolbar
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:9];
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                             target:nil
                                                                                             action:nil];
    //add a task item
    UIBarButtonItem *addATaskListItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CIALBrowser.bundle/images/browserBack.png"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(addATaskList)];
    //rename a task item
    UIBarButtonItem *renameATaskListItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CIALBrowser.bundle/images/browserForward.png"]
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(renameSelectedTaskList)];
    
    //complete all tasks
    UIBarButtonItem *completeAllListItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                     target:self
                                                                                     action:@selector(renameSelectedTaskList)];
    
    //delete all tasks
    UIBarButtonItem *deleteAllListItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                   target:self
                                                                                   action:@selector(viewBookmark:)];
    
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:addATaskListItem];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:renameATaskListItem];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:completeAllListItem];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:deleteAllListItem];
    [items addObject:flexibleSpaceButtonItem];
    
    return items;
}

#pragma mark - TasksList

- (void)fetchTaskLists {
    self.taskLists = nil;
    self.taskListsFetchError = nil;
    
    GTLServiceTasks *service = self.tasksService;
    
    GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsList];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"LOADING", @"Loading")];
    
    self.taskListsTicket = [service executeQuery:query
                               completionHandler:^(GTLServiceTicket *ticket,
                                                   id taskLists, NSError *error) {
                                   // callback
                                   [SVProgressHUD dismiss];
                                   
                                   self.taskLists = taskLists;
                                   self.taskListsFetchError = error;
                                   self.taskListsTicket = nil;
                                   
                                   [self updateUI];
                               }];
    [self updateUI];
}

- (void)updateUI
{
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[self toolbarItems]];
    
    // todo: needs to handle errors!
//    if (self.taskListsTicket != nil || self.editTaskListTicket != nil) {
//        DebugLog(@"we got some tasks");
//        //        [taskListsProgressIndicator_ startAnimation:self];
//    } else {
//        //        [taskListsProgressIndicator_ stopAnimation:self];
//        DebugLog(@"we didn't get anything");
//    }
    
    // Get the description of the selected item, or the feed fetch error
    NSString *resultStr = @"";
    
    if (self.taskListsFetchError) {
        // Display the error
        resultStr = [self.taskListsFetchError description];
        
        // Also display any server data present
        NSData *errData = [[self.taskListsFetchError userInfo] objectForKey:kGTMHTTPFetcherStatusDataKey];
        if (errData) {
            NSString *dataStr = [[NSString alloc] initWithData:errData
                                                      encoding:NSUTF8StringEncoding];
            resultStr = [resultStr stringByAppendingFormat:@"\n%@", dataStr];
        }
    } else {
        // Display the selected item
        GTLTasksTaskList *item = [self selectedTaskList];
        if (item) {
            // this is all we care
            resultStr = [item description];
        }
    }
    //    [taskListsResultTextView_ setString:resultStr];
    DebugLog(@"this is the task lists we got: %@", resultStr);
    
    [self.tableView reloadData];
    
}

#pragma mark - UI

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
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchTaskLists];
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
    return [self.taskLists.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    GTLTasksTaskList *item = self.taskLists[indexPath.row];
    cell.textLabel.text = item.title;
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


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     GTLTasksTaskList *selectedTasklist = [self selectedTaskList];
    
    // Navigation logic may go here. Create and push another view controller.
    TaskTasksViewController *detailViewController = [[TaskTasksViewController alloc] initWithStyle:UITableViewStylePlain];
    
    // todo: super stupid
    detailViewController.selectedTasklist = selectedTasklist;
    detailViewController.tasksService = self.tasksService;
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
    
}


#pragma mark - setter & getter

- (GTLTasksTaskList *)selectedTaskList {
    //    int rowIndex = [taskListsTable__ selectedRow];
    // todo: the default is always the first one
    int rowIndex = 0;
    if (rowIndex > -1) {
        GTLTasksTaskList *item = [self.taskLists itemAtIndex:rowIndex];
        return item;
    }
    return nil;
}

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

#pragma mark Add a Task List

- (void)addATaskList {
    //    NSString *title = [taskListNameField_ stringValue];
    NSString *title = @"";
    if ([title length] > 0) {
        // Make a new task list
        GTLTasksTaskList *tasklist = [GTLTasksTaskList object];
        tasklist.title = title;
        
        GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsInsertWithObject:tasklist];
        
        GTLServiceTasks *service = self.tasksService;
        self.editTaskListTicket = [service executeQuery:query
                                      completionHandler:^(GTLServiceTicket *ticket,
                                                          id item, NSError *error) {
                                          // callback
                                          self.editTaskListTicket = nil;
                                          GTLTasksTaskList *tasklist = item;
                                          
                                          if (error == nil) {
                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"Added task list \"%@\"", tasklist.title]];
                                              //                                              [self displayAlert:@"Task List Added"
                                              //                                                          format:@"Added task list \"%@\"", tasklist.title];
                                              [self fetchTaskLists];
                                              //                                              [taskListNameField_ setStringValue:@""];
                                          } else {
                                              //                                              [self displayAlert:@"Error"
                                              //                                                          format:@"%@", error];
                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                              [self updateUI];
                                          }
                                      }];
        [self updateUI];
    }
}

#pragma mark Rename a Task List

- (void)renameSelectedTaskList {
    //    NSString *title = [taskListNameField_ stringValue];
    
    NSString *title = @"";
    if ([title length] > 0) {
        // Rename the selected task list
        
        // Rather than update the object with a complete replacement, we'll make
        // a patch object containing just the changed title
        GTLTasksTaskList *patchObject = [GTLTasksTaskList object];
        patchObject.title = title;
        
        GTLTasksTaskList *selectedTaskList = [self selectedTaskList];
        
        GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsPatchWithObject:patchObject
                                                                      tasklist:selectedTaskList.identifier];
        GTLServiceTasks *service = self.tasksService;
        self.editTaskListTicket = [service executeQuery:query
                                      completionHandler:^(GTLServiceTicket *ticket,
                                                          id item, NSError *error) {
                                          // callback
                                          self.editTaskListTicket = nil;
                                          GTLTasksTaskList *tasklist = item;
                                          
                                          if (error == nil) {
                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"Updated task list \"%@\"", tasklist.title]];
                                              //                                              [self displayAlert:@"Task List Updated"
                                              //                                                          format:@"Updated task list \"%@\"", tasklist.title];
                                              [self fetchTaskLists];
                                              //                                              [taskListNameField_ setStringValue:@""];
                                          } else {
                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                              //                                              [self displayAlert:@"Error"
                                              //                                                          format:@"%@", error];
                                              [self updateUI];
                                          }
                                      }];
        [self updateUI];
    }
}

#pragma mark Delete a Task List

- (void)deleteSelectedTaskList {
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    
    GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsDeleteWithTasklist:tasklist.identifier];
    
    GTLServiceTasks *service = self.tasksService;
    self.editTaskListTicket = [service executeQuery:query
                                  completionHandler:^(GTLServiceTicket *ticket,
                                                      id item, NSError *error) {
                                      // callback
                                      self.editTaskListTicket = nil;
                                      
                                      if (error == nil) {
                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"Delete task list \"%@\"", tasklist.title]];
                                          //                                          [self displayAlert:@"Task List Deleted"
                                          //                                                      format:@"Deleted task list \"%@\"", tasklist.title];
                                          [self fetchTaskLists];
                                      } else {
                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                          //                                          [self displayAlert:@"Error"
                                          //                                                      format:@"%@", error];
                                          [self updateUI];
                                      }
                                  }];
    [self updateUI];
}


@end
