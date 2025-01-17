//
//  MBContactPicker.h
//  MBContactPicker
//  https://github.com/Citrrus/MBContactPicker
//
//  Created by Matt Bowman on 12/2/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBContactModel.h"
#import "MBContactCollectionView.h"
#import "MBContactCollectionViewContactCell.h"
#import "MBContactCollectionViewPromptCell.h"
#import "MBContactCollectionViewEntryCell.h"

@class MBContactPicker;

@protocol MBContactPickerDataSource <NSObject>

@optional

- (NSArray *)contactModelsForContactPicker:(MBContactPicker*)contactPickerView;
- (NSArray *)selectedContactModelsForContactPicker:(MBContactPicker*)contactPickerView;

@end

@protocol MBContactPickerDelegate <MBContactCollectionViewDelegate>

@optional

- (void)contactPicker:(MBContactPicker*)contactPicker didUpdateContentHeightTo:(CGFloat)newHeight;
- (void)contactPicker:(MBContactPicker*)contactPicker didChangeEntryText:(NSString *)entryText;
- (void)didShowFilteredContactsForContactPicker:(MBContactPicker*)contactPicker;
- (void)didHideFilteredContactsForContactPicker:(MBContactPicker*)contactPicker;

@end

@interface MBContactPicker : UIView <UITableViewDataSource, UITableViewDelegate, MBContactCollectionViewDelegate>

@property (nonatomic, weak) IBOutlet id<MBContactPickerDelegate> delegate;
@property (nonatomic, weak) IBOutlet id<MBContactPickerDataSource> datasource;
@property (nonatomic, readonly) NSArray *contactsSelected;
@property (nonatomic) NSInteger cellHeight;
@property (nonatomic, copy) NSString *prompt;
@property (nonatomic) CGFloat maxVisibleRows;
@property (nonatomic, readonly) CGFloat currentContentHeight;
@property (nonatomic, readonly) CGFloat keyboardHeight;
@property (nonatomic) CGFloat animationSpeed;
@property (nonatomic) BOOL allowsCompletionOfSelectedContacts;
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL showPrompt;
@property (nonatomic, strong) UIFont *font UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign, readonly, getter=isInvalidContact) BOOL invalidContact;

- (void)reloadData;
- (NSString*)phoneNumberFromText:(NSString*)text;

@end
