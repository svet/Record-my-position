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
	/// Keeps track of whether we are watching or not.
	BOOL watching_;

	/// Save in memory if we have to reestablish timers.
	BOOL reenable_timers_;
}

@property (nonatomic, retain) CLLocation *old_location;

- (id)init;

@end
