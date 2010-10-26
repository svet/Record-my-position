// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface Share_tab : UIViewController <MFMailComposeViewControllerDelegate>
{
	/// Label used to display the number of entries.
	UILabel *counter_;

	/// Cached value of entries, to avoid disk roundtrips each time.
	int num_entries_;

	/// Switches and labels.
	UISwitch *switch_;

	/// Action buttons.
	UIButton *share_;
	UIButton *purge_;

	/// Shows a wait dialog along with a non touchable interface.
	UIView *shield_;
	UIActivityIndicatorView *activity_;
}

@property (nonatomic, assign) int num_entries;

- (id)init;

@end
