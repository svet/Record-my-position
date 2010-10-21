// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Capture_tab.h"

#import "macro.h"


@interface Capture_tab ()
- (void)switch_changed;
@end


@implementation Capture_tab

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Capture";
	return self;
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

- (void)dealloc
{
	[switch_ removeTarget:self action:@selector(switch_changed)
		forControlEvents:UIControlEventValueChanged];
	[switch_ release];
	[start_title_ release];
	[super dealloc];
}

- (void)switch_changed
{
	DLOG(@"Hey! %d", [switch_ isOn]);
}


@end
