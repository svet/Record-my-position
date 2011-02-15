// vim:tabstop=4 shiftwidth=4 syntax=objc

#import "controllers/Note_taking_controller.h"

#import "db/DB.h"
#import "macro.h"


@implementation Note_taking_controller

@synthesize location = location_;

- (id)init
{
	if (!(self = [super init]))
		return nil;

	location_id_ = -1;
	self.title = @"Take a note";
	can_take_pictures_ = [UIImagePickerController
		isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	return self;
}

- (void)loadView
{
	NSAssert(location_, @"You need to set the location before calling this!");
	[super loadView];

	UIImageView *background = [[UIImageView alloc]
		initWithImage:[UIImage imageNamed:@"back.jpg"]];
	[self.view addSubview:background];
	[background release];

	dismiss_ = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	dismiss_.frame = self.view.frame;
	[dismiss_ addTarget:self action:@selector(dismiss_touches)
		forControlEvents:UIControlEventTouchDown];
	_MAKE_BUTTON_LABEL_COLOR(dismiss_.titleLabel);
	[self.view addSubview:dismiss_];

	// Cancel button.
	cancel_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	cancel_.frame = CGRectMake(10, 10, 300, 40);
	[cancel_ setTitle:@"Cancel note" forState:UIControlStateNormal];
	[cancel_ addTarget:self action:@selector(cancel_note)
		forControlEvents:UIControlEventTouchUpInside];
	_MAKE_BUTTON_LABEL_COLOR(cancel_.titleLabel);
	[self.view addSubview:cancel_];

	if (can_take_pictures_) {
		// Info about taking a picture.
		UILabel *label = [[UILabel alloc]
			initWithFrame:CGRectMake(10, 60, 300, 79)];
		label.text = @"You can take a photo and save it to your photo library, "
			@"but it won't be included in the application's logs, sorry.";
		label.numberOfLines = 0;
		label.font = [UIFont systemFontOfSize:16];
		_MAKE_DEFAULT_LABEL_COLOR(label);
		[self.view addSubview:label];
		[label release];

		// Button to save a picture.
		photo_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
		photo_.frame = CGRectMake(10, 140, 300, 40);
		[photo_ setTitle:@"Take photo" forState:UIControlStateNormal];
		[photo_ addTarget:self action:@selector(take_photo)
			forControlEvents:UIControlEventTouchUpInside];
		_MAKE_BUTTON_LABEL_COLOR(photo_.titleLabel);
		[self.view addSubview:photo_];
	}

	// Text entry field.
	text_ = [[UITextField alloc] initWithFrame:CGRectMake(10, 200, 300, 28)];
	text_.placeholder = @"Optionally add some text";
	text_.borderStyle = UITextBorderStyleRoundedRect;
	text_.clearButtonMode = UITextFieldViewModeAlways;
	text_.delegate = self;
	[self.view addSubview:text_];

	// Button to save the current note.
	save_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	save_.frame = CGRectMake(10, 400, 300, 40);
	[save_ setTitle:@"Save note" forState:UIControlStateNormal];
	[save_ addTarget:self action:@selector(save_note)
		forControlEvents:UIControlEventTouchUpInside];
	_MAKE_BUTTON_LABEL_COLOR(save_.titleLabel);
	[self.view addSubview:save_];

	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)dealloc
{
	[dismiss_ release];
	[text_ release];
	[photo_ release];
	[save_ release];
	[cancel_ release];
	[location_ release];
	[super dealloc];
}

/** Verify that the identifier is ok.
 */
- (void)viewDidAppear:(BOOL)animated
{
	if (location_id_ < 0)
		[self warn:@"Couldn't get saved location id!" title:@"Error saving"];
}

/** Handles setting the location, which triggers lots of side effects.
 * The location will be immediately saved into the database and a
 * row identifier will be saved into location_id_. Later this identifier
 * is used to update the text of the note should the user take any,
 * or remove the entry if the user cancels the note.
 */
- (void)setLocation:(CLLocation*)location
{
	[location retain];
	[location_ release];
	location_ = location;

	if (location)
		location_id_ = [[DB get] log_note:location];
	else
		location_id_ = -1;
}

/** Dismisses the view, removing the previously entered log entry.
 */
- (void)cancel_note
{
	[[DB get] delete_note:location_id_];
	[self dismissModalViewControllerAnimated:YES];
}

/** Dismiss the view, possibly updating the text entry for the log.
 */
- (void)save_note
{
	[[DB get] update_note:location_id_ text:text_.text];
	[self dismissModalViewControllerAnimated:YES];
}

/** Show the photo taking view.
 */
- (void)take_photo
{
	[text_ resignFirstResponder];

	// TODO: Put here a shield to let the user know we are waiting. Run async.
	UIImagePickerController *picker = [UIImagePickerController new];
	picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	picker.delegate = self;
	[self presentModalViewController:picker animated:YES];

	[picker release];
}

/** Handles the touching on any part of the interface not active.
 * The purpose of this is to let the user tap anywhere and hide the keybaord.
 */
- (void)dismiss_touches
{
	[text_ resignFirstResponder];
}

#pragma UITextFieldDelegate

/** Allows return key to hide the keyboard.
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[text_ resignFirstResponder];
	return YES;
}

#pragma UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
	didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
	if (!image)
		image = [info objectForKey:UIImagePickerControllerOriginalImage];

	if (image) {
		DLOG(@"Saving image asynchronously, not checking errors, lalala");
		UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
	} else {
		DLOG(@"Errr... weren't we saving something here?");
	}

	[picker dismissModalViewControllerAnimated:YES];
}

@end
