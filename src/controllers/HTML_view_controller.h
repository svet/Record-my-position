#import "controllers/View_controller.h"
#import <MessageUI/MessageUI.h>

@class NSURL;

/** Shows an HTML to the user.
 *
 * Nothing fancy, the file comes from the bundle's resources.
 */
@interface HTML_view_controller : View_controller
	<UIWebViewDelegate, MFMailComposeViewControllerDelegate>
{
	/// Tracks our web view.
	UIWebView *web_view_;

	/// Put here the relative path to the file you want to show.
	NSString *filename_;

	/// Put here the title for the view.
	NSString *title_;

	/// Link to open externally, used by the alert delegate.
	NSURL *external_;
}

@property (nonatomic, retain) NSString *filename;
//@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSURL *external;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
