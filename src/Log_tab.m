// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Log_tab.h"


@implementation Log_tab

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Log";
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
