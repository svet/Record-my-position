// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Capture_tab.h"

#import "GPS.h"
#import "macro.h"


@interface Capture_tab ()
- (void)switch_changed;
- (void)update_gui;
@end


@implementation Capture_tab

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Capture";
	return self;
}

- (void)dealloc
{
	[switch_ removeTarget:self action:@selector(switch_changed)
		forControlEvents:UIControlEventValueChanged];
	[switch_ release];
	[start_title_ release];
	[super dealloc];
}

- (void)loadView
{
	[super loadView];

	start_title_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 210, 20)];
	start_title_.text = @"Hello1";
	start_title_.numberOfLines = 0;
	start_title_.lineBreakMode = UILineBreakModeTailTruncation;
	start_title_.backgroundColor = [UIColor clearColor];
	start_title_.textColor = [UIColor blackColor];
	[self.view addSubview:start_title_];

	switch_ = [[UISwitch alloc] initWithFrame:CGRectMake(220, 20, 100, 20)];
	[switch_ addTarget:self action:@selector(switch_changed)
		forControlEvents:UIControlEventValueChanged];

	[self.view addSubview:switch_];
}

/** The view is going to be shown. Update it.
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self update_gui];
}

/** User toggled on/off GUI switch.
 */
- (void)switch_changed
{
	GPS *gps = [GPS get];

	if ([switch_ isOn]) {
		if (![gps start]) {
			switch_.on = false;

			UIAlertView *alert = [[UIAlertView alloc]
				initWithTitle:@"GPS" message:@"Couldn't start GPS"
				delegate:nil cancelButtonTitle:@"Oh!" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	} else {
		[gps stop];
	}

	[self update_gui];
}

/** Handles updating the gui labels and other state.
 */
- (void)update_gui
{
	if (switch_.on)
		start_title_.text = @"Reading GPS...";
	else
		start_title_.text = @"GPS off";
}


@end
