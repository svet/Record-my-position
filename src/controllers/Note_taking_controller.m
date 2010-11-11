// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "controllers/Note_taking_controller.h"

#import "macro.h"


@implementation Note_taking_controller

@synthesize location = location_;

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Take a note";
	can_take_pictures_ = [UIImagePickerController
		isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	return self;
}

- (void)loadView
{
	NSAssert(location_, @"You need to set the location before calling this!");
	[super loadView];

	dismiss_ = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	dismiss_.frame = self.view.frame;
	[dismiss_ addTarget:self action:@selector(dismiss_touches)
		forControlEvents:UIControlEventTouchDown];
	[self.view addSubview:dismiss_];

	// Cancel button.
	cancel_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	cancel_.frame = CGRectMake(10, 10, 300, 40);
	[cancel_ setTitle:@"Cancel note" forState:UIControlStateNormal];
	[cancel_ addTarget:self action:@selector(cancel_note)
		forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:cancel_];

	if (can_take_pictures_) {
		// Info about taking a picture.
		UILabel *label = [[UILabel alloc]
			initWithFrame:CGRectMake(10, 60, 300, 79)];
		label.text = @"You can take a photo and save it to your photo library, "
			@"but it won't be included in the application's logs, sorry.";
		label.numberOfLines = 0;
		label.font = [UIFont systemFontOfSize:16];
		[self.view addSubview:label];
		[label release];

		// Button to save a picture.
		photo_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
		photo_.frame = CGRectMake(10, 140, 300, 40);
		[photo_ setTitle:@"Take photo" forState:UIControlStateNormal];
		[photo_ addTarget:self action:@selector(take_photo)
			forControlEvents:UIControlEventTouchUpInside];
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

/** Dismisses the view, removing the previously entered log entry.
 */
- (void)cancel_note
{
	[self dismissModalViewControllerAnimated:YES];
}

/** Dismiss the view, possibly updating the text entry for the log.
 */
- (void)save_note
{
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
