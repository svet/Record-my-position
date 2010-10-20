// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>

@class Tab_controller;

@interface App_delegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window_;
	Tab_controller *tab_controller_;
}

@end
