//
//  SHCViewController.m
//  ClearStyle
//
//  Created by Colin Eberhardt on 23/08/2012.
//  Copyright (c) 2012 Colin Eberhardt. All rights reserved.
//

#import "SHCViewController.h"
#import "SHCToDoItem.h"
#import "SHCTableViewCell.h"
#import "SHCPullToAddNewBehaviour.h"
#import "SHCPinchToAddNewBehaviour.h"
#import "TaskTasksViewController.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"
#import "SSTheme.h"

@interface SHCViewController ()<UIActionSheetDelegate>
{
    // a array of to-do items
//    NSMutableArray* _toDoItems;
    
    // the offset applied to cells when entering 'edit mode'
    float _editingOffset;
    
    SHCPullToAddNewBehaviour* _pullAddNewBehaviour;
    SHCPinchToAddNewBehaviour* _pinchAddNewBehaviour;
}

@property (strong) GTLTasksTaskLists *taskLists;
@property (strong) GTLServiceTicket *taskListsTicket;
@property (strong) NSError *taskListsFetchError;

@property (strong) GTLServiceTicket *editTaskListTicket;

@property (strong) GTLTasksTasks *tasks;
@property (strong) GTLServiceTicket *tasksTicket;
@property (strong) NSError *tasksFetchError;

@property (strong) GTLServiceTicket *editTaskTicket;
//@property (strong)  NSIndexPath *selectedIndexPath;


@end


@implementation SHCViewController
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

#pragma mark - View Cycle
-(id)initWithAuth:(GTMOAuth2Authentication *)auth
{
    self = [self initWithNibName:@"SHCViewController" bundle:nil];
    if (self){
//        self.tasksService.authorizer = auth;
        
    }
    
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
//        self.tasksService = [self tasksService];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.alpha = 0.0;
    
    id <SSTheme> theme = [SSThemeManager sharedTheme];
    self.view.backgroundColor =  [theme mainColor]; //[UIColor blackColor];
    
    // configure the table
    [self.tableView registerClassForCells:[SHCTableViewCell class]];
    self.tableView.datasource = self;
    
    _pullAddNewBehaviour = [[SHCPullToAddNewBehaviour alloc] initWithTableView:self.tableView];
    _pinchAddNewBehaviour  = [[SHCPinchToAddNewBehaviour alloc] initWithTableView:self.tableView];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchTaskLists];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    _tableView = nil;
}

- (UIColor*)colorForIndex:(NSInteger) index
{
//    NSUInteger itemCount = _toDoItems.count - 1;
    NSUInteger itemCount = self.taskLists.items.count - 1;
    
    float val = ((float)index / (float)itemCount) * 0.6;
    return [UIColor colorWithRed: 1.0 green:val blue: 0.0 alpha:1.0];
}

#pragma mark - SHCTableViewCellDelegate methods

- (void)cellDidBeginEditing:(SHCTableViewCell *)editingCell
{
    _editingOffset = _tableView.scrollView.contentOffset.y - editingCell.frame.origin.y;
    
    for(SHCTableViewCell* cell in [_tableView visibleCells])
    {
        [UIView animateWithDuration:0.3
                         animations:^{
                             cell.transform = CGAffineTransformMakeTranslation(0,  _editingOffset);
                             if (cell != editingCell)
                             {
                                 cell.alpha = 0.3;
                             }
                         }];
    }
}

- (void)cellDidEndEditing:(SHCTableViewCell *)editingCell
{
    for(SHCTableViewCell* cell in [_tableView visibleCells])
    {
        [UIView animateWithDuration:0.3
                         animations:^{
                             cell.transform = CGAffineTransformIdentity;
                             if (cell != editingCell)
                             {
                                 cell.alpha = 1.0;
                                 
                             } else
                                [self renameSelectedTaskList:editingCell.todoItem];
                         }];
    }
    
   
}


- (void) toDoItemDeleted:(GTLTasksTaskList*) todoItem
{    
    float delay = 0.0;
    
    NSArray* visibleCells = [_tableView visibleCells];
    
    UIView* lastView = [visibleCells lastObject];
    bool startAnimating = false;
    
    for(SHCTableViewCell* cell in visibleCells)
    {
        if (startAnimating)
        {
            [UIView animateWithDuration:0.3
                                  delay:delay
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 cell.frame = CGRectOffset(cell.frame, 0.0f, -cell.frame.size.height);
                             }
                             completion:^(BOOL finished){
                                 if (cell == lastView)
                                 {
                                     [_tableView reloadData];
                                 }
                             }];
            delay+=0.03;
        }
        
        if (cell.todoItem == todoItem)
        {
            startAnimating = true;
            cell.hidden = YES;
            [self deleteSelectedTaskList:todoItem];
        }
    }
}



#pragma mark - SHCCustomTableViewDataSource methods

