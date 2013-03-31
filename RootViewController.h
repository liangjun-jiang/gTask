
#import "GTLTasks.h"

#define client_id @"580813237419.apps.googleusercontent.com"
#define client_secret @"1XLt_eUMs7hdIiqSDt04qe4-"

@class GTMOAuth2Authentication;

@interface RootViewController : UIViewController <UINavigationControllerDelegate, UITextFieldDelegate> {
  UILabel *mEmailField;
  UILabel *mAccessTokenField;
  UILabel *mExpirationField;
  UILabel *mRefreshTokenField;

  UIButton *mFetchButton;
  UIButton *mExpireNowButton;

  UISwitch *mShouldSaveInKeychainSwitch;

  UIBarButtonItem *mSignInOutButton;

  int mNetworkActivityCounter;
  GTMOAuth2Authentication *mAuth;
    
    
    //todo : demo purpose
    GTLTasksTaskLists *tasksLists_;
    GTLServiceTicket *taskListsTicket_;
    NSError *taskListsFetchError_;
    
    GTLServiceTicket *editTaskListTicket_;
    
    GTLTasksTasks *tasks_;
    GTLServiceTicket *tasksTicket_;
    NSError *tasksFetchError_;
    
    GTLServiceTicket *editTaskTicket_;
}

@property (nonatomic, strong) IBOutlet UILabel *emailField;
@property (nonatomic, strong) IBOutlet UILabel *accessTokenField;
@property (nonatomic, strong) IBOutlet UILabel *expirationField;
@property (nonatomic, strong) IBOutlet UILabel *refreshTokenField;
@property (nonatomic, strong) IBOutlet UIButton *fetchButton;
@property (nonatomic, strong) IBOutlet UIButton *expireNowButton;
@property (nonatomic, strong) IBOutlet UISegmentedControl *serviceSegments;
@property (nonatomic, strong) IBOutlet UISwitch *shouldSaveInKeychainSwitch;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *signInOutButton;

@property (nonatomic, strong) GTMOAuth2Authentication *auth;

- (IBAction)signInOutClicked:(id)sender;
- (IBAction)fetchClicked:(id)sender;
- (IBAction)expireNowClicked:(id)sender;
- (IBAction)toggleShouldSaveInKeychain:(id)sender;

- (void)signInToGoogle;
- (void)signOut;
- (BOOL)isSignedIn;
- (void)updateUI;

@end
