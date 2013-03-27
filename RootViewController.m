
#import "RootViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2SignIn.h"

#import "GTLUtilities.h"
#import "GTMHTTPFetcherLogging.h"

#import "TaskListViewController.h"

//static NSString *const kKeychainItemName = @"OAuth Sample: Google Contacts";
static NSString *const kShouldSaveInKeychainKey = @"shouldSaveInKeychain";

//static NSString *const kDailyMotionAppServiceName = @"OAuth Sample: DailyMotion";
//static NSString *const kDailyMotionServiceName = @"DailyMotion";

static NSString *const kSampleClientIDKey = @"clientID";
static NSString *const kSampleClientSecretKey = @"clientSecret";

@interface RootViewController()

@property (readonly) GTLServiceTasks *tasksService;

@property (retain) GTLTasksTaskLists *taskLists;
@property (retain) GTLServiceTicket *taskListsTicket;
@property (retain) NSError *taskListsFetchError;

@property (retain) GTLServiceTicket *editTaskListTicket;

@property (retain) GTLTasksTasks *tasks;
@property (retain) GTLServiceTicket *tasksTicket;
@property (retain) NSError *tasksFetchError;

@property (retain) GTLServiceTicket *editTaskTicket;

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error;
- (void)incrementNetworkActivity:(NSNotification *)notify;
- (void)decrementNetworkActivity:(NSNotification *)notify;
- (void)signInNetworkLostOrFound:(NSNotification *)notify;
//- (GTMOAuth2Authentication *)authForDailyMotion;
- (void)doAnAuthenticatedAPIFetch;
- (void)displayAlertWithMessage:(NSString *)str;
- (BOOL)shouldSaveInKeychain;
- (void)saveClientIDValues;
- (void)loadClientIDValues;
- (void)displayAlert:(NSString *)title format:(NSString *)format, ...;

@end
// Constants that ought to be defined by the API
//NSString *const kTaskStatusCompleted = @"completed";
//NSString *const kTaskStatusNeedsAction = @"needsAction";

// Keychain item name for saving the user's authentication information
NSString *const kKeychainItemName = @"gTasks: Google Tasks";

@implementation RootViewController

@synthesize clientIDField = mClientIDField,
            clientSecretField = mClientSecretField,
            serviceNameField = mServiceNameField,
            emailField = mEmailField,
            expirationField = mExpirationField,
            accessTokenField = mAccessTokenField,
            refreshTokenField = mRefreshTokenField,
            fetchButton = mFetchButton,
            expireNowButton = mExpireNowButton,
            serviceSegments = mServiceSegments,
            shouldSaveInKeychainSwitch = mShouldSaveInKeychainSwitch,
            signInOutButton = mSignInOutButton;

@synthesize auth = mAuth;

// NSUserDefaults keys
static NSString *const kGoogleClientIDKey          = @"GoogleClientID";
static NSString *const kGoogleClientSecretKey      = @"GoogleClientSecret";
static NSString *const kDailyMotionClientIDKey     = @"DailyMotionClientID";
static NSString *const kDailyMotionClientSecretKey = @"DailyMotionClientSecret";

- (void)awakeFromNib {
  // Listen for network change notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(incrementNetworkActivity:) name:kGTMOAuth2WebViewStartedLoading object:nil];
  [nc addObserver:self selector:@selector(decrementNetworkActivity:) name:kGTMOAuth2WebViewStoppedLoading object:nil];
  [nc addObserver:self selector:@selector(incrementNetworkActivity:) name:kGTMOAuth2FetchStarted object:nil];
  [nc addObserver:self selector:@selector(decrementNetworkActivity:) name:kGTMOAuth2FetchStopped object:nil];
  [nc addObserver:self selector:@selector(signInNetworkLostOrFound:) name:kGTMOAuth2NetworkLost  object:nil];
  [nc addObserver:self selector:@selector(signInNetworkLostOrFound:) name:kGTMOAuth2NetworkFound object:nil];

  // Fill in the Client ID and Client Secret text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // First, we'll try to get the saved Google authentication, if any, from
  // the keychain

  // Normal applications will hardcode in their client ID and client secret,
  // but the sample app allows the user to enter them in a text field, and
  // saves them in the preferences
  NSString *clientID = [defaults stringForKey:kGoogleClientIDKey];
  NSString *clientSecret = [defaults stringForKey:kGoogleClientSecretKey];

  GTMOAuth2Authentication *auth = nil;

  if (clientID && clientSecret) {
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                      clientID:clientID
                                                                  clientSecret:clientSecret];
  }

  if (auth.canAuthorize) {
    // Select the Google service segment
    self.serviceSegments.selectedSegmentIndex = 0;
  }
  
  // Save the authentication object, which holds the auth tokens and
  // the scope string used to obtain the token.  For Google services,
  // the auth object also holds the user's email address.
  self.auth = auth;

  // Update the client ID value text fields to match the radio button selection
  [self loadClientIDValues];

  BOOL isRemembering = [self shouldSaveInKeychain];
  self.shouldSaveInKeychainSwitch.on = isRemembering;
  [self updateUI];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];


}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
  // Returns non-zero on iPad, but backward compatible to SDKs earlier than 3.2.
  if (UI_USER_INTERFACE_IDIOM()) {
    return YES;
  }
  return [super shouldAutorotateToInterfaceOrientation:orientation];
}

//- (BOOL)isSignedIn {
//    
//    
//  BOOL isSignedIn = self.auth.canAuthorize;
//  return isSignedIn;
//}

- (BOOL)isGoogleSegmentSelected {
  int segmentIndex = self.serviceSegments.selectedSegmentIndex;
  return (segmentIndex == 0);
}

- (IBAction)serviceSegmentClicked:(id)sender {
  [self loadClientIDValues];
}

// copy from GTasks Mac
- (NSString *)signedInUsername {
    // Get the email address of the signed-in user
    GTMOAuth2Authentication *auth = self.tasksService.authorizer;
    BOOL isSignedIn = auth.canAuthorize;
    if (isSignedIn) {
        return auth.userEmail;
    } else {
        return nil;
    }
}

- (BOOL)isSignedIn {
    NSString *name = [self signedInUsername];
    return (name != nil);
}