- (void)itemAdded
{
    [self itemAddedAtIndex:0];
}

- (void)itemAddedAtIndex:(NSInteger)index
{
    // create the new item
//    SHCToDoItem* toDoItem = [[SHCToDoItem alloc] init];
//    [_toDoItems insertObject:toDoItem atIndex:index];
    
    // todo:
    GTLTasksTaskList *toDoItem = [GTLTasksTaskList object];
//    tasklist.title = title;
    
    // we add an emty task immediately. When the editing of textfiled is finished, it will be an update
    
    [self addATaskList:toDoItem];
    
//    [self addTaskListClicked:nil];
    
    // enter edit mode
    SHCTableViewCell* editCell;
    for(SHCTableViewCell* cell in _tableView.visibleCells)
    {
        if (cell.todoItem == toDoItem)
        {
            editCell = cell;
            break;
        }
    }
    [editCell.label becomeFirstResponder];
}

- (NSInteger)numberOfRows
{
//    return _toDoItems.count;
    return self.taskLists.items.count;
}


- (UIView *) cellForRow:(NSInteger) row;
{
    SHCTableViewCell* cell = (SHCTableViewCell*)[_tableView dequeueReusableCell];
        
    int index = row;
//    SHCToDoItem *item = _toDoItems[index];
//    cell.todoItem = item;
    
    GTLTasksTaskList *item = self.taskLists[index];
    cell.todoItem = item;
//    cell.todoItem.text = item.title;
//    cell.textLabel.text = item.title;
    
    cell.backgroundColor = [self colorForIndex:row];
    cell.delegate = self;
    
    return cell;
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

- (void)deleteTaskListClicked:(GTLTasksTaskList *)item {
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
    NSString *title = item.title;
    [self displayAlert:@"Delete" format:@"Delete \"%@\"?", title];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
    } else {
        if (alertView.tag == 110 || alertView.tag == 111) {
//            UITextField *taskString = [alertView textFieldAtIndex:0];
            if (alertView.tag  == 110) {
//                [self addATaskList:taskString.text];
            } else if(alertView.tag == 111) {
//                [self renameSelectedTaskList:taskString.text];
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
    [self.tableView reloadData];
    
    // todo: needs to handle errors!
//    if (self.taskListsTicket != nil || self.editTaskListTicket != nil) {
//        [SVProgressHUD showWithStatus:@"Loading..."];
//    } else {
//        [SVProgressHUD dismiss];
//    }
//    
//    // Get the description of the selected item, or the feed fetch error
//    NSString *resultStr = @"";
//    
//    if (self.taskListsFetchError) {
//        // Display the error
//        resultStr = [self.taskListsFetchError description];
//        
//        // Also display any server data present
//        NSData *errData = [[self.taskListsFetchError userInfo] objectForKey:kGTMHTTPFetcherStatusDataKey];
//        if (errData) {
//            NSString *dataStr = [[NSString alloc] initWithData:errData
//                                                      encoding:NSUTF8StringEncoding];
//            resultStr = [resultStr stringByAppendingFormat:@"\n%@", dataStr];
//        }
//    } else {
        // Display the selected item
//        GTLTasksTaskList *item = [self selectedTaskList];
//        if (item) {
//            // this is all we care
//            resultStr = [item description];
//        }
//    }
    //    [taskListsResultTextView_ setString:resultStr];
    
//    BOOL hasTaskLists = (self.taskLists != nil);
//    BOOL isTaskListSelected = ([self selectedTaskList] != nil);
//    GTLTasksTaskList *item = [self selectedTaskList];
//    
//    BOOL hasTaskListTitle = ([item.title length] > 0);
//    
//    [addTaskListButton_ setEnabled:(hasTaskListTitle && hasTaskLists)];
//    [renameTaskListButton_ setEnabled:(hasTaskListTitle && isTaskListSelected)];
//    [deleteTaskListButton_ setEnabled:(isTaskListSelected)];
    
    // todo: we also allow the user canceling the fetching!
    //    BOOL isFetchingTaskLists = (self.taskListsTicket != nil);
    //    BOOL isEditingTaskList = (self.editTaskListTicket != nil);
    //    [taskListsCancelButton_ setEnabled:(isFetchingTaskLists || isEditingTaskList)];
    
//    [self.tableView reloadData];
    
}

#pragma mark - setter & getter

//- (GTLServiceTasks *)tasksService {
//    static GTLServiceTasks *service = nil;
//    
//    if (!service) {
//        service = [[GTLServiceTasks alloc] init];
//        
//        // Have the service object set tickets to fetch consecutive pages
//        // of the feed so we do not need to manually fetch them
//        service.shouldFetchNextPages = YES;
//        
//        // Have the service object set tickets to retry temporary error conditions
//        // automatically
//        service.retryEnabled = YES;
//    }
//    return service;
//}



//- (GTLTasksTaskList *)selectedTaskList {
//    
//    NSIndexPath *indexPath = self.selectedIndexPath;// [self.tableView indexPathForSelectedRow];
//    
//    // to make it simple
//    if (indexPath == nil)
//        indexPath = self.selectedIndexPath;
//    
//    if (indexPath.row > -1) {
//        GTLTasksTaskList *item = [self.taskLists itemAtIndex:indexPath.row];
//        return item;
//    }
//    return nil;
//}

//- (GTLTasksTaskList *)selectedTaskListForIndexPath:(NSIndexPath *)indexPath {
//
////    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//    if (indexPath.row > -1) {
//        GTLTasksTaskList *item = [self.taskLists itemAtIndex:indexPath.row];
//        return item;
//    }
//    return nil;
//}


#pragma mark Add a Task List

- (void)addATaskList:(GTLTasksTaskList *)toDoItem {
//    if ([title length] > 0) {
        // Make a new task list
//        GTLTasksTaskList *tasklist = [GTLTasksTaskList object];
//        tasklist.title = title;
//        
    GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsInsertWithObject:toDoItem];
    
    GTLServiceTasks *service = self.tasksService;
    self.editTaskListTicket = [service executeQuery:query
                                  completionHandler:^(GTLServiceTicket *ticket,
                                                      id item, NSError *error) {
                                      // callback
                                      self.editTaskListTicket = nil;
//                                      GTLTasksTaskList *tasklist = item;
//
                                      if (error == nil) {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"Added task list \"%@\"", tasklist.title]];
                                          [self fetchTaskLists];
                                      } else {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                          [self updateUI];
                                      }
                                  }];
    [self updateUI];
//    }
}

