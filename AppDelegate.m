
#import "AppDelegate.h"
#import "RootViewController.h"
#import "TaskListViewController.h"

@implementation AppDelegate

@synthesize window = mWindow;
@synthesize navigationController = mNavigationController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
  [mWindow addSubview:[mNavigationController view]];
  [mWindow makeKeyAndVisible];
    
    [SSThemeManager customizeAppAppearance];
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

