//
//  LoginViewController.h
//  gTask
//
//  Created by LIANGJUN JIANG on 4/26/13.
//
//

#import <UIKit/UIKit.h>
#import "Constants.h"

#import "GTLTasks.h"
@class GTMOAuth2Authentication;

@interface LoginViewController : UIViewController
{
    int mNetworkActivityCounter;
    GTMOAuth2Authentication *mAuth;
}
@property (nonatomic, strong) GTMOAuth2Authentication *auth;
@property (nonatomic, weak) IBOutlet UIButton *signInButton;

@end