#pragma mark Rename a Task List

- (void)renameSelectedTaskList:(GTLTasksTaskList *)toDoItem{
    
//    if ([title length] > 0) {
        // Rename the selected task list
        
        // Rather than update the object with a complete replacement, we'll make
        // a patch object containing just the changed title
        GTLTasksTaskList *patchObject = [GTLTasksTaskList object];
        patchObject.title = toDoItem.title;
        
        GTLTasksTaskList *selectedTaskList = toDoItem;
        
        GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsPatchWithObject:patchObject
                                                                      tasklist:selectedTaskList.identifier];
        GTLServiceTasks *service = self.tasksService;
        self.editTaskListTicket = [service executeQuery:query
                                      completionHandler:^(GTLServiceTicket *ticket,
                                                          id item, NSError *error) {
                                          // callback
                                          self.editTaskListTicket = nil;
//                                          GTLTasksTaskList *tasklist = item;
                                          
                                          if (error == nil) {
//                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"Updated task list \"%@\"", tasklist.title]];
                                              //                                              [self displayAlert:@"Task List Updated"
                                              //                                                          format:@"Updated task list \"%@\"", tasklist.title];
                                              [self fetchTaskLists];
                                              //                                              [taskListNameField_ setStringValue:@""];
                                          } else {
//                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                              //                                              [self displayAlert:@"Error"
                                              //                                                          format:@"%@", error];
                                              [self updateUI];
                                          }
                                      }];
        [self updateUI];
//    }
}

#pragma mark Delete a Task List

- (void)deleteSelectedTaskList:(GTLTasksTaskList *)toDoItem {
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
    
    GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsDeleteWithTasklist:toDoItem.identifier];
    
    GTLServiceTasks *service = self.tasksService;
    self.editTaskListTicket = [service executeQuery:query
                                  completionHandler:^(GTLServiceTicket *ticket,
                                                      id item, NSError *error) {
                                      // callback
                                      self.editTaskListTicket = nil;
                                      
                                      if (error == nil) {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"Delete task list \"%@\"", toDoItem.title]];
                                          [self fetchTaskLists];
                                      } else {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
                                          [self updateUI];
                                      }
                                  }];
    [self updateUI];
}

#pragma mark - Gesture
//- (void)onLongPress:(UILongPressGestureRecognizer *)gesture
//{
//    if (gesture.state == UIGestureRecognizerStateBegan)
//    {
//        UITableViewCell *cell = (UITableViewCell *)[gesture view];
//        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//        self.selectedIndexPath = indexPath;
//        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTION", @"action") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"EDIT_TITLE",@"edit title"), NSLocalizedString(@"DELETE", @"delete"), nil];
//        [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
//        
//    }
//}
//
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex == actionSheet.cancelButtonIndex) {
//        [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
//    } else if (buttonIndex == 0){ //edit
//        [self renameTaskListClicked:nil];
//    } else if (buttonIndex == 1) { //delete
//        [self deleteTaskListClicked:nil];
//    }
//    
//}


#pragma mark - UI
-(void)onSignOut:(id)sender
{
    AppDelegate *delegate = [AppDelegate appDelegate];
    [delegate signOut];
    
}



@end
