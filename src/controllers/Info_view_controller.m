#import "Info_view_controller.h"

#import "ELHASO.h"
#import "NSArray+ELHASO.h"
#import "HTML_view_controller.h"


#define _FILENAME				@"index.plist"

@implementation Info_view_controller

@synthesize title = title_;
@synthesize items;

- (void)loadView
{
	[super loadView];

	self.navigationItem.title = self.title.length ? self.title : @"Info";
	self.navigationItem.titleView = nil;

	if (self.items.count < 1) {
		NSString *path = get_path(_FILENAME, DIR_BUNDLE);
		self.items = [NSArray arrayWithContentsOfFile:path];
	}
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *identifier = @"cell";
	UITableViewCell *cell = [tableView
		dequeueReusableCellWithIdentifier:identifier];

	if (cell == nil)
		cell = [[[UITableViewCell alloc]
			initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:identifier] autorelease];

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.textLabel.text = [self.items get:indexPath.row * 2];
	cell.textLabel.textColor = [UIColor colorWithRed:0x12 / 255.0
		green:0x65 / 255.0 blue:0x74 / 255.0 alpha:1];
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.minimumFontSize = 10;
	return cell;
}

/** Returns the total number of items or the number of rows in a section.
 */
- (NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)num_section
{
	return self.items.count / 2;
}

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *title = [self.items get:indexPath.row * 2];
	id content = [self.items get:indexPath.row * 2 + 1];

	if ([content isKindOfClass:[NSString class]]) {
		HTML_view_controller *controller = [HTML_view_controller new];
		controller.title = title;
		controller.filename = content;
		[self.navigationController pushViewController:controller animated:YES];
	} else {
		NSArray *child_items = content;
		if (child_items.count) {
			Info_view_controller *controller = [Info_view_controller new];
			controller.title = title;
			controller.items = child_items;
			[self.navigationController pushViewController:controller
				animated:YES];
		} else {
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		}
	}
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
