//
//  MenuViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "MenuViewController.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"

@interface MenuViewController()
@property (nonatomic, strong) NSArray *menuItems;
@property (strong) GTLTasksTaskLists *taskLists;
@property (strong) GTLServiceTicket *taskListsTicket;
@property (strong) NSError *taskListsFetchError;

@property (strong) GTLServiceTicket *editTaskListTicket;

@property (strong) GTLTasksTasks *tasks;
@property (strong) GTLServiceTicket *tasksTicket;
@property (strong) NSError *tasksFetchError;

@property (strong) GTLServiceTicket *editTaskTicket;
@end

@implementation MenuViewController
@synthesize menuItems;
@synthesize tasksService;

- (void)awakeFromNib
{
  self.menuItems = [NSArray arrayWithObjects:@"First", @"Second", @"Third", @"Navigation", nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.slidingViewController setAnchorRightRevealAmount:280.0f];
  self.slidingViewController.underLeftWidthLayout = ECFullWidth;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
//  return self.menuItems.count;
    
    return [self.taskLists.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *cellIdentifier = @"MenuItemCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
//  cell.textLabel.text = [self.menuItems objectAtIndex:indexPath.row];
    GTLTasksTaskList *item = self.taskLists[indexPath.row];
    cell.textLabel.text = item.title;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *identifier = [NSString stringWithFormat:@"%@Top", [self.menuItems objectAtIndex:indexPath.row]];

  UIViewController *newTopViewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
  
  [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
    CGRect frame = self.slidingViewController.topViewController.view.frame;
    self.slidingViewController.topViewController = newTopViewController;
    self.slidingViewController.topViewController.view.frame = frame;
    [self.slidingViewController resetTopView];
  }];
}

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
    
//    BOOL hasTaskLists = (self.taskLists != nil);
//    BOOL isTaskListSelected = ([self selectedTaskList] != nil);
//    GTLTasksTaskList *item = [self selectedTaskList];
//    
//    BOOL hasTaskListTitle = ([item.title length] > 0);
    
//    [addTaskListButton_ setEnabled:(hasTaskListTitle && hasTaskLists)];
//    [renameTaskListButton_ setEnabled:(hasTaskListTitle && isTaskListSelected)];
//    [deleteTaskListButton_ setEnabled:(isTaskListSelected)];
    
    // todo: we also allow the user canceling the fetching!
    //    BOOL isFetchingTaskLists = (self.taskListsTicket != nil);
    //    BOOL isEditingTaskList = (self.editTaskListTicket != nil);
    //    [taskListsCancelButton_ setEnabled:(isFetchingTaskLists || isEditingTaskList)];
    
//    [self.tableView reloadData];
    
}

#pragma mark - UI
-(void)onSignOut:(id)sender
{
    AppDelegate *delegate = [AppDelegate appDelegate];
    [delegate signOut];
    
}

#pragma mark - setter & getter

- (GTLTasksTaskList *)selectedTaskList {
    
//    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//    
//    // to make it simple
//    if (indexPath == nil)
//        indexPath = self.selectedIndexPath;
//    
//    if (indexPath.row > -1) {
//        GTLTasksTaskList *item = [self.taskLists itemAtIndex:indexPath.row];
//        return item;
//    }
    return nil;
}



@end
