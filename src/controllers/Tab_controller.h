#import <UIKit/UIKit.h>

@class Capture_tab;
@class Log_tab;
@class Share_tab;

@interface Tab_controller : UITabBarController
	<UITabBarControllerDelegate>
{
	/// Stores the different tab view controller classes.
	Capture_tab *capture_tab_;
	Log_tab *log_tab_;
	Share_tab *share_tab_;
}

- (id)init;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
