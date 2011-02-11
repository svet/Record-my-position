// vim:tabstop=4 shiftwidth=4 syntax=objc

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"App_delegate");
	[pool release];
	return retVal;
}
