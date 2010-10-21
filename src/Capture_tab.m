// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Capture_tab.h"


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
}

- (void)dealloc
{
	[super dealloc];
}

@end
