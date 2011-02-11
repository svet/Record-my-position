// vim:tabstop=4 shiftwidth=4 syntax=objc

#import "controllers/View_controller.h"


@implementation View_controller

/** Shows an OK popup alert to the user.
 */
- (void)warn:(NSString*)text title:(NSString*)title
{
	UIAlertView *alert = [[UIAlertView alloc]
		initWithTitle:title message:text
		delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

@end
