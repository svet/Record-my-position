#import "controllers/HTML_view_controller.h"

#import "ELHASO.h"


@implementation HTML_view_controller

@synthesize filename = filename_;
//@synthesize title = title_;
@synthesize external = external_;

- (void)loadView
{
	[super loadView];

	self.navigationItem.title = self.title;
	//self.navigationItem.titleView = nil;
	web_view_ = [[UIWebView alloc] initWithFrame:self.view.bounds];
	//web_view_.scalesPageToFit = YES;
	web_view_.autoresizesSubviews = YES;
	web_view_.autoresizingMask = FLEXIBLE_SIZE;
	web_view_.delegate = self;
	web_view_.dataDetectorTypes = UIDataDetectorTypeNone;
	NSString *path = get_path(self.filename, DIR_BUNDLE);
	if (path)
		[web_view_ loadRequest:[NSURLRequest requestWithURL:
			[NSURL fileURLWithPath:path]]];
	[self.view addSubview:web_view_];
	[web_view_ release];
}

- (void)dealloc
{
	[external_ release];
	[title_ release];
	[filename_ release];
	[web_view_ stopLoading];
	[web_view_ release];
	[super dealloc];
}

/** Used by the web view delegate to open an url.
 * Before calling this you are meant to set the self.external variable properly.
 */
- (void)alert_opening_url
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enlace externo"
		message:@"¿Desea abrir el enlace en Safari? La aplicación será cerrada"
		delegate:self cancelButtonTitle:@"Cancelar"
		otherButtonTitles:@"Aceptar", nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView
	clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex) {
		DLOG(@"Opening %@!", self.external);
		[[UIApplication sharedApplication] openURL:self.external];
	}
}

#pragma mark UIWebViewDelegate protocol

- (void)webViewDidStartLoad:(UIWebView*)webView
{
	DLOG(@"Started loading.");
}

- (void)webViewDidFinishLoad:(UIWebView*)webView
{
	DLOG(@"Did finish load");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	DLOG(@"Failed load with %@", error);
}

- (BOOL)webView:(UIWebView *)webView
	shouldStartLoadWithRequest:(NSURLRequest *)request
	navigationType:(UIWebViewNavigationType)navigationType
{
	switch (navigationType) {
		case UIWebViewNavigationTypeLinkClicked:
		case UIWebViewNavigationTypeFormSubmitted:
		case UIWebViewNavigationTypeFormResubmitted: {
			DLOG(@"Requesting %@", request);
			if (NSOrderedSame ==
					[[[request URL] scheme] caseInsensitiveCompare:@"mailto"]) {
				DLOG(@"Mailto not implemented");
				//[self show_mail_composer:[[request URL] resourceSpecifier]];
			} else {
				self.external = request.URL;
				[self alert_opening_url];
			}
			return NO;
		}
		default:
			return YES;
	}
	return YES;
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
