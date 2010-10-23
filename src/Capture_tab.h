// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>

@class CLLocation;

@interface Capture_tab : UIViewController
{
	UILabel *start_title_;
	UISwitch *switch_;

	UILabel *longitude_;
	UILabel *latitude_;
	UILabel *precission_;
	UILabel *altitude_;
	UILabel *ago_;
	UILabel *movement_;

	UILabel *clock_;
	NSTimer *timer_;

	CLLocation *old_location_;
}

@property (nonatomic, retain) CLLocation *old_location;

- (id)init;

@end
