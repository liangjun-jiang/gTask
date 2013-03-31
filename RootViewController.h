
#import "GTLTasks.h"

#define client_id @"580813237419.apps.googleusercontent.com"
#define client_secret @"1XLt_eUMs7hdIiqSDt04qe4-"

@class GTMOAuth2Authentication;

@interface RootViewController : UIViewController <UINavigationControllerDelegate, UITextFieldDelegate> {
  UILabel *mEmailField;
  UISwitch *mShouldSaveInKeychainSwitch;

  int mNetworkActivityCounter;
  GTMOAuth2Authentication *mAuth;
    
}

@property (nonatomic, strong) IBOutlet UILabel *emailField;
@property (nonatomic, strong) IBOutlet UISwitch *shouldSaveInKeychainSwitch;

@property (nonatomic, strong) GTMOAuth2Authentication *auth;

- (void)signInOutClicked:(id)sender;
- (void)fetchClicked:(id)sender;
- (void)expireNowClicked:(id)sender;
- (IBAction)toggleShouldSaveInKeychain:(id)sender;

- (void)signInToGoogle;
- (void)signOut;
- (BOOL)isSignedIn;
- (void)updateUI;

@end
