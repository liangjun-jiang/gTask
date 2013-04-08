//


#import "TaskTasksDetailViewController.h"

#define kTextFieldWidth	195.0
#define kTextHeight		34.0

@interface CustomTableViewCell : UITableViewCell
@property (nonatomic, strong) UITextField *textField;
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

@end;


@interface TaskTasksDetailViewController ()<UITextFieldDelegate, UITextViewDelegate>//, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate>
{
    NSUInteger selected;  
}


//@property (nonatomic, strong) NSArray *statusList;
//@property (nonatomic, strong) NSArray *alertMinsList;


@end

@implementation TaskTasksDetailViewController
//@synthesize statusList,alertMinsList;


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
//    self.statusList = @[@"completed",@"uncomplete",@"archieved", @"delete"];
//    self.alertMinsList = @[@"15",@"30",@"45",@"60",@"120",@"180"];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kAddTaskDueDate" object:self.task];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 60.0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1)
        return 150.0;
    else
        return 44.0;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    static NSString *TextViewCellIdentifier = @"TextViewCell";
    UITableViewCell *tableViewCell = nil;
    
    if (indexPath.row == 0) {
        CustomTableViewCell *cell = (CustomTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        cell.textLabel.font = SYSTEM_TEXT_FONT;
        cell.textField.font = SYSTEM_TEXT_FONT;
        cell.textField.delegate = self;
        cell.textField.tag = indexPath.row + 10;
        // Configure the cell...
        NSString *title = NSLocalizedString(@"TITILE", @"");
        NSString *textFieldText = self.task.title;
//        switch (indexPath.row) {
//            case 0:
//            {
//                title = NSLocalizedString(@"TITILE", @"");;
//                textFieldText = self.task.title;
//                break;
//            }
//            case 1:
//            {
//                title = NSLocalizedString(@"STATUS", @"");
//                textFieldText = self.task.status;
//                break;
//            }
//            case 2:
//            {
//                title = NSLocalizedString(@"DUE_DATE", @"");;
//                textFieldText = (self.task.updated == nil)?@"":[self.task.updated description];
//                break;
//            }
//            case 3:
//            {
//                title = NSLocalizedString(@"ALERT_AT", @"");;
//                textFieldText = @"";
//                break;
//            }
//            default:
//                break;
//        }
        cell.textLabel.text = title;
        cell.textField.text = textFieldText;
        tableViewCell = cell;
    } else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TextViewCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextViewCellIdentifier];
        }
        cell.textLabel.font = SYSTEM_TEXT_FONT;
        cell.textLabel.text = NSLocalizedString(@"NOTES", @"");
        UITextView *notesTextView = [[UITextView alloc] initWithFrame:CGRectMake(100, 5.0, kTextFieldWidth, 80.0)];
        notesTextView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        notesTextView.returnKeyType = UIReturnKeyDefault;
        notesTextView.font = SYSTEM_TEXT_FONT;
        notesTextView.delegate = self;
        notesTextView.backgroundColor = [UIColor clearColor];
        notesTextView.tag = indexPath.row + 10;
        cell.accessoryView = notesTextView;
        
        return cell;
    }
    
    return tableViewCell;
}


#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // we row this to top
//    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    [tableView deselectRowAtIndexPath:indexPath animated:NO];
//}


