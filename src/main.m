// vim:tabstop=4 shiftwidth=4 syntax=objc

#import <UIKit/UIKit.h>
#import "App_delegate.h"

int main(int argc, char *argv[])
{
	@autoreleasepool {
		int retVal = UIApplicationMain(argc, argv, nil,
            NSStringFromClass([App_delegate class]));
		return retVal;
	}
}
