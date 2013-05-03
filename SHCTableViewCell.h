//
//  SHCTableViewCell.h
//  ClearStyle
//
//  Created by Colin Eberhardt on 23/08/2012.
//  Copyright (c) 2012 Colin Eberhardt. All rights reserved.
//

#import "SHCToDoItem.h"
#import "SHCTableViewCellDelegate.h"
#import "SHCStrikethroughLabel.h"
#import "GTLTasksTask.h"

#import <UIKit/UIKit.h>

// A custom table cell that renders SHCToDoItem items.
//
@interface SHCTableViewCell : UITableViewCell <UITextFieldDelegate>

// The item that this cell renders
@property (nonatomic) GTLTasksTask* todoItem;

// The object that acts as delegate for this cell. 
@property (nonatomic, assign) id<SHCTableViewCellDelegate> delegate;

// the label used to render the to-do text
@property (nonatomic, assign, readonly) SHCStrikethroughLabel* label;

@end
