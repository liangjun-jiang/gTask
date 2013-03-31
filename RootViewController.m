
#import "RootViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2SignIn.h"

#import "GTLUtilities.h"
#import "GTMHTTPFetcherLogging.h"

#import "TaskListViewController.h"

static NSString *const kShouldSaveInKeychainKey = @"shouldSaveInKeychain";
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
- (void)doAnAuthenticatedAPIFetch;
- (void)displayAlertWithMessage:(NSString *)str;
- (BOOL)shouldSaveInKeychain;
- (void)saveClientIDValues;
- (void)loadClientIDValues;
- (void)displayAlert:(NSString *)title format:(NSString *)format, ...;

@end

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

    DebugLog(@"keyChain auth: %@",auth);
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

// I think this one matters.
- (BOOL)isSignedIn {
  BOOL isSignedIn = self.auth.canAuthorize;
  return isSignedIn;
}

- (BOOL)isGoogleSegmentSelected {
  int segmentIndex = self.serviceSegments.selectedSegmentIndex;
  return (segmentIndex == 0);
}

- (IBAction)serviceSegmentClicked:(id)sender {
  [self loadClientIDValues];
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
    DebugLog(@"Authentication error: %@", error);
    NSData *responseData = [error userInfo][@"data"]; // kGTMHTTPFetcherStatusDataKey
    if ([responseData length] > 0) {
      // show the body of the server's authentication failure response
      NSString *str = [[NSString alloc] initWithData:responseData
                                             encoding:NSUTF8StringEncoding];
      DebugLog(@"%@", str);
    }

    self.auth = nil;
  } else {
    // Authentication succeeded
    //
    //
      DebugLog(@"auth: succesfully!");
//      if (error == nil) {
//          self.tasksService.authorizer = auth;
//          TaskListViewController *tasksListViewController = [[TaskListViewController alloc] initWithStyle:UITableViewStylePlain];
//          tasksListViewController.tasksService = self.tasksService;
//          
//          [self.navigationController pushViewController:tasksListViewController animated:YES];
//          
//          DebugLog(@"sign in succesfuuly");
//      } else {
//          self.taskListsFetchError = error;
//          [self updateUI];
//      }

    // save the authentication object
    self.auth = auth;
  }

  [self updateUI];
}

- (void)doAnAuthenticatedAPIFetch {
    NSString *urlStr;
    if ([self isGoogleSegmentSelected]) {
    // Google tasks feed
     urlStr = @"https://www.googleapis.com/tasks/v1/users/@me/lists";
  }

  NSURL *url = [NSURL URLWithString:urlStr];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [self.auth authorizeRequest:request
            completionHandler:^(NSError *error) {
              NSString *output = nil;
              if (error) {
                output = [error description];
              } else {
               
                  self.tasksService.authorizer = self.auth;
                  TaskListViewController *tasksListViewController = [[TaskListViewController alloc] initWithStyle:UITableViewStylePlain];
                  tasksListViewController.tasksService = self.tasksService;
                  
                  [self.navigationController pushViewController:tasksListViewController animated:YES];
                  
                // We can get json data, but seems it's better to keep
                // the business logic to TaskListViewController
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
              }

//              [self displayAlertWithMessage:output];

              // the access token may have changed
//              [self updateUI];
            }];
    
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
  }
}

- (void)loadClientIDValues {
  // Load the client ID and secret from the prefs into the text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ([self isGoogleSegmentSelected]) {
    self.clientIDField.text = [defaults stringForKey:kGoogleClientIDKey];
    self.clientSecretField.text = [defaults stringForKey:kGoogleClientSecretKey];
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

}

- (IBAction)getTaskListsClicked:(id)sender {
    if (![self isSignedIn]) {
        [self signInOutClicked:nil];
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

@end