- (IBAction)signInOutClicked:(id)sender {
  [self saveClientIDValues];

  if (![self isSignedIn]) {
    // Sign in
    if ([self isGoogleSegmentSelected]) {
      [self signInToGoogle];
    }
  } else {
    // Sign out
    [self signOut];
  }
  [self updateUI];
}

- (IBAction)fetchClicked:(id)sender {
  // Just to prove we're signed in, we'll attempt an authenticated fetch for the
  // signed-in user
  [self doAnAuthenticatedAPIFetch];
}

- (IBAction)expireNowClicked:(id)sender {
  NSDate *date = self.auth.expirationDate;
  if (date) {
    self.auth.expirationDate = [NSDate dateWithTimeIntervalSince1970:0];
    [self updateUI];
  }
}

// UISwitch does the toggling for us. We just need to read the state.
- (IBAction)toggleShouldSaveInKeychain:(UISwitch *)sender {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:sender.isOn forKey:kShouldSaveInKeychainKey];
}

- (void)signOut {
  if ([self.auth.serviceProvider isEqual:kGTMOAuth2ServiceProviderGoogle]) {
    // remove the token from Google's servers
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
  }

  // remove the stored Google authentication from the keychain, if any
  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];

  // remove the stored DailyMotion authentication from the keychain, if any
//  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kDailyMotionAppServiceName];

  // Discard our retained authentication object.
  self.auth = nil;

  [self updateUI];
}

#define myClientId @"580813237419.apps.googleusercontent.com"
#define mySecretKey @"1XLt_eUMs7hdIiqSDt04qe4-"

- (void)signInToGoogle {
  [self signOut];

  NSString *keychainItemName = nil;
  if ([self shouldSaveInKeychain]) {
    keychainItemName = kKeychainItemName;
  }

  // For Google APIs, the scope strings are available
  // in the service constant header files.
  NSString *scope = @"https://www.googleapis.com/auth/tasks";
//    NSString *scope =@"https://www.googleapis.com/auth/plus.me";

  // Typically, applications will hardcode the client ID and client secret
  // strings into the source code; they should not be user-editable or visible.
  //
  // But for this sample code, they are editable.
    NSString *clientID = myClientId; // self.clientIDField.text;
    NSString *clientSecret = mySecretKey; //self.clientSecretField.text;

    
    
  if ([clientID length] == 0 || [clientSecret length] == 0) {
    NSString *msg = @"This requires a valid client ID and client secret to sign in.";
    [self displayAlertWithMessage:msg];
    return;
  }

  // Note:
  // GTMOAuth2ViewControllerTouch is not designed to be reused. Make a new
  // one each time you are going to show it.

  // Display the autentication view.
  SEL finishedSel = @selector(viewController:finishedWithAuth:error:);

  GTMOAuth2ViewControllerTouch *viewController;
  viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                                            clientID:clientID
                                                        clientSecret:clientSecret
                                                    keychainItemName:keychainItemName
                                                            delegate:self
                                                    finishedSelector:finishedSel];

  // You can set the title of the navigationItem of the controller here, if you
  // want.

  // If the keychainItemName is not nil, the user's authorization information
  // will be saved to the keychain. By default, it saves with accessibility
  // kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, but that may be
  // customized here. For example,
  //
  //   viewController.keychainItemAccessibility = kSecAttrAccessibleAlways;

  // During display of the sign-in window, loss and regain of network
  // connectivity will be reported with the notifications
  // kGTMOAuth2NetworkLost/kGTMOAuth2NetworkFound
  //
  // See the method signInNetworkLostOrFound: for an example of handling
  // the notification.

  // Optional: Google servers allow specification of the sign-in display
  // language as an additional "hl" parameter to the authorization URL,
  // using BCP 47 language codes.
  //
  // For this sample, we'll force English as the display language.
  NSDictionary *params = @{@"hl": @"en"};
  viewController.signIn.additionalAuthorizationParameters = params;

  // By default, the controller will fetch the user's email, but not the rest of
  // the user's profile.  The full profile can be requested from Google's server
  // by setting this property before sign-in:
  //
  //   viewController.signIn.shouldFetchGoogleUserProfile = YES;
  //
  // The profile will be available after sign-in as
  //
  //   NSDictionary *profile = viewController.signIn.userProfile;

  // Optional: display some html briefly before the sign-in page loads
  NSString *html = @"<html><body bgcolor=silver><div align=center>Loading sign-in page...</div></body></html>";
  viewController.initialHTMLString = html;

  [[self navigationController] pushViewController:viewController animated:YES];

  // The view controller will be popped before signing in has completed, as
  // there are some additional fetches done by the sign-in controller.
  // The kGTMOAuth2UserSignedIn notification will be posted to indicate
  // that the view has been popped and those additional fetches have begun.
  // It may be useful to display a temporary UI when kGTMOAuth2UserSignedIn is
  // posted, just until the finished selector is invoked.
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
  if (error != nil) {
    // Authentication failed (perhaps the user denied access, or closed the
    // window before granting access)
    NSLog(@"Authentication error: %@", error);
    NSData *responseData = [error userInfo][@"data"]; // kGTMHTTPFetcherStatusDataKey
    if ([responseData length] > 0) {
      // show the body of the server's authentication failure response
      NSString *str = [[NSString alloc] initWithData:responseData
                                             encoding:NSUTF8StringEncoding];
      NSLog(@"%@", str);
    }

    self.auth = nil;
  } else {
    // Authentication succeeded
    //
    //
      DebugLog(@"auth: succesfully!");
      if (error == nil) {
//          DebugLog(@"is service nil ? %@",self.tasksService);
          self.tasksService.authorizer = auth;
          
          TaskListViewController *tasksListViewController = [[TaskListViewController alloc] initWithStyle:UITableViewStylePlain];
          tasksListViewController.tasksService = self.tasksService;
          
          [self.navigationController pushViewController:tasksListViewController animated:YES];
          
//          [self performSelector:@selector(fetchTaskLists)];
//          if (signInDoneSel) {
//              [self performSelector:signInDoneSel];
//          }
          DebugLog(@"sign in succesfuuly");
      } else {
          self.taskListsFetchError = error;
          [self updateUI];
      }

    // save the authentication object
    self.auth = auth;
  }

  [self updateUI];
}

