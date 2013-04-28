
#import "AppDelegate.h"
#import "RootViewController.h"
#import "LoginViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "TaskListViewController.h"
#import "SHCViewController.h"

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(UIApplication *)application {
     self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    __block UINavigationController *navController = nil;
    
    [[[UIAlertView alloc] initWithTitle:@"auth desc" message:[self auth].debugDescription delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil] show];
    
    if([self auth].canAuthorize){
        NSString *urlStr = @"https://www.googleapis.com/tasks/v1/users/@me/lists";
        
        NSURL *url = [NSURL URLWithString:urlStr];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [self.auth authorizeRequest:request
                  completionHandler:^(NSError *error) {
                      NSString *output = nil;
                      if (error) {
                          output = [error description];
                      } else {
                          
                          self.tasksService.authorizer = self.auth;
//                          TaskListViewController *tasksListViewController = [[TaskListViewController alloc] initWithStyle:UITableViewStylePlain];
//                          tasksListViewController.tasksService = self.tasksService;
                          SHCViewController *shcViewController = [[SHCViewController alloc] initWithNibName:@"SHCViewController" bundle:nil];
                          shcViewController.tasksService = self.tasksService;
                          
                          
                          navController = [[UINavigationController alloc] initWithRootViewController:shcViewController];
                           self.window.rootViewController = navController;
                          
                      }
                      
                  }];
    } else {
    
        LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        navController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
         self.window.rootViewController = navController;
    }
   
    [self.window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
}


+(AppDelegate *)appDelegate
{
    return [[UIApplication sharedApplication] delegate];
    
}

- (void)signOut {
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
    
    // remove the stored Google authentication from the keychain, if any
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    
    LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    
    self.window.rootViewController = loginViewController;
    [self.window makeKeyAndVisible];

}


- (GTMOAuth2Authentication *)auth{
    // First, we'll try to get the saved Google authentication, if any, from
    // the keychain

    NSString *clientID = myClientId;
    NSString *clientSecret = mySecretKey;

    GTMOAuth2Authentication *auth = nil;

    if (clientID && clientSecret) {
        auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                     clientID:clientID
                                                                 clientSecret:clientSecret];
    }
    
    return auth;
}

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

@end

