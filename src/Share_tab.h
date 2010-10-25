// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>

@interface Share_tab : UIViewController
{
	/// Label used to display the number of entries.
	UILabel *counter_;

	/// Cached value of entries, to avoid disk roundtrips each time.
	int num_entries_;

	/// Switches and labels.
	UISwitch *delete_switch_;

	/// Action buttons.
	UIButton *share_;
	UIButton *purge_;
}

@property (nonatomic, assign) int num_entries;

- (id)init;

@end
