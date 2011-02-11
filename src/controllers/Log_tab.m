// vim:tabstop=4 shiftwidth=4 syntax=objc

#import "controllers/Log_tab.h"


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

	todo_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 300, 20)];
	todo_.text = @"Not yet implemented";
	todo_.backgroundColor = [UIColor blackColor];
	todo_.textColor = [UIColor redColor];
	[self.view addSubview:todo_];
}

- (void)dealloc
{
	[todo_ release];
	[super dealloc];
}

@end
