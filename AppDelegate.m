
#import "AppDelegate.h"
#import "RootViewController.h"
#import "LoginViewController.h"

@implementation AppDelegate

//@synthesize window = mWindow;
//@synthesize navigationController = mNavigationController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
     self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    RootViewController *rootViewController = [[RootViewController alloc] initWithStyle:UITableViewStyleGrouped];
//    self.window.rootViewController = rootViewController;
    
    LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    self.window.rootViewController = loginViewController;
    [self.window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