- (void)doAnAuthenticatedAPIFetch {
    [self fetchTaskLists];
//  NSString *urlStr;
//  if ([self isGoogleSegmentSelected]) {
//    // Google Plus feed
//    urlStr = @"https://www.googleapis.com/plus/v1/people/me/activities/public";
//  }
    // we don't care DailyMotion
//  else {
//    // DailyMotion status feed
//    urlStr = @"https://api.dailymotion.com/videos/favorites";
//  }

//  NSURL *url = [NSURL URLWithString:urlStr];
//  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//  [self.auth authorizeRequest:request
//            completionHandler:^(NSError *error) {
//              NSString *output = nil;
//              if (error) {
//                output = [error description];
//              } else {
//                // Synchronous fetches like this are a really bad idea in Cocoa applications
//                //
//                // For a very easy async alternative, we could use GTMHTTPFetcher
//                NSURLResponse *response = nil;
//                NSData *data = [NSURLConnection sendSynchronousRequest:request
//                                                     returningResponse:&response
//                                                                 error:&error];
//                if (data) {
//                  // API fetch succeeded
//                  output = [[NSString alloc] initWithData:data
//                                                  encoding:NSUTF8StringEncoding];
//                } else {
//                  // fetch failed
//                  output = [error description];
//                }
//              }
//
//              [self displayAlertWithMessage:output];
//
//              // the access token may have changed
//              [self updateUI];
//            }];
    
}

#pragma mark -

- (void)incrementNetworkActivity:(NSNotification *)notify {
  ++mNetworkActivityCounter;
  if (mNetworkActivityCounter == 1) {
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:YES];
  }
}

- (void)decrementNetworkActivity:(NSNotification *)notify {
  --mNetworkActivityCounter;
  if (mNetworkActivityCounter == 0) {
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:NO];
  }
}

- (void)signInNetworkLostOrFound:(NSNotification *)notify {
  if ([[notify name] isEqual:kGTMOAuth2NetworkLost]) {
    // network connection was lost; alert the user, or dismiss
    // the sign-in view with
    [[[notify object] delegate] cancelSigningIn];
  } else {
    // network connection was found again
  }
}

#pragma mark -

- (void)updateUI {
  // update the text showing the signed-in state and the button title
  // A real program would use NSLocalizedString() for strings shown to the user.
  if ([self isSignedIn]) {
    // signed in
    self.serviceNameField.text = self.auth.serviceProvider;
    self.emailField.text = self.auth.userEmail;
    self.accessTokenField.text = self.auth.accessToken;
    self.expirationField.text = [self.auth.expirationDate description];
    self.refreshTokenField.text = self.auth.refreshToken;

    self.signInOutButton.title = @"Sign Out";
    self.fetchButton.enabled = YES;
    self.expireNowButton.enabled = YES;
  } else {
    // signed out
    self.serviceNameField.text = @"-Not signed in-";
    self.emailField.text = @"";
    self.accessTokenField.text = @"-No access token-";
    self.expirationField.text = @"";
    self.refreshTokenField.text = @"-No refresh token-";

    self.signInOutButton.title = @"Sign In";
    self.fetchButton.enabled = NO;
    self.expireNowButton.enabled = NO;
  }

  BOOL isRemembering = [self shouldSaveInKeychain];
  self.shouldSaveInKeychainSwitch.on = isRemembering;
    
    
    //
    // Task lists table
    //
//    [taskListsTable__ reloadData];
    
//    if (self.taskListsTicket != nil || self.editTaskListTicket != nil) {
//        DebugLog(@"we got some tasks");
////        [taskListsProgressIndicator_ startAnimation:self];
//    } else {
////        [taskListsProgressIndicator_ stopAnimation:self];
//        DebugLog(@"we didn't get anything");
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
//                                                       encoding:NSUTF8StringEncoding];
//            resultStr = [resultStr stringByAppendingFormat:@"\n%@", dataStr];
//        }
//    } else {
//        // Display the selected item
//        GTLTasksTaskList *item = [self selectedTaskList];
//        if (item) {
//            // this is all we care
//            resultStr = [item description];
//        }
//    }
////    [taskListsResultTextView_ setString:resultStr];
//    DebugLog(@"this is the task lists we got: %@", resultStr);
//    //
//    // Tasks outline
//    //
////    [tasksOutline_ reloadData];
//    
//    // todo: this is a total temp hacker!!!
//    [self fetchTasksForSelectedList];
    
//    if (self.tasksTicket != nil) {
//        DebugLog(@"self.tasksTicket is not nil");
////        [tasksProgressIndicator_ startAnimation:self];
//    } else {
////        [tasksProgressIndicator_ stopAnimation:self];
//        DebugLog(@"self.tasksticket is nil");
//    }
//    
//    // Get the description of the selected item, or the feed fetch error
//    resultStr = @"";
//    if (self.tasksFetchError) {
//        resultStr = [self.tasksFetchError description];
//    } else {
//        DebugLog(@"the all tasks %@",self.tasks);
//        GTLTasksTask *item = [self selectedTask];
//        if (item) {
//            resultStr = [item description];
//        }
//    }
////    [tasksResultTextView_ setString:resultStr];
//    DebugLog(@"this is the task we got: %@", resultStr);

    // Enable task lists buttons
//    BOOL hasTaskLists = (self.taskLists != nil);
//    BOOL isTaskListSelected = ([self selectedTaskList] != nil);
//    BOOL hasTaskListTitle = ([[taskListNameField_ stringValue] length] > 0);
//    
//    [addTaskListButton_ setEnabled:(hasTaskListTitle && hasTaskLists)];
//    [renameTaskListButton_ setEnabled:(hasTaskListTitle && isTaskListSelected)];
//    [deleteTaskListButton_ setEnabled:(isTaskListSelected)];
//    
//    BOOL isFetchingTaskLists = (self.taskListsTicket != nil);
//    BOOL isEditingTaskList = (self.editTaskListTicket != nil);
//    [taskListsCancelButton_ setEnabled:(isFetchingTaskLists || isEditingTaskList)];
//    
//    // Enable tasks buttons
//    GTLTasksTask *selectedTask = [self selectedTask];
//    BOOL hasTasks = (self.tasks != nil);
//    BOOL isTaskSelected = (selectedTask != nil);
//    BOOL hasTaskTitle = ([[taskNameField_ stringValue] length] > 0);
//    
//    [addTaskButton_ setEnabled:(hasTaskTitle && hasTasks)];
//    [renameTaskButton_ setEnabled:(hasTaskTitle && isTaskSelected)];
//    [deleteTaskButton_ setEnabled:(isTaskSelected)];
//    
//    BOOL isCompleted = [selectedTask.status isEqual:kTaskStatusCompleted];
//    [completeTaskButton_ setEnabled:isTaskSelected];
//    [completeTaskButton_ setTitle:(isCompleted ? @"Uncomplete" : @"Complete")];
//    
//    NSArray *completedTasks = [self completedTasks];
//    NSUInteger numberOfCompletedTasks = [completedTasks count];
//    [clearTasksButton_ setEnabled:(numberOfCompletedTasks > 0)];
//    
//    NSUInteger numberOfTasks = [self.tasks.items count];
//    [deleteAllTasksButton_ setEnabled:(numberOfTasks > 0)];
//    
//    BOOL areAllTasksCompleted = (numberOfCompletedTasks == numberOfTasks);
//    [completeAllTasksButton_ setEnabled:(numberOfTasks > 0)];
//    [completeAllTasksButton_ setTitle:(areAllTasksCompleted ?
//                                       @"Uncomplete All" : @"Complete All")];
//    
//    BOOL isFetchingTasks = (self.tasksTicket != nil);
//    BOOL isEditingTask = (self.editTaskTicket != nil);
//    [tasksCancelButton_ setEnabled:(isFetchingTasks || isEditingTask)];
    
//    // Show or hide the text indicating that the client ID or client secret are
//    // needed
//    BOOL hasClientIDStrings = [[clientIDField_ stringValue] length] > 0
//    && [[clientSecretField_ stringValue] length] > 0;
//    [clientIDRequiredTextField_ setHidden:hasClientIDStrings];
    
}

