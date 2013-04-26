
#import "GTLTasks.h"
#import "Constants.h"

@class GTMOAuth2Authentication;

@interface RootViewController : UITableViewController <UINavigationControllerDelegate> {

  int mNetworkActivityCounter;
  GTMOAuth2Authentication *mAuth;
    
}


@property (nonatomic, strong) GTMOAuth2Authentication *auth;
//@property (nonatomic, strong) UITableView *mTableView;

- (void)signInOutClicked:(id)sender;
- (void)fetchClicked:(id)sender;
- (void)expireNowClicked:(id)sender;
- (IBAction)toggleShouldSaveInKeychain:(id)sender;

- (void)signInToGoogle;
- (void)signOut;
- (BOOL)isSignedIn;
- (void)updateUI;

@end
