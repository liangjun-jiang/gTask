

@interface AppDelegate : NSObject <UIApplicationDelegate> {
 @private
  UIWindow *mWindow;
  UINavigationController *mNavigationController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UINavigationController *navigationController;

@end