- (void)displayAlertWithMessage:(NSString *)message {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"gTask"
                                                   message:message
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
  [alert show];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [self saveClientIDValues];
}

- (BOOL)shouldSaveInKeychain {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL flag = [defaults boolForKey:kShouldSaveInKeychainKey];
  return flag;
}

#pragma mark Client ID and Secret

//
// Normally an application will hardwire the client ID and client secret
// strings in the source code.  This sample app has to allow them to be
// entered by the developer, so we'll save them across runs into preferences.
//

- (void)saveClientIDValues {
  // Save the client ID and secret from the text fields into the prefs
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *clientID = myClientId;// self.clientIDField.text;
    NSString *clientSecret = mySecretKey; // self.clientSecretField.text;

  if ([self isGoogleSegmentSelected]) {
    [defaults setObject:clientID forKey:kGoogleClientIDKey];
    [defaults setObject:clientSecret forKey:kGoogleClientSecretKey];
  } else {
    [defaults setObject:clientID forKey:kDailyMotionClientIDKey];
    [defaults setObject:clientSecret forKey:kDailyMotionClientSecretKey];
  }
}

- (void)loadClientIDValues {
  // Load the client ID and secret from the prefs into the text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ([self isGoogleSegmentSelected]) {
    self.clientIDField.text = [defaults stringForKey:kGoogleClientIDKey];
    self.clientSecretField.text = [defaults stringForKey:kGoogleClientSecretKey];
  } else {
    self.clientIDField.text = [defaults stringForKey:kDailyMotionClientIDKey];
    self.clientSecretField.text = [defaults stringForKey:kDailyMotionClientSecretKey];
  }
}

#pragma mark - Tasks

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
//    NSBeginAlertSheet(title, nil, nil, nil, [self window], nil, nil,
//                      nil, nil, @"%@", result);
}

- (IBAction)getTaskListsClicked:(id)sender {
    if (![self isSignedIn]) {
//        [self runSigninThenInvokeSelector:@selector(fetchTaskLists)];
    } else {
        [self fetchTaskLists];
    }
}

- (IBAction)cancelTaskListsFetch:(id)sender {
    [self.taskListsTicket cancelTicket];
    self.taskListsTicket = nil;
    
    [self.editTaskListTicket cancelTicket];
    self.editTaskListTicket = nil;
    
    [self updateUI];
}

- (IBAction)cancelTasksFetch:(id)sender {
    [self.tasksTicket cancelTicket];
    self.tasksTicket = nil;
    
    [self.editTaskTicket cancelTicket];
    self.editTaskTicket = nil;
    
    [self updateUI];
}

