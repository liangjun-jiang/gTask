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
{
    UIBarButtonItem *addTaskListButton_;
    UIBarButtonItem *renameTaskListButton_;
    UIBarButtonItem *deleteTaskListButton_;

    
}
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
    
    addTaskListButton_ = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonSystemItemAdd target:self action:@selector(addTaskListClicked:)];
    renameTaskListButton_ = [[UIBarButtonItem alloc] initWithTitle:@"R" style:UIBarButtonSystemItemEdit target:self action:@selector(renameTaskListClicked:)];
    deleteTaskListButton_ = [[UIBarButtonItem alloc] initWithTitle:@"X" style:UIBarButtonSystemItemAction target:self action:@selector(deleteTaskListClicked:)];
    
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                             target:nil
                                                                                             action:nil];
    //add a task item
//    UIBarButtonItem *addATaskListItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CIALBrowser.bundle/images/browserBack.png"]
//                                                                     style:UIBarButtonItemStylePlain
//                                                                    target:self
//                                                                    action:@selector(addATaskList)];
   
    
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:addTaskListButton_];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:renameTaskListButton_];
    [items addObject:flexibleSpaceButtonItem];
    [items addObject:deleteTaskListButton_];
    [items addObject:flexibleSpaceButtonItem];
    
    return items;
}

#pragma mark - IBAction
- (void)addTaskListClicked:(id)sender {
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

- (void)renameTaskListClicked:(id)sender {
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

- (void)deleteTaskListClicked:(id)sender {
    GTLTasksTaskList *tasklist = [self selectedTaskList];
    NSString *title = tasklist.title;
    [self displayAlert:@"Delete" format:@"Delete \"%@\"?", title];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
    } else {
        if (alertView.tag == 110 || alertView.tag == 111) {
            UITextField *taskString = [alertView textFieldAtIndex:0];
            if (alertView.tag  == 110) {
                [self addATaskList:taskString.text];
            } else if(alertView.tag == 111) {
                [self renameSelectedTaskList:taskString.text];
            }
        } else
            // from other alertView
            // might do other things
        {
            [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
            
        }
        
    }
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
   
    
    // todo: needs to handle errors!
    if (self.taskListsTicket != nil || self.editTaskListTicket != nil) {
        [SVProgressHUD showWithStatus:@"Loading..."];
    } else {
        [SVProgressHUD dismiss];
    }
    
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
    
    BOOL hasTaskLists = (self.taskLists != nil);
    BOOL isTaskListSelected = ([self selectedTaskList] != nil);
    GTLTasksTaskList *item = [self selectedTaskList];
    
    BOOL hasTaskListTitle = ([item.title length] > 0);
    
    [addTaskListButton_ setEnabled:(hasTaskListTitle && hasTaskLists)];
    [renameTaskListButton_ setEnabled:(hasTaskListTitle && isTaskListSelected)];
    [deleteTaskListButton_ setEnabled:(isTaskListSelected)];

    // todo: we also allow the user canceling the fetching!
//    BOOL isFetchingTaskLists = (self.taskListsTicket != nil);
//    BOOL isEditingTaskList = (self.editTaskListTicket != nil);
//    [taskListsCancelButton_ setEnabled:(isFetchingTaskLists || isEditingTaskList)];
    
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
    
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[self toolbarItems]];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchTaskLists];
    });
    
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    return [self.taskLists.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
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
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    [self updateUI];
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
  
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath.row > -1) {
        GTLTasksTaskList *item = [self.taskLists itemAtIndex:indexPath.row];
        return item;
    }
    return nil;
}

#pragma mark Add a Task List

- (void)addATaskList:(NSString *)title {
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
                                              [self fetchTaskLists];
                                          } else {
                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                              [self updateUI];
                                          }
                                      }];
        [self updateUI];
    }
}

#pragma mark Rename a Task List

- (void)renameSelectedTaskList:(NSString *)title{
    
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
                                          [self fetchTaskLists];
                                      } else {
                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                          [self updateUI];
                                      }
                                  }];
    [self updateUI];
}


@end
