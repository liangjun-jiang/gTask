



#import "Constants.h"
#import "GTLTasks.h"
@class GTMOAuth2Authentication;
@interface AppDelegate : NSObject <UIApplicationDelegate> 

@property (strong, nonatomic) UIWindow *window;
@property (readonly) GTLServiceTasks *tasksService;
+(AppDelegate *)appDelegate;
- (GTMOAuth2Authentication *)auth;
@end

