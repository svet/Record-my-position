// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Share_tab.h"


@implementation Share_tab

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Share";
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
