// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "controllers/View_controller.h"

/** Prompts the user to take a text or photo along with a position.
 * The location passed to the view through the property will be
 * stored in the database immediately to preserve the sequence.
 *
 * However, the text input can take some time, so the controller
 * retrieves the recently inserted row's identifier and uses it later
 * to update the text if there was any.
 */
@class CLLocation;

@interface Note_taking_controller : View_controller
	<UITextFieldDelegate, UIImagePickerControllerDelegate,
	UINavigationControllerDelegate>
{
	UIButton *cancel_;
	UIButton *save_;
	UIButton *photo_;
	UIButton *dismiss_;
	UITextField *text_;
	CLLocation *location_;

	/// Stores the identifier used by the database to generate the log entry.
	int location_id_;

	/// Caches the capacity of being able to take pictures.
	BOOL can_take_pictures_;
}

@property (nonatomic, retain) CLLocation *location;

- (id)init;

@end
