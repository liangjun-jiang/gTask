
#import "GTLTasks.h"

#define client_id @"580813237419.apps.googleusercontent.com"
#define client_secret @"1XLt_eUMs7hdIiqSDt04qe4-"

@class GTMOAuth2Authentication;

@interface RootViewController : UIViewController <UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate> {

  int mNetworkActivityCounter;
  GTMOAuth2Authentication *mAuth;
    
}


@property (nonatomic, strong) GTMOAuth2Authentication *auth;
@property (nonatomic, strong) UITableView *mTableView;

- (void)signInOutClicked:(id)sender;
- (void)fetchClicked:(id)sender;
- (void)expireNowClicked:(id)sender;
- (IBAction)toggleShouldSaveInKeychain:(id)sender;

- (void)signInToGoogle;
- (void)signOut;
- (BOOL)isSignedIn;
- (void)updateUI;

@end