//- (IBAction)addTaskListClicked:(id)sender {
//    [self addATaskList];
//}
//
//- (IBAction)renameTaskListClicked:(id)sender {
//    [self renameSelectedTaskList];
//}
//
//- (IBAction)deleteTaskListClicked:(id)sender {
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    NSString *title = tasklist.title;
//    
//    DebugLog(@"detele title: %@",title);
////    NSBeginAlertSheet(@"Delete", nil, @"Cancel", nil,
////                      [self window], self,
////                      @selector(deleteTaskListSheetDidEnd:returnCode:contextInfo:),
////                      nil, nil, @"Delete \"%@\"?", title);
//    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete" message:title delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
//    alertView.tag = 10;
//    [alertView show];
//                              
//    
//}
//
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    switch (alertView.tag) {
//        case 100:
//        {
//            if (buttonIndex == 1) [self deleteSelectedTaskList];
//            break;
//        }
//        case 101:
//        {
//            if (buttonIndex == 1) [self deleteSelectedTask];
//            break;
//        }
//            
//        default:
//            break;
//    }
//    
//}
//- (void)deleteTaskListSheetDidEnd:(NSWindow *)sheet
//                       returnCode:(int)returnCode
//                      contextInfo:(void *)contextInfo {
//    if (returnCode == NSAlertDefaultReturn) {
//        [self deleteSelectedTaskList];
//    }
//}

//- (IBAction)addTaskClicked:(id)sender {
//    [self addATask];
//}
//
//- (IBAction)renameTaskClicked:(id)sender {
//    [self renameSelectedTask];
//}
//
//- (IBAction)deleteTaskClicked:(id)sender {
//    GTLTasksTask *task = [self selectedTask];
//    NSString *title = task.title;
//    
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"'" message:title delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
//    alertView.tag = 11;
//    [alertView show];
//    
//}


#pragma mark - 
#pragma mark -

// get a service object with the current username/password
//
// A "service" object handles networking tasks.  Service objects
// contain user authentication information as well as networking
// state information (such as cookies and the "last modified" date for
// fetched data.)

- (GTLServiceTasks *)tasksService {
    static GTLServiceTasks *service = nil;
    
    if (!service) {
        service = [[GTLServiceTasks alloc] init];
        
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them
        service.shouldFetchNextPages = YES;
        
        // Have the service object set tickets to retry temporary error conditions
        // automatically
        service.retryEnabled = YES;
    }
    return service;
}

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

//- (NSArray *)completedTasks {
//    NSArray *array = [GTLUtilities objectsFromArray:self.tasks.items
//                                          withValue:kTaskStatusCompleted
//                                         forKeyPath:@"status"];
//    return array;
//}

//#pragma mark Create ID Map and Ordered Child Arrays
//
//// For the efficient access to tasks in the tasks object, we'll
//// build a map from task identifier to each task item, and arrays
//// for the children of the top-level object and for the children
//// of every parent task
//
//static NSString *const kGTLTaskMapProperty = @"taskMap";
//static NSString *const kGTLChildTasksProperty = @"childTasks";
//
//- (void)createPropertiesForTasks:(GTLTasksTasks *)tasks {
//    // First, build a dictionary, mapping item identifier strings to items objects
//    //
//    // This will allow for much faster lookup than would linear search of
//    // task list's items
//    NSMutableDictionary *taskMap = [NSMutableDictionary dictionary];
//    for (GTLTasksTask *task in tasks) {
//        [taskMap setObject:task
//                    forKey:task.identifier];
//    }
//    [tasks setProperty:taskMap
//                forKey:kGTLTaskMapProperty];
//    
//    // Make an array for each parent with pointers to its immediate children, in
//    // the order the children occur in the list.  We'll store the array in a
//    // property of the parent task item.
//    //
//    // For top-level tasks, we'll store the array in a property of the list
//    // object.
//    NSMutableArray *topTasks = [NSMutableArray array];
//    [tasks setProperty:topTasks
//                forKey:kGTLChildTasksProperty];
//    
//    for (GTLTasksTask *task in tasks) {
//        NSString *parentID = task.parent;
//        if (parentID == nil) {
//            // this is a top-level task in the list, so the task's parent is the
//            // main list
//            [topTasks addObject:task];
//        } else {
//            // this task is child of another task; add it to the parent's list
//            GTLTasksTask *parentTask = [taskMap objectForKey:parentID];
//            NSMutableArray *childTasks = [parentTask propertyForKey:kGTLChildTasksProperty];
//            if (childTasks == nil) {
//                childTasks = [NSMutableArray array];
//                [parentTask setProperty:childTasks
//                                 forKey:kGTLChildTasksProperty];
//            }
//            [childTasks addObject:task];
//        }
//    }
//}
//
//- (GTLTasksTask *)taskWithIdentifier:(NSString *)taskID
//                           fromTasks:(GTLTasksTasks *)tasks {
//    NSDictionary *taskMap = [tasks propertyForKey:kGTLTaskMapProperty];
//    GTLTasksTask *task = [taskMap valueForKey:taskID];
//    return task;
//}
//
//- (NSArray *)taskChildrenForObject:(GTLObject *)obj {
//    // Object is either a GTLTasksTasks (the top-level tasks list)
//    // or a GTLTasksTask (a task which may be a parent of other tasks)
//    NSArray *array = [obj propertyForKey:kGTLChildTasksProperty];
//    return array;
//}

#pragma mark Fetch Task Lists

- (void)fetchTaskLists {
    self.taskLists = nil;
    self.taskListsFetchError = nil;
    
    GTLServiceTasks *service = self.tasksService;
    
    GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsList];
    
    self.taskListsTicket = [service executeQuery:query
                               completionHandler:^(GTLServiceTicket *ticket,
                                                   id taskLists, NSError *error) {
                                   // callback
                                   self.taskLists = taskLists;
                                   self.taskListsFetchError = error;
                                   self.taskListsTicket = nil;
                                   
                                   [self updateUI];
                               }];
    [self updateUI];
}

#pragma mark Fetch Tasks

