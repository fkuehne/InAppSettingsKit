//
//  IASKSpecifierValuesViewController.m
//  http://www.inappsettingskit.com
//
//  Copyright (c) 2009:
//  Luc Vandal, Edovia Inc., http://www.edovia.com
//  Ortwin Gentz, FutureTap GmbH, http://www.futuretap.com
//  All rights reserved.
// 
//  It is appreciated but not required that you give credit to Luc Vandal and Ortwin Gentz, 
//  as the original authors of this code. You can give credit in a blog post, a tweet or on 
//  a info page of your app. Also, the original authors appreciate letting them know if you use this code.
//
//  This code is licensed under the BSD license that is available at: http://www.opensource.org/licenses/bsd-license.php
//

#import "IASKSpecifierValuesViewController.h"
#import "IASKSpecifier.h"
#import "IASKSettingsReader.h"
#import "IASKMultipleValueSelection.h"
#import "IASKAppSettingsViewController.h"

#define kCellValue      @"kCellValue"

@interface IASKSpecifierValuesViewController()

@property (nonatomic, strong, readonly) IASKMultipleValueSelection *selection;
@property (nonatomic) BOOL didFirstLayout;
@end

@implementation IASKSpecifierValuesViewController
@synthesize settingsReader = _settingsReader;
@synthesize settingsStore = _settingsStore;

- (void)setSettingsStore:(id <IASKSettingsStore>)settingsStore {
    _settingsStore = settingsStore;
    _selection.settingsStore = settingsStore;
}

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    self.view = _tableView;

    _selection = [IASKMultipleValueSelection new];
    _selection.tableView = _tableView;
    _selection.settingsStore = _settingsStore;
}

- (void)viewWillAppear:(BOOL)animated {
    if (_currentSpecifier) {
        [self setTitle:[_currentSpecifier title]];
        _selection.specifier = _currentSpecifier;
    }
    
    if (_tableView) {
        [_tableView reloadData];
		_selection.tableView = _tableView;
    }
	self.didFirstLayout = NO;
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[_tableView flashScrollIndicators];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	if (!self.didFirstLayout) {
		// Make sure the currently checked item is visible
		// this needs to be done as early as possible when pushing the view but after the first layout
		// otherwise scrolling to the first entry doesn't respect tableView.contentInset
		[_tableView scrollToRowAtIndexPath:_selection.checkedItem
						  atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		self.didFirstLayout = YES;
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    _selection.tableView = nil;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_currentSpecifier multipleValuesCount];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return [_currentSpecifier footerText];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell   = [tableView dequeueReusableCellWithIdentifier:kCellValue];
    NSArray *titles         = [_currentSpecifier multipleTitles];
    NSArray *iconNames      = [_currentSpecifier multipleIconNames];
	
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellValue];
    }

    [_selection updateSelectionInCell:cell indexPath:indexPath];

    @try {
        [[cell textLabel] setText:[self.settingsReader titleForId:[titles objectAtIndex:indexPath.row]]];
        if ((NSInteger)iconNames.count > indexPath.row) {
            NSString *iconName = iconNames[indexPath.row];
            // This tries to read the image from the main bundle. As this is currently not supported in
            // system settings, this should be the correct behaviour. (Idea: abstract away and try different
            // paths?)
            UIImage *image = [UIImage imageNamed:iconName];
            cell.imageView.image = image;
        }
    }
    @catch (NSException * e) {}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(settingsViewController:shouldSetMultiValueForSpecifier:toValueAtIndex:)] &&
        ![self.delegate settingsViewController:self
               shouldSetMultiValueForSpecifier:self.currentSpecifier
                                toValueAtIndex:indexPath.row]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
    }
    [_selection selectRowAtIndexPath:indexPath];
}

- (CGSize)preferredContentSize {
    return [[self view] sizeThatFits:CGSizeMake(320, 2000)];
}

@end
