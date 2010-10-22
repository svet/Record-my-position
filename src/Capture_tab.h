// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>

@interface Capture_tab : UIViewController
{
	UILabel *start_title_;
	UISwitch *switch_;

	UILabel *longitude_;
	UILabel *latitude_;
	UILabel *precission_;
	UILabel *altitude_;
}

- (id)init;

@end
