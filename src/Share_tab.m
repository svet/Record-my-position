// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Share_tab.h"

#import "DB.h"
#import "macro.h"


@interface Share_tab ()
- (void)update_gui;
- (void)increment_count:(NSNotification*)notification;
@end


@implementation Share_tab

@synthesize num_entries = num_entries_;

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Share";

	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(increment_count:) name:DB_bump_notification
		object:nil];

	return self;
}

- (void)loadView
{
	[super loadView];

	counter_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 300, 20)];
	counter_.text = @"0 entries available";
	counter_.backgroundColor = [UIColor clearColor];
	counter_.textColor = [UIColor blackColor];
	[self.view addSubview:counter_];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[counter_ release];
	[super dealloc];
}

/** The view is going to be shown. Update it.
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	DB *db = [DB get_db];
	self.num_entries = [db get_num_entries];
}

/** The view is going to dissappear.
 */
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)setNum_entries:(int)value
{
	num_entries_ = value;
	[self update_gui];
}

/** Handles updating the gui labels and other state.
 */
- (void)update_gui
{
	counter_.text = [NSString stringWithFormat:@"%d entries collected",
		self.num_entries];	
}

/** Handles receiving notifications.
 * This is used while the tab is open instead of querying the
 * database for new entries. Avoids a disk roundtrip.
 */
- (void)increment_count:(NSNotification*)notification
{
	self.num_entries += 1;
}

@end
