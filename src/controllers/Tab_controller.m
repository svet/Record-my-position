// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "controllers/Tab_controller.h"

#import "controllers/Capture_tab.h"
#import "controllers/Log_tab.h"
#import "controllers/Share_tab.h"


@implementation Tab_controller

/** Initialises the tab controller.
 * Creates the classes for the viewing.
 */
- (id)init
{
	if (!(self = [super init]))
		return nil;

	capture_tab_ = [Capture_tab new];
	//log_tab_ = [Log_tab new];
	share_tab_ = [Share_tab new];

	if (!capture_tab_ || !share_tab_)
		return nil;

	// Create the tab bar items to associate icons.
	UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:@"Capture"
		image:[UIImage imageNamed:@"capture_icon.png"] tag:0];
	capture_tab_.tabBarItem = item;
	[item release];

	item = [[UITabBarItem alloc] initWithTitle:@"Share"
		image:[UIImage imageNamed:@"share_icon.png"] tag:0];
	share_tab_.tabBarItem = item;
	[item release];

	self.viewControllers = [NSArray arrayWithObjects:capture_tab_,
		share_tab_, nil];
	self.delegate = self;

	return self;
}

- (void)dealloc
{
	[log_tab_ release];
	[share_tab_ release];
	[capture_tab_ release];
	[super dealloc];
}

- (void)loadView
{
	[super loadView];
}

/** Support only the portrait orientation.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:
	(UIInterfaceOrientation)orientation
{
	return (UIInterfaceOrientationPortrait == orientation);
}

@end
