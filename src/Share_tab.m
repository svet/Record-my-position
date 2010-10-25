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

	counter_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 300, 40)];
	counter_.text = @"0 entries available";
	counter_.backgroundColor = [UIColor clearColor];
	counter_.textColor = [UIColor blackColor];
	[self.view addSubview:counter_];

	share_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	share_.frame = CGRectMake(20, 300, 280, 40);
	[share_ setTitle:@"Send log by email" forState:UIControlStateNormal];
	[self.view addSubview:share_];

	purge_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	purge_.frame = CGRectMake(20, 200, 280, 40);
	[purge_ setTitle:@"Purge database" forState:UIControlStateNormal];
	[self.view addSubview:purge_];

	UILabel *delete_label = [[UILabel alloc]
		initWithFrame:CGRectMake(10, 70, 210, 40)];
	delete_label.text = @"Remove entries sent in email";
	delete_label.numberOfLines = 2;
	delete_label.backgroundColor = [UIColor clearColor];
	delete_label.textColor = [UIColor blackColor];
	[self.view addSubview:delete_label];
	[delete_label release];

	delete_switch_ = [[UISwitch alloc]
		initWithFrame:CGRectMake(220, 70, 100, 40)];
	//[delete_switch_ addTarget:self action:@selector(switch_changed)
		//forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:delete_switch_];

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
