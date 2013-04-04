//


#import "TaskTasksDetailViewController.h"


static NSString *kTitleKey = @"sectionTitleKey";
static NSString *kSourceKey = @"sourceKey";
static NSString *kViewKey = @"viewKey";

#define kTextFieldWidth	195.0
#define kTextHeight		34.0

@interface CustomTableViewCell : UITableViewCell
@property (nonatomic, strong) UITextField *textField;
- (void)setContentForTableCellLabel:(NSString *)title textField:(NSString *)placeHolder keyBoardType:(NSNumber *)keyboardType;
@end

@implementation CustomTableViewCell
@synthesize textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.backgroundColor = [UIColor clearColor];
        CGRect frame = CGRectMake(100, 5.0, kTextFieldWidth, kTextHeight);
        textField = [[UITextField alloc] initWithFrame:frame];
        textField.borderStyle = UITextBorderStyleNone;
        textField.textColor = [UIColor blackColor];
        textField.font = [UIFont systemFontOfSize:13.0];
        textField.textAlignment = NSTextAlignmentLeft;
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.enabled = YES;
        textField.backgroundColor = [UIColor clearColor];
        textField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
        
        textField.returnKeyType = UIReturnKeyDone;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
        
        self.accessoryView = textField;
        
    }
    
    return self;
}

- (void)setContentForTableCellLabel:(NSString *)title textField:(NSString *)textFieldText keyBoardType:(NSNumber *)keyboardType
{
    
    self.textLabel.text = title;
    self.textField.text = textFieldText;
    self.textField.keyboardType = [keyboardType intValue];
    
}

@end;


@interface TaskTasksDetailViewController ()<UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate>
{
    NSUInteger selected;  
}

@property (nonatomic, strong) NSArray *dataSourceArray;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSArray *statusList;


@end

@implementation TaskTasksDetailViewController
@synthesize dataSourceArray, dataArray, statusList;


-(id)initWithTask:(GTLTasksTask *)mTask
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.task = mTask;
    }
    
    return self;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [SSThemeManager customizeTableView:self.tableView];
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
   self.title = self.task.title;
    
    // due, status, title, notes, completed at :time stamp
    self.statusList = @[@"completed",@"uncomplete",@"archieve", @"delete"];
  
    NSDictionary *dict0 = @{kTitleKey:@"Title", kSourceKey:self.task.title, kViewKey:[NSNumber numberWithInt:UIKeyboardAppearanceDefault]};
    NSDictionary *dict1 = @{kTitleKey:@"Status", kSourceKey:self.task.status, kViewKey:[NSNumber numberWithInt:UIKeyboardAppearanceDefault]};
    NSDictionary *dict2 = @{kTitleKey:@"complete At", kSourceKey:[self.task.completed description], kViewKey:[NSNumber numberWithInt:UIKeyboardTypeNamePhonePad]};
    NSDictionary *dict3 = @{kTitleKey:@"Update At", kSourceKey:[self.task.updated description], kViewKey:[NSNumber numberWithInt:UIKeyboardTypeNamePhonePad]};
    NSDictionary *dict4 = @{kTitleKey:@"note", kSourceKey:(self.task.notes==nil)?@"":self.task.notes , kViewKey:[NSNumber numberWithInt:UIKeyboardTypeDefault]};
   
    
    self.dataSourceArray = @[dict0, dict1,dict2,dict3,dict4];

    
    self.dataArray = [NSMutableArray arrayWithCapacity:[self.dataSourceArray count]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataSourceArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 60.0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self.dataSourceArray count] -1)
        return 100.0;
    else
        return 44.0;
    
}



- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *TextViewCellIdentifier = @"TextViewCell";
    UITableViewCell *tableViewCell = nil;
    
    if (indexPath.row != [self.dataSourceArray count] -1) {
        CustomTableViewCell *cell = (CustomTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        cell.textLabel.font = [UIFont boldSystemFontOfSize:13.0];
        cell.textField.delegate = self;
        cell.textField.tag = indexPath.row + 10;
        // Configure the cell...
        NSDictionary *infoDict = self.dataSourceArray[indexPath.row];
        [cell setContentForTableCellLabel:infoDict[kTitleKey] textField:infoDict[kSourceKey] keyBoardType:infoDict[kViewKey]];
        tableViewCell = cell;
    } else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TextViewCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextViewCellIdentifier];
        }
        cell.textLabel.font = SYSTEM_TEXT_FONT;
        cell.textLabel.text = self.dataSourceArray[indexPath.row][kTitleKey];
    
        // this should be reused!!!
        
        UITextView *commentTextView = [[UITextView alloc] initWithFrame:CGRectMake(100, 5.0, kTextFieldWidth, 80.0)];
        commentTextView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        // We also don't want to set the returnkey of keyboard "Done" for the TextView
        // because the user might just want to change to new line
        commentTextView.returnKeyType = UIReturnKeyDefault; 
        commentTextView.font = [UIFont systemFontOfSize:14.0f];
        commentTextView.delegate = self;
        commentTextView.backgroundColor = [UIColor clearColor];
        commentTextView.tag = indexPath.row + 10;
//        commentTextView.text = self.dataSourceArray[indexPath.row][kSourceKey];
        cell.accessoryView = commentTextView;
        
        return cell;
    }
    
    return tableViewCell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // we row this to top
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark  - IBAction Method

