//
//  Constants.h
//  gTask
//
//  Created by LIANGJUN JIANG on 4/26/13.
//
//

#ifndef gTask_Constants_h


#define gTask_Constants_h
// Keychain item name for saving the user's authentication information
static NSString *const kShouldSaveInKeychainKey = @"shouldSaveInKeychain";
static NSString *const kKeychainItemName = @"gTasks: Google Tasks";
static NSString *const kGoogleClientIDKey          = @"GoogleClientID";
static NSString *const kGoogleClientSecretKey      = @"GoogleClientSecret";

static NSString *const kTaskStatusCompleted = @"completed";
static NSString *const kTaskStatusNeedsAction = @"needsAction";

#define myClientId @"580813237419.apps.googleusercontent.com"
#define mySecretKey @"1XLt_eUMs7hdIiqSDt04qe4-"

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IS_IPHONE_4 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 480.0f)
#endif