#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   self.task.title = textField.text;
//    NSInteger index = textField.tag / 10;
//    //Crap, I still need to iterate those
//    switch (index) {
//        case 0:
//            self.task.title = textField.text;
//            break;
//        case 1:
//            self.task.status = textField.text;
//            break;
//        case 2:
////            self.task.due = textField.text;
//            break;
//        case 3:
////            self.task.notes = textField.text;
//            break;
//        default:
//            break;
//    }
//    
  	[textField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    
//    [self.tableView reloadData];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // create a "done" item as the right barButtonItem so user can dismiss the keyboard
     UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem = doneItem;
    
    selected = 0;
//    selected = textField.tag - 10;
//    
//    if (textField.tag == 12)  // this is for due date
//    {
//        UIDatePicker *datePickerView = [[UIDatePicker alloc] initWithFrame:CGRectZero];
//        datePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
//        datePickerView.datePickerMode = UIDatePickerModeDate;
//
//        textField.inputView = datePickerView;
//        
//        // this animiation was from Apple Sample Code: DateCell
//        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
//		CGSize pickerSize = [datePickerView sizeThatFits:CGSizeZero];
//		CGRect startRect = CGRectMake(0.0,
//									  screenRect.origin.y + screenRect.size.height,
//									  pickerSize.width, pickerSize.height);
//		datePickerView.frame = startRect;
//		
//		// compute the end frame
//		CGRect pickerRect = CGRectMake(0.0,
//									   screenRect.origin.y + screenRect.size.height - pickerSize.height,
//									   pickerSize.width,
//									   pickerSize.height);
//        
//        [UIView animateWithDuration:0.3 animations:^{
//            datePickerView.frame = pickerRect;
//        }];
// 
//    } else if (textField.tag == 11 || textField.tag == 13 ) {
//        UIPickerView *categoryPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
//        categoryPicker.showsSelectionIndicator = YES;	// note this is default to NO
//        
//        
//        // this view controller is the data source and delegate
//        categoryPicker.delegate = self;
//        categoryPicker.dataSource = self;
//        
//        categoryPicker.tag = (textField.tag == 11)? 101:102;
//        
//        textField.inputView = categoryPicker;
//        
//        // this animiation was from Apple Sample Code: DateCell
//        CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
//		CGSize pickerSize = [categoryPicker sizeThatFits:CGSizeZero];
//		CGRect startRect = CGRectMake(0.0,
//									  screenRect.origin.y + screenRect.size.height,
//									  pickerSize.width, pickerSize.height);
//		categoryPicker.frame = startRect;
//		
//		// compute the end frame
//		CGRect pickerRect = CGRectMake(0.0,
//									   screenRect.origin.y + screenRect.size.height - pickerSize.height,
//									   pickerSize.width,
//									   pickerSize.height);
//        
//        [UIView animateWithDuration:0.3 animations:^{
//            categoryPicker.frame = pickerRect;
//        }];
//    }
    
}

#pragma mark - UITextView Delegate method
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.navigationItem.rightBarButtonItem = nil;
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem = doneItem;
    
    selected = 1;
//    selected = textView.tag-10;
    
}
- (void)textViewDidEndEditing:(UITextView *)textView
{
//    feedback.comments = textView.text;
    [textView resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - private method

- (void)onDone:(id)sender
{
    
    UITableViewCell *activeCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selected inSection:0]];
    if ([activeCell.accessoryView isKindOfClass:[UITextField class]])
    {
        UITextField *textField = (UITextField*)activeCell.accessoryView;
        if (textField.tag == 10) // for status
        {
            self.task.status = textField.text;
        }
//        else if (textField.tag == 13) // for alert date
//        {
//            //todo:
////            feedback.category = textField.text;
//        } else if (textField.tag == 12)
//        {
//            //todo
//            self.task.due = nil;
//        }
        
        [textField resignFirstResponder];
    } else if ([activeCell.accessoryView isKindOfClass:[UITextView class]])
    {
        UITextView *textView = (UITextView *)activeCell.accessoryView;
        self.task.notes = textView.text;
        [textView resignFirstResponder];
    } else  // rest should be just textfield
    {
        [(UITextField *)activeCell.accessoryView resignFirstResponder];
    }
}

#pragma mark UIPickerViewDelegate

//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
//{
//    NSIndexPath *indexPath;
//    CustomTableViewCell *cell;
//    if (pickerView.tag == 101) {
//        self.task.status = self.statusList[row];
//    } else {
//        indexPath = [NSIndexPath indexPathForRow:3 inSection:0];
//        cell = (CustomTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//        cell.textField.text = self.alertMinsList[row];
//    }
//    [self.tableView reloadData];
//}
//
//
//#pragma mark -
//#pragma mark UIPickerViewDataSource
//
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    return (pickerView.tag == 101)?self.statusList[row]:[NSString stringWithFormat:@"%@ mins", self.alertMinsList[row]];
//}
//
//- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
//{
//	CGFloat componentWidth = 280.0;
// 	return componentWidth;
//}
//
//- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
//{
//	return 40.0;
//}
//
//- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
//{
//	return (pickerView.tag == 101)?self.statusList.count:self.alertMinsList.count;
//}
//
//- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
//{
//	return 1;
//}

@end