//- (void)fetchTasksForSelectedList {
//    self.tasks = nil;
//    self.tasksFetchError = nil;
//    
//    GTLServiceTasks *service = self.tasksService;
//    
//    GTLTasksTaskList *selectedTasklist = [self selectedTaskList];
//    if (selectedTasklist) {
//        NSString *tasklistID = selectedTasklist.identifier;
//        
//        GTLQueryTasks *query = [GTLQueryTasks queryForTasksListWithTasklist:tasklistID];
////        query.showCompleted = [showCompletedTasksCheckbox_ state];
////        query.showHidden = [showHiddenTasksCheckbox_ state];
////        query.showDeleted = [showDeletedTasksCheckbox_ state];
//        
//        self.tasksTicket = [service executeQuery:query
//                               completionHandler:^(GTLServiceTicket *ticket,
//                                                   id tasks, NSError *error) {
//                                   // callback
//                                   [self createPropertiesForTasks:tasks];
//                                   
//                                   self.tasks = tasks;
//                                   self.tasksFetchError = error;
//                                   self.tasksTicket = nil;
//                                   
//                                   [self updateTasksTable];
////                                   [self updateUI];
//                               }];
////        [self updateUI];
//    }
//}
//
//#pragma mark - updat another table
//- (void)updateTasksTable
//{
//    if (self.tasksTicket != nil) {
//        DebugLog(@"self.tasksTicket is not nil");
//        //        [tasksProgressIndicator_ startAnimation:self];
//    } else {
//        //        [tasksProgressIndicator_ stopAnimation:self];
//        DebugLog(@"self.tasksticket is nil");
//    }
//    
//    // Get the description of the selected item, or the feed fetch error
//    NSString *resultStr = @"";
//    if (self.tasksFetchError) {
//        resultStr = [self.tasksFetchError description];
//    } else {
//        DebugLog(@"the all tasks %@",self.tasks);
//        GTLTasksTask *item = [self selectedTask];
//        if (item) {
//            resultStr = [item description];
//        }
//    }
//    //    [tasksResultTextView_ setString:resultStr];
//    DebugLog(@"this is the task we got: %@", resultStr);
//}
//
//#pragma mark Add a Task List
//
//- (void)addATaskList {
////    NSString *title = [taskListNameField_ stringValue];
//     NSString *title = @"";
//    if ([title length] > 0) {
//        // Make a new task list
//        GTLTasksTaskList *tasklist = [GTLTasksTaskList object];
//        tasklist.title = title;
//        
//        GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsInsertWithObject:tasklist];
//        
//        GTLServiceTasks *service = self.tasksService;
//        self.editTaskListTicket = [service executeQuery:query
//                                      completionHandler:^(GTLServiceTicket *ticket,
//                                                          id item, NSError *error) {
//                                          // callback
//                                          self.editTaskListTicket = nil;
//                                          GTLTasksTaskList *tasklist = item;
//                                          
//                                          if (error == nil) {
//                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"Added task list \"%@\"", tasklist.title]];
////                                              [self displayAlert:@"Task List Added"
////                                                          format:@"Added task list \"%@\"", tasklist.title];
//                                              [self fetchTaskLists];
////                                              [taskListNameField_ setStringValue:@""];
//                                          } else {
////                                              [self displayAlert:@"Error"
////                                                          format:@"%@", error];
//                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
//                                              [self updateUI];
//                                          }
//                                      }];
//        [self updateUI];
//    }
//}
//
//#pragma mark Rename a Task List
//
//- (void)renameSelectedTaskList {
////    NSString *title = [taskListNameField_ stringValue];
//    
//    NSString *title = @"";
//    if ([title length] > 0) {
//        // Rename the selected task list
//        
//        // Rather than update the object with a complete replacement, we'll make
//        // a patch object containing just the changed title
//        GTLTasksTaskList *patchObject = [GTLTasksTaskList object];
//        patchObject.title = title;
//        
//        GTLTasksTaskList *selectedTaskList = [self selectedTaskList];
//        
//        GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsPatchWithObject:patchObject
//                                                                      tasklist:selectedTaskList.identifier];
//        GTLServiceTasks *service = self.tasksService;
//        self.editTaskListTicket = [service executeQuery:query
//                                      completionHandler:^(GTLServiceTicket *ticket,
//                                                          id item, NSError *error) {
//                                          // callback
//                                          self.editTaskListTicket = nil;
//                                          GTLTasksTaskList *tasklist = item;
//                                          
//                                          if (error == nil) {
//                                              [self displayAlertWithMessage:[NSString stringWithFormat:@"Updated task list \"%@\"", tasklist.title]];
////                                              [self displayAlert:@"Task List Updated"
////                                                          format:@"Updated task list \"%@\"", tasklist.title];
//                                              [self fetchTaskLists];
////                                              [taskListNameField_ setStringValue:@""];
//                                          } else {
//                                               [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
////                                              [self displayAlert:@"Error"
////                                                          format:@"%@", error];
//                                              [self updateUI];
//                                          }
//                                      }];
//        [self updateUI];
//    }
//}
//
//#pragma mark Delete a Task List
//
//- (void)deleteSelectedTaskList {
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    
//    GTLQueryTasks *query = [GTLQueryTasks queryForTasklistsDeleteWithTasklist:tasklist.identifier];
//    
//    GTLServiceTasks *service = self.tasksService;
//    self.editTaskListTicket = [service executeQuery:query
//                                  completionHandler:^(GTLServiceTicket *ticket,
//                                                      id item, NSError *error) {
//                                      // callback
//                                      self.editTaskListTicket = nil;
//                                      
//                                      if (error == nil) {
//                                           [self displayAlertWithMessage:[NSString stringWithFormat:@"Delete task list \"%@\"", tasklist.title]];
////                                          [self displayAlert:@"Task List Deleted"
////                                                      format:@"Deleted task list \"%@\"", tasklist.title];
//                                          [self fetchTaskLists];
//                                      } else {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
////                                          [self displayAlert:@"Error"
////                                                      format:@"%@", error];
//                                          [self updateUI];
//                                      }
//                                  }];
//    [self updateUI];
//}
//
//#pragma mark Add a Task
//
//- (void)addATask {
////    NSString *title = [taskNameField_ stringValue];
//    NSString *title = @"";
//    if ([title length] > 0) {
//        // Make a new task
//        GTLTasksTask *task = [GTLTasksTask object];
//        task.title = title;
//        
//        GTLTasksTaskList *tasklist = [self selectedTaskList];
//        GTLQueryTasks *query = [GTLQueryTasks queryForTasksInsertWithObject:task
//                                                                   tasklist:tasklist.identifier];
//        GTLServiceTasks *service = self.tasksService;
//        self.editTaskTicket = [service executeQuery:query
//                                  completionHandler:^(GTLServiceTicket *ticket,
//                                                      id item, NSError *error) {
//                                      // callback
//                                      self.editTaskTicket = nil;
//                                      GTLTasksTask *task = item;
//                                      
//                                      if (error == nil) {
//                                           [self displayAlertWithMessage:[NSString stringWithFormat:@"Updated task list \"%@\"", task.title]];
////                                          [self displayAlert:@"Task Added"
////                                                      format:@"Added task \"%@\"", task.title];
//                                          [self fetchTasksForSelectedList];
////                                          [taskNameField_ setStringValue:@""];
//                                      } else {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
////                                          [self displayAlert:@"Error"
////                                                      format:@"%@", error];
//                                          [self updateUI];
//                                      }
//                                  }];
//        [self updateUI];
//    }
//}
//
//#pragma mark Rename a Task
//
//- (void)renameSelectedTask {
////    NSString *title = [taskNameField_ stringValue];
//    NSString *title = @"";
//    if ([title length] > 0) {
//        // Rename the selected task
//        
//        // Rather than update the object with a complete replacement, we'll make
//        // a patch object containing just the changes
//        GTLTasksTask *patchObject = [GTLTasksTask object];
//        patchObject.title = title;
//        
//        GTLTasksTask *task = [self selectedTask];
//        GTLTasksTaskList *tasklist = [self selectedTaskList];
//        GTLQueryTasks *query = [GTLQueryTasks queryForTasksPatchWithObject:patchObject
//                                                                  tasklist:tasklist.identifier
//                                                                      task:task.identifier];
//        GTLServiceTasks *service = self.tasksService;
//        self.editTaskTicket = [service executeQuery:query
//                                  completionHandler:^(GTLServiceTicket *ticket,
//                                                      id item, NSError *error) {
//                                      // callback
//                                      self.editTaskTicket = nil;
//                                      GTLTasksTask *task = item;
//                                      
//                                      if (error == nil) {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"Renamed task to \"%@\"", task.title]];
////                                          [self displayAlert:@"Task Updated"
////                                                      format:@"Renamed task to \"%@\"", task.title];
////                                          [self fetchTasksForSelectedList];
////                                          [taskNameField_ setStringValue:@""];
//                                      } else {
//                                          [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
////                                          [self displayAlert:@"Error"
////                                                      format:@"%@", error];
//                                          [self updateUI];
//                                      }
//                                  }];
//        [self updateUI];
//    }
//}
//
//#pragma mark Delete a Task
//
//- (void)deleteSelectedTask {
//    // Delete a task
//    GTLTasksTask *task = [self selectedTask];
//    NSString *taskTitle = task.title;
//    DebugLog(@"%@",taskTitle);
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    GTLQueryTasks *query = [GTLQueryTasks queryForTasksDeleteWithTasklist:tasklist.identifier
//                                                                     task:task.identifier];
//    GTLServiceTasks *service = self.tasksService;
//    self.editTaskTicket = [service executeQuery:query
//                              completionHandler:^(GTLServiceTicket *ticket,
//                                                  id item, NSError *error) {
//                                  // callback
//                                  self.editTaskTicket = nil;
//                                  
//                                  if (error == nil) {
//                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"Deleted task \"%@\"", task.title]];
//                                      //                                          [self displayAlert:@"Task Updated"
//                                      //                                                      format:@"Renamed task to \"%@\"", task.title];
//                                      //                                          [self fetchTasksForSelectedList];
//                                      //                                          [taskNameField_ setStringValue:@""];
//                                  } else {
//                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
//                                      //                                          [self displayAlert:@"Error"
//                                      //                                                      format:@"%@", error];
//                                      [self updateUI];
//                                  }
//                                  
////                                  if (error == nil) {
////                                      [self displayAlert:@"Task Deleted"
////                                                  format:@"Deleted task \"%@\"", taskTitle];
////                                      [self fetchTasksForSelectedList];
////                                  } else {
////                                      [self displayAlert:@"Error"
////                                                  format:@"%@", error];
////                                      [self updateUI];
////                                  }
//                              }];
//    [self updateUI];
//}

#pragma mark Change a Task's Complete Status

//- (void)completeSelectedTask {
//    // Mark a task as completed or incomplete
//    GTLTasksTask *selectedTask = [self selectedTask];
//    GTLTasksTask *patchObject = [GTLTasksTask object];
//    
//    if ([selectedTask.status isEqual:kTaskStatusCompleted]) {
//        // Change the status to not complete
//        patchObject.status = kTaskStatusNeedsAction;
//        patchObject.completed = [GTLObject nullValue]; // remove the completed date
//    } else {
//        // Change the status to complete
//        patchObject.status = kTaskStatusCompleted;
//    }
//    
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    GTLQueryTasks *query = [GTLQueryTasks queryForTasksPatchWithObject:patchObject
//                                                              tasklist:tasklist.identifier
//                                                                  task:selectedTask.identifier];
//    GTLServiceTasks *service = self.tasksService;
//    self.editTaskTicket = [service executeQuery:query
//                              completionHandler:^(GTLServiceTicket *ticket,
//                                                  id item, NSError *error) {
//                                  // callback
//                                  self.editTaskTicket = nil;
//                                  GTLTasksTask *task = item;
//                                  
//                                  if (error == nil) {
//                                      NSString *displayStatus;
//                                      if ([task.status isEqual:kTaskStatusCompleted]) {
//                                          displayStatus = @"complete";
//                                      } else {
//                                          displayStatus = @"incomplete";
//                                      }
//                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"Deleted task \"%@\"", task.title]];
////                                      [self displayAlert:@"Task Updated"
////                                                  format:@"Marked task \"%@\" %@", task.title, displayStatus];
//                                      [self fetchTasksForSelectedList];
//                                  } else {
//                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
////                                      [self displayAlert:@"Error"
////                                                  format:@"%@", error];
//                                      [self updateUI];
//                                  }
//                              }];
//    [self updateUI];
//}
//
//#pragma mark Hide Completed Tasks
//
//- (void)hideCompletedTasks {
//    // Make all completed tasks hidden
//    NSArray *previouslyCompletedTasks = [self completedTasks];
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    GTLQueryTasks *query = [GTLQueryTasks queryForTasksClearWithTasklist:tasklist.identifier];
//    
//    GTLServiceTasks *service = self.tasksService;
//    self.editTaskTicket = [service executeQuery:query
//                              completionHandler:^(GTLServiceTicket *ticket,
//                                                  id item, NSError *error) {
//                                  // callback
//                                  self.editTaskTicket = nil;
//                                  
//                                  if (error == nil) {
////                                       [self displayAlertWithMessage:[NSString stringWithFormat:@"Task List Clear"]];
//                                      [self displayAlert:@"Task List Clear"
//                                                  format:@"Made %lu tasks hidden", (unsigned long) [previouslyCompletedTasks count]];
//                                      [self fetchTasksForSelectedList];
//                                  } else {
//                                      [self displayAlertWithMessage:[NSString stringWithFormat:@"error: \"%@\"", error]];
////                                      [self displayAlert:@"Error"
////                                                  format:@"%@", error];
//                                      [self updateUI];
//                                  }
//                              }];
//    [self updateUI];
//}
//
//#pragma mark Complete All Tasks
//
//- (void)completeAllTasks {
//    // Change all tasks to be completed or uncompleted
//    NSArray *completedTasks = [self completedTasks];
//    NSUInteger numberOfCompletedTasks = [completedTasks count];
//    NSUInteger numberOfTasks = [self.tasks.items count];
//    BOOL wereAllTasksCompleted = (numberOfCompletedTasks == numberOfTasks);
//    
//    // Make a batch of queries to set all tasks to completed or uncompleted
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    
//    GTLBatchQuery *batchQuery = [GTLBatchQuery batchQuery];
//    
//    for (GTLTasksTask *task in self.tasks) {
//        GTLTasksTask *patchObject = [GTLTasksTask object];
//        
//        if (wereAllTasksCompleted) {
//            // Change the status to not complete
//            patchObject.status = kTaskStatusNeedsAction;
//            patchObject.completed = [GTLObject nullValue]; // remove the completed date
//        } else {
//            // Change the status to complete
//            patchObject.status = kTaskStatusCompleted;
//        }
//        
//        GTLQueryTasks *query = [GTLQueryTasks queryForTasksPatchWithObject:patchObject
//                                                                  tasklist:tasklist.identifier
//                                                                      task:task.identifier];
//        [batchQuery addQuery:query];
//    }
//    
//    GTLServiceTasks *service = self.tasksService;
//    self.editTaskTicket = [service executeQuery:batchQuery
//                              completionHandler:^(GTLServiceTicket *ticket,
//                                                  id object, NSError *error) {
//                                  // callback
//                                  self.editTaskTicket = nil;
//                                  
//                                  if (error == nil) {
//                                      GTLBatchResult *batchResults = (GTLBatchResult *)object;
//                                      NSString *status = wereAllTasksCompleted ? @"Uncompleted" : @"Completed";
//                                      
//                                      NSDictionary *successes = batchResults.successes;
//                                      NSDictionary *failures = batchResults.failures;
//                                      
//                                      NSUInteger numberUpdated = [successes count];
//                                      NSUInteger numberFailed = [failures count];
//                                      
//                                      NSArray *successTasks = [successes allValues];
//                                      NSArray *titles = [successTasks valueForKey:@"title"];
//                                      NSString *titlesStr = [titles componentsJoinedByString:@", "];
//                                      
//                                      [self displayAlert:@"Tasks Updated"
//                                                  format:@"%@: %lu\n%@\nErrors: %lu\n%@",
//                                       status,
//                                       (unsigned long) numberUpdated, titlesStr,
//                                       (unsigned long) numberFailed, failures];
//                                      
//                                      [self fetchTasksForSelectedList];
//                                  } else {
//                                      [self displayAlert:@"Error"
//                                                  format:@"%@", error];
//                                      [self updateUI];
//                                  }
//                              }];
//    [self updateUI];
//}
//
//#pragma mark Delete All Tasks
//
//- (void)deleteAllTasks {
//    // Make a batch of queries to delete all tasks
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    
//    GTLBatchQuery *batch = [GTLBatchQuery batchQuery];
//    
//    for (GTLTasksTask *task in self.tasks) {
//        GTLQueryTasks *query = [GTLQueryTasks queryForTasksDeleteWithTasklist:tasklist.identifier
//                                                                         task:task.identifier];
//        [batch addQuery:query];
//    }
//    
//    GTLServiceTasks *service = self.tasksService;
//    self.editTaskTicket = [service executeQuery:batch
//                              completionHandler:^(GTLServiceTicket *ticket,
//                                                  id object, NSError *error) {
//                                  // callback
//                                  self.editTaskTicket = nil;
//                                  
//                                  if (error == nil) {
//                                      GTLBatchResult *batch = (GTLBatchResult *)object;
//                                      
//                                      NSUInteger numberDeleted = [batch.successes count];
//                                      
//                                      [self displayAlert:@"Tasks Deleted"
//                                                  format:@"Deleted: %lu\nErrors: %@",
//                                       (unsigned long) numberDeleted,
//                                       batch.failures];
//                                      
//                                      [self fetchTasksForSelectedList];
//                                  } else {
//                                      [self displayAlert:@"Error"
//                                                  format:@"%@", error];
//                                      [self updateUI];
//                                  }
//                              }];
//    [self updateUI];
//}
//
//#pragma mark Move Task
//
//- (void)moveTaskWithIdentifier:(NSString *)taskID
//                    toParentID:(NSString *)destinationParentIDorNil
//                         index:(NSInteger)destinationIndex {
//    // Make all completed tasks hidden
//    GTLTasksTaskList *tasklist = [self selectedTaskList];
//    GTLQueryTasks *query = [GTLQueryTasks queryForTasksMoveWithTasklist:tasklist.identifier
//                                                                   task:taskID];
//    query.parent = destinationParentIDorNil;
//    
//    // Determine the ID of the task preceding the new location
//    if (destinationIndex > 0) {
//        GTLObject *parentTask;
//        if (destinationParentIDorNil) {
//            parentTask = [self taskWithIdentifier:destinationParentIDorNil
//                                        fromTasks:self.tasks];
//        } else {
//            // There is no parent; it's a top-level task
//            parentTask = self.tasks;
//        }
//        NSArray *children = [self taskChildrenForObject:parentTask];
//        
//        GTLTasksTask *previousTask = [children objectAtIndex:(destinationIndex - 1)];
//        query.previous = previousTask.identifier;
//    }
//    
//    GTLServiceTasks *service = self.tasksService;
//    self.editTaskTicket = [service executeQuery:query
//                              completionHandler:^(GTLServiceTicket *ticket,
//                                                  id item, NSError *error) {
//                                  // callback
//                                  self.editTaskTicket = nil;
//                                  
//                                  if (error == nil) {
//                                      [self fetchTasksForSelectedList];
//                                  } else {
//                                      [self displayAlert:@"Error"
//                                                  format:@"%@", error];
//                                      [self updateUI];
//                                  }
//                              }];
//    [self updateUI];
//}
@end
