/* Copyright (c) 2011 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// OAuth2SampleRootViewControllerTouch.h

@class GTMOAuth2Authentication;

@interface RootViewController : UIViewController <UINavigationControllerDelegate, UITextFieldDelegate> {
  UISegmentedControl *mServiceSegments;
  UITextField *mClientIDField;
  UITextField *mClientSecretField;

  UILabel *mServiceNameField;
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
}

@property (nonatomic, strong) IBOutlet UITextField *clientIDField;
@property (nonatomic, strong) IBOutlet UITextField *clientSecretField;
@property (nonatomic, strong) IBOutlet UILabel *serviceNameField;
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

- (IBAction)serviceSegmentClicked:(id)sender;
- (IBAction)signInOutClicked:(id)sender;
- (IBAction)fetchClicked:(id)sender;
- (IBAction)expireNowClicked:(id)sender;
- (IBAction)toggleShouldSaveInKeychain:(id)sender;

- (void)signInToGoogle;
- (void)signInToDailyMotion;
- (void)signOut;
- (BOOL)isSignedIn;

- (void)updateUI;

@end