- (IBAction)onSubmit:(id)sender
{
    self.navigationItem.rightBarButtonItem = nil;
    
    // I don't want to collect those content from UITextField & UITextView Until right now
    // Since it will be another process of iterating the cells, and decide it is textfield or textview
    // Even though the user doesn't fill up with anything, the user email, name and device info will still be sent out
//    if (feedback.comments.length > 0) {
//        // we send the info to server
//        NSLog(@"feedback will be sent out: %@",feedback);
//    } else {
//        CustomAlertView *error = [[CustomAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"") message:NSLocalizedString(@"Comment can't be blank", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", @"") otherButtonTitles:nil, nil];
//        [error show];
//        
//    }
    
    
}

#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSDictionary *contentDictionary = nil;
    NSString *key = nil;
    // just don't want to iterate to rewrite those key titles again
    NSInteger index = textField.tag / 10;
    
    contentDictionary = self.dataSourceArray[index];
    key = contentDictionary[kTitleKey];  // we only care the section title
    [self.dataArray addObject:@{key:textField.text}];
    
    //Crap, I still need to iterate those
    switch (index) {
        case 0:
//            feedback.name = textField.text;
            break;
        case 1:
//            feedback.phone = textField.text;
            break;
        case 2:
//            feedback.email = textField.text;
            break;
        case 3:
//            feedback.category = textField.text;
            break;
        default:
            break;
    }
    
  	[textField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
     
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // create a "done" item as the right barButtonItem so user can dismiss the keyboard
     UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem = doneItem;
    selected = textField.tag - 10;
    
    if (textField.tag == 13)  // this is for feedback category
    {
        UIDatePicker *datePickerView = [[UIDatePicker alloc] initWithFrame:CGRectZero];
        datePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        datePickerView.datePickerMode = UIDatePickerModeDate;

        textField.inputView = datePickerView;
        
        // this animiation was from Apple Sample Code: DateCell
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGSize pickerSize = [datePickerView sizeThatFits:CGSizeZero];
		CGRect startRect = CGRectMake(0.0,
									  screenRect.origin.y + screenRect.size.height,
									  pickerSize.width, pickerSize.height);
		datePickerView.frame = startRect;
		
		// compute the end frame
		CGRect pickerRect = CGRectMake(0.0,
									   screenRect.origin.y + screenRect.size.height - pickerSize.height,
									   pickerSize.width,
									   pickerSize.height);
        
        [UIView animateWithDuration:0.3 animations:^{
            datePickerView.frame = pickerRect;
        }];
 
    } else if (textField.tag == 11) {
        UIPickerView *categoryPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
        categoryPicker.showsSelectionIndicator = YES;	// note this is default to NO
        
        
        // this view controller is the data source and delegate
        categoryPicker.delegate = self;
        categoryPicker.dataSource = self;
        
        textField.inputView = categoryPicker;
        
        // this animiation was from Apple Sample Code: DateCell
        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
		CGSize pickerSize = [categoryPicker sizeThatFits:CGSizeZero];
		CGRect startRect = CGRectMake(0.0,
									  screenRect.origin.y + screenRect.size.height,
									  pickerSize.width, pickerSize.height);
		categoryPicker.frame = startRect;
		
		// compute the end frame
		CGRect pickerRect = CGRectMake(0.0,
									   screenRect.origin.y + screenRect.size.height - pickerSize.height,
									   pickerSize.width,
									   pickerSize.height);
        
        [UIView animateWithDuration:0.3 animations:^{
            categoryPicker.frame = pickerRect;
        }];
    }
    
}

#pragma mark - UITextView Delegate method
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    selected = textView.tag-10;
    
}
- (void)textViewDidEndEditing:(UITextView *)textView
{
//    feedback.comments = textView.text;
    [textView resignFirstResponder];
}

#pragma mark - private method

- (void)onDone:(id)sender
{
    // we resign the textfield
    // Apple creates a numberpad (also decimal number pad) without "Done" which has a good reason.
    // It's not necessary to have to comply with it. But it's better to do so. The common practice in Apple's app is..
    // make the RightBarButtonItem dismiss the numberkeypad.
    
    
    UITableViewCell *activeCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selected inSection:0]];
    if ([activeCell.accessoryView isKindOfClass:[UITextField class]])
    {
        UITextField *textField = (UITextField*)activeCell.accessoryView;
        if (textField.tag == 11) // for phone
        {
//            feedback.phone = textField.text;
        } else if (textField.tag == 13) // for category
        {
//            feedback.category = textField.text;
        }
        
        [textField resignFirstResponder];
    } else if ([activeCell.accessoryView isKindOfClass:[UITextView class]])
    {
        UITextView *textView = (UITextView *)activeCell.accessoryView;
//        feedback.comments = textView.text;
        [textView resignFirstResponder];
    } else  // rest should be just textfield
    {
        [(UITextField *)activeCell.accessoryView resignFirstResponder];
    }
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // since we have only one textfield having a picker, so we hardcode where it is.
    NSIndexPath *pickerIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];
    CustomTableViewCell *cell = (CustomTableViewCell *)[self.tableView cellForRowAtIndexPath:pickerIndexPath];
    // we need to update the UI
    cell.textField.text = self.statusList[row];
}


#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.statusList objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	CGFloat componentWidth = 280.0;
 	return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [self.statusList count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

@end
