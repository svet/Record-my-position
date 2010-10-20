// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "App_delegate.h"

#import "DB.h"
#import "Tab_controller.h"
#import "macro.h"


@implementation App_delegate

@synthesize db = db_;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	window_.backgroundColor = [UIColor whiteColor];

	db_ = [DB open_database];
	if (!db_) {
		[self handle_error:@"Couldn't open database" abort:YES];
		return NO;
	}

	tab_controller_ = [Tab_controller new];
	[window_ addSubview:tab_controller_.view];

	[window_ makeKeyAndVisible];

	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to
	 inactive state. This can occur for certain types of temporary
	 interruptions (such as an incoming phone call or SMS
	 message) or when the user quits the application and it
	 begins the transition to the background state.

	 Use this method to pause ongoing tasks, disable timers,
	 and throttle down OpenGL ES frame rates. Games should use
	 this method to pause the game.
	 */
}
#if 0
- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user
	 data, invalidate timers, and store enough application state
	 information to restore your application to its current
	 state in case it is terminated later.

	 If your application supports background execution, called
	 instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of      transition from the background to
	 the inactive state: here you can undo many of the changes
	 made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started)
	 while the application was inactive. If the application was
	 previously in the background, optionally refresh the user
	 interface.
	 */
}
#endif

/** Application shutdown. Save cache and stuff...
 * Note that the method could be called even during initialisation,
 * so you can't make any guarantees about objects being available.
 *
 * If background running is supported, applicationDidEnterBackground
 * is used instead.
 **/
- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 See also applicationDidEnterBackground:.
	 */
	[[DB get_db] close];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	/*
	 Free up as much memory as possible by purging cached data
	 objects that can be recreated (or reloaded from disk)
	 later.
	 */
}

- (void)dealloc
{
	[tab_controller_ release];
	[window_ release];
	[super dealloc];
}

/** Handle reporting of errors to the user.
 * Pass the message for the error and a boolean telling to force
 exit or let the user acknowledge the problem.
 */
- (void)handle_error:(NSString*)message abort:(BOOL)abort
{
	if (abort)
		abort_after_alert_ = YES;

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
		message:NON_NIL_STRING(message) delegate:self
		cancelButtonTitle:(abort ? @"Abort" : @"OK") otherButtonTitles:nil];
	[alert show];
	[alert release];
	DLOG(@"Error: %@", message);
}

#pragma mark UIAlertViewDelegate protocol

- (void)alertView:(UIAlertView *)alertView
	clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (abort_after_alert_) {
		DLOG(@"User closed dialog which aborts program. Bye bye!");
		exit(1);
	}
}

#pragma mark Global functions

/** Builds up the path of a file in a specific directory.
 * Note that making a path inside a DIR_BUNDLE will always fail if the file
 * doesn't exist (bundles are not allowed to be modified), while a path for
 * DIR_DOCS may succeed even if the file doesn't yet exists (useful to create
 * persistant configuration files).
 *
 * \return Returns an NSString with the path, or NULL if there was an error.
 * If you want to use the returned path with C functions, you will likely
 * call the method cStringUsingEncoding:1 on the returned object.
 */
NSString *get_path(NSString *filename, DIR_TYPE dir_type)
{
	switch (dir_type) {
		case DIR_BUNDLE:
		{
			NSString *path = [[NSBundle mainBundle]
				pathForResource:filename ofType:nil];

			if (!path)
				DLOG(@"File '%@' not found inside bundle!", filename);

			return path;
		}

		case DIR_DOCS:
		{
			NSArray *paths = NSSearchPathForDirectoriesInDomains(
				NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentsDirectory = [paths objectAtIndex:0];
			NSString *path = [documentsDirectory
				stringByAppendingPathComponent:filename];

			if (!path)
				DLOG(@"File '%@' not found inside doc directory!", filename);

			return path;
		}

		default:
			DLOG(@"Trying to use dir_type %d", dir_type);
			assert(0 && "Invalid get_path(dir_type).");
			return 0;
	}
}

@end
