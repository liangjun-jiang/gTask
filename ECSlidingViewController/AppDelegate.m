//
//  AppDelegate.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "AppDelegate.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "TaskListViewController.h"
#import "LoginViewController.h"
#import "InitialSlidingViewController.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
//    __block UINavigationController *navController = nil;
    
    //    [[[UIAlertView alloc] initWithTitle:@"auth desc" message:[self auth].debugDescription delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil] show];
   
//    if([self auth].canAuthorize){
    
//        NSString *urlStr = @"https://www.googleapis.com/tasks/v1/users/@me/lists";
//        
//        NSURL *url = [NSURL URLWithString:urlStr];
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//        [self.auth authorizeRequest:request
//                  completionHandler:^(NSError *error) {
//                      NSString *output = nil;
//                      if (error) {
//                          output = [error description];
//                      } else {
//                          
//                          self.tasksService.authorizer = self.auth;
//                          TaskListViewController *tasksListViewController = [[TaskListViewController alloc] initWithStyle:UITableViewStylePlain];
//                          tasksListViewController.tasksService = self.tasksService;
//                          
//                          navController = [[UINavigationController alloc] initWithRootViewController:tasksListViewController];
//                          self.window.rootViewController = navController;
//                          
//                      }
//                      
//                  }];
//    } else {
//        [self displayLogin];
        
//        LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
//        navController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
//        self.window.rootViewController = navController;
//    }
    
//    [self.window makeKeyAndVisible];
    UIViewController *rootViewController = nil;
    if ([self auth].canAuthorize) {
        UIStoryboard *storyboard;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
        }
        InitialSlidingViewController *initialViewController = [storyboard instantiateInitialViewController];
        initialViewController.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"FirstTop"];
        rootViewController = initialViewController;
    } else {
        rootViewController = [[self storyBoard] instantiateViewControllerWithIdentifier:@"NavigationLogin"];
    }
//    self.window.rootViewController = [[self storyBoard] instantiateViewControllerWithIdentifier:([self auth].canAuthorize)?@"FirstTop":@"NavigationLogin"];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  /*
   Called when the application is about to terminate.
   Save data if appropriate.
   See also applicationDidEnterBackground:.
   */
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

#pragma mark -
#pragma mark - Login/Logout
- (void)displayLogin
{
    LoginViewController *login = [[self storyBoard] instantiateViewControllerWithIdentifier:@"Login"];
    self.window.rootViewController = login;
    [self.window makeKeyAndVisible];
}

- (UIStoryboard *)storyBoard
{
    UIStoryboard *storyboard;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        storyboard = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        storyboard = [UIStoryboard storyboardWithName:@"iPad" bundle:nil];
    }
    
    return storyboard;
}

-(UIViewController *)rootViewController {
    return [[self storyBoard] instantiateViewControllerWithIdentifier:@"FirstTop"];
}

@end
