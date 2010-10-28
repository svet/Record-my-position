// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Share_tab.h"

#import "App_delegate.h"
#import "DB.h"
#import "macro.h"
#import "egf/hardware.h"


#define _SWITCH_KEY_NEGATED		@"remove_entries_negated"


@interface Share_tab ()
- (void)update_gui;
- (void)increment_count:(NSNotification*)notification;
- (void)switch_changed;
- (void)purge_database;
- (void)share_by_email;
@end


@implementation Share_tab

@synthesize num_entries = num_entries_;

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Share";

	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(increment_count:) name:DB_bump_notification
		object:nil];

	return self;
}

- (void)loadView
{
	[super loadView];

	// Counter label.
	counter_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 300, 40)];
	counter_.text = @"0 entries available";
	counter_.backgroundColor = [UIColor clearColor];
	counter_.textColor = [UIColor blackColor];
	[self.view addSubview:counter_];

	// Button to share data through email.
	share_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	share_.frame = CGRectMake(20, 300, 280, 40);
	[share_ setTitle:@"Send log by email" forState:UIControlStateNormal];
	[share_ addTarget:self action:@selector(share_by_email)
		forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:share_];

	// Button to purge disk database.
	purge_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
	purge_.frame = CGRectMake(20, 200, 280, 40);
	[purge_ setTitle:@"Purge database" forState:UIControlStateNormal];
	[purge_ addTarget:self action:@selector(purge_database)
		forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:purge_];

	// Temporary label for switch.
	UILabel *delete_label = [[UILabel alloc]
		initWithFrame:CGRectMake(10, 70, 210, 40)];
	delete_label.text = @"Remove entries sent by email";
	delete_label.numberOfLines = 2;
	delete_label.backgroundColor = [UIColor clearColor];
	delete_label.textColor = [UIColor blackColor];
	[self.view addSubview:delete_label];
	[delete_label release];

	// The actual switch.
	switch_ = [[UISwitch alloc]
		initWithFrame:CGRectMake(220, 70, 100, 40)];
	[switch_ addTarget:self action:@selector(switch_changed)
		forControlEvents:UIControlEventValueChanged];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	switch_.on = ![defaults boolForKey:_SWITCH_KEY_NEGATED];
	[self.view addSubview:switch_];

	/// The shield view with a spinning element.
	shield_ = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	shield_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	shield_.backgroundColor = [UIColor blackColor];
	shield_.alpha = 0.5;
	shield_.hidden = YES;
	[self.view addSubview:shield_];

	activity_ = [[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activity_.contentMode = UIViewContentModeCenter;
	activity_.frame = self.view.frame;
	activity_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	[shield_ addSubview:activity_];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[activity_ release];
	[shield_ release];
	[switch_ release];
	[purge_ release];
	[share_ release];
	[counter_ release];
	[super dealloc];
}

/** The view is going to be shown. Update it.
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	DB *db = [DB get];
	self.num_entries = [db get_num_entries];
}

/** The view is going to dissappear.
 */
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)setNum_entries:(int)value
{
	num_entries_ = value;
	[self update_gui];
}

/** Handles updating the gui labels and other state.
 */
- (void)update_gui
{
	counter_.text = [NSString stringWithFormat:@"%d entries collected",
		self.num_entries];
}

/** Handles receiving notifications.
 * This is used while the tab is open instead of querying the
 * database for new entries. Avoids a disk roundtrip.
 */
- (void)increment_count:(NSNotification*)notification
{
	self.num_entries += 1;
}

/** User toggled on/off the GUI switch.
 * Record the new setting in the user's preferences.
 */
- (void)switch_changed
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:!switch_.on forKey:_SWITCH_KEY_NEGATED];
	[defaults synchronize];
}

/** User clicked the purge button. Ask him if he's really serious.
 */
- (void)purge_database
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purge database?"
		message:@"Are you sure you want to purge the database?" delegate:self
		cancelButtonTitle:@"Wait, no" otherButtonTitles:@"Yeah", nil];
	[alert show];
	[alert release];
}

/** User clicked the share by email button. Prepare mail.
 * This function is split into share_by_email_prepare so that the
 * shield is refreshed immediately and the user sees it. Otherwise
 * the long processing might not allow the shield to come up immediately.
 */
- (void)share_by_email
{
	if (![MFMailComposeViewController canSendMail]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No email?"
			message:@"Uh oh, this thing can't send mail!" delegate:self
			cancelButtonTitle:@"Hmmm..." otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}

	shield_.hidden = NO;
	[activity_ startAnimating];
	[self performSelector:@selector(share_by_email_prepare) withObject:nil
		afterDelay:0];
}

/** Second part of share_by_email.
 * This does the long work of setting up the attachments to the
 * email, hopefully after the UI has been updated to show a
 * shield/processing screen.
 */
- (void)share_by_email_prepare
{
	MFMailComposeViewController *mail =
		[[MFMailComposeViewController alloc] init];
	mail.mailComposeDelegate = self;
	[mail setSubject:@"Sending some GPS readings"];
	[mail setMessageBody:@"Here, parse this.\n\n" isHTML:NO];

	rows_to_attach_ = [[DB get] prepare_to_attach];
	NSData *attachment = [rows_to_attach_ get_attachment];
	if (attachment) {
		NSDateComponents *now = [[NSCalendar currentCalendar]
			components:NSDayCalendarUnit | NSMonthCalendarUnit |
			NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit |
			NSSecondCalendarUnit fromDate:[NSDate date]];

		Hardware_info *info = get_hardware_info();

		[mail addAttachmentData:attachment mimeType:@"text/csv"
			fileName:[NSString stringWithFormat:@"positions %04d-%02d-%02d "
			@"%02d:%02d:%02d %s.csv", [now year], [now month], [now day],
			[now hour], [now minute], [now second],
			(info && info->name) ? (info->name) : ("unknown"), nil]];

		destroy_hardware_info(&info);
	}

	[self presentModalViewController:mail animated:YES];
	[mail release];
}

#pragma mark UIAlertViewDelegate protocol

/** Handles the alert view for purging the database.
 * If the button is not the cancel one, we purge the database now.
 */
- (void)alertView:(UIAlertView *)alertView
	clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < 1)
		return;

	App_delegate *app = [[UIApplication sharedApplication] delegate];
	[app purge_database];
	self.num_entries = 0;
}

#pragma mark MFMailComposeViewControllerDelegate

/** Forces dismissing of the view.
 * If there was no error and the user didn't cancel the thing, we
 * will remove the database entries.
 */
- (void)mailComposeController:(MFMailComposeViewController*)controller
	didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[self dismissModalViewControllerAnimated:YES];

	if (MFMailComposeResultCancelled == result ||
			MFMailComposeResultFailed == result)
		goto end;

	if ([rows_to_attach_ remaining]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Give me more!"
			message:@"Only a portion of data was sent. Send more emails."
			delegate:self cancelButtonTitle:@"Will do" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}

	if (switch_.on) {
		[rows_to_attach_ delete_rows];
		DB *db = [DB get];
		self.num_entries = [db get_num_entries];
	}

end:
	[rows_to_attach_ release];
	shield_.hidden = YES;
	[activity_ stopAnimating];
}


@end
