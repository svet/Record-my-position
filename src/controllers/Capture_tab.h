#import "controllers/View_controller.h"

@class CLLocation;

@interface Capture_tab : View_controller
{
	UILabel *start_title_;
	UISwitch *start_switch_;
	UISwitch *record_type_switch_;
	UILabel *explanation_label_;

	UILabel *longitude_;
	UILabel *latitude_;
	UILabel *precission_;
	UILabel *altitude_;
	UILabel *ago_;
	UILabel *movement_;
	UILabel *capabilities_;

	UILabel *clock_;
	NSTimer *timer_;

	UIButton *note_;

	CLLocation *old_location_;
	/// Keeps track of whether we are watching or not.
	BOOL watching_;

	/// Save in memory if we have to reestablish timers.
	BOOL reenable_timers_;
}

@property (nonatomic, retain) CLLocation *old_location;

- (id)init;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
