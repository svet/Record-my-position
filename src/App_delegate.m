#import "App_delegate.h"

#import "GPS.h"
#import "controllers/Tab_controller.h"
#import "db/DB.h"
#import "macro.h"
#import "Record_my_position-Swift.h"

#import "EHReachability.h"

/** \mainpage Record my position
 *
 * \section meta Meta
 *
 * You are reading the autogenerated Doxygen documentation extracted
 * from the project. Source code can be found at:
 * http://github.com/gradha/Record-my-position
 *
 * \section external-libs External libraries
 * Sqlite disk access is controlled through the singleton like DB
 * class built on top of a fork (http://github.com/gradha/egodatabase)
 * of the EGODatabase (http://developers.enormego.com/code/egodatabase/)
 * from enormego (http://enormego.com/).
 *
 * Fragments of code from a private library by Grzegorz Adam
 * Hankiewicz from Electric Hands Software (http://elhaso.es/) have
 * made it to Floki for hardware UDID detection. See licensing
 * information under \c external/egf/readme.txt.
 *
 * To be aware of the state of the network and show informative
 * messages to the user we use Apple's Reachability class
 * (http://developer.apple.com/iphone/library/samplecode/Reachability/index.html).
 * The class was renamed to RPReachability to avoid possible future
 * clashes with third party libraries which linked into us might
 * give problems due to including themselves a copy of the Reachability
 * class. Unfortunately in objective c there are no namespaces and
 * everybody has to suck it down and use ugly prefixes. Hah, just
 * look at the mess Apple did with the internal Message class in
 * their MessageUI framework. Madness.
 */

/// Pseudo constants.
static NSString *REACH_HOST = @"github.com";

// Private function forward declarations.
static void _set_globals(void);


@implementation App_delegate

@synthesize db = db_;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launch_options
{
	DLOG(@"Lunching application with %@", launch_options);

    SGPS* test = [SGPS get];
    [test start];
    test.gpsIsOn = YES;
    test.saveAllPositions = YES;

	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	_set_globals();
	[DB preserve_old_db];

	window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	window_.backgroundColor = [UIColor whiteColor];

	/** Set up the reachability class. This works slowly, so let it be first. */
	[EHReachability init_with_host:REACH_HOST];

	db_ = [DB open_database];
	if (!db_) {
		[self handle_error:@"Couldn't open database" do_abort:YES];
		return NO;
	}

	// For the moment we don't know what to do with this...
	if (launch_options)
		[db_ log:[NSString stringWithFormat:@"Launch options? %@",
			launch_options]];

	tab_controller_ = [Tab_controller new];
	[window_ addSubview:tab_controller_.view];

	[window_ makeKeyAndVisible];

	return YES;
}

/** Something stole the focus of the application.
 * Or the user might have locked the screen. Change to medium gps tracking.
 */
- (void)applicationWillResignActive:(UIApplication *)application
{
	[[GPS get] set_accuracy:MEDIUM_ACCURACY reason:@"Lost focus."];
	[db_ flush];
}

/** The application regained focus.
 * This is the pair to applicationWillResignActive.
 */
- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[GPS get] set_accuracy:HIGH_ACCURACY reason:@"Gained focus."];
}

/** The user quit the app, and we are supporting background operation.
 * Suspend GUI dependant timers and log status change.
 *
 * This method is only called if the app is running on a device
 * supporting background operation. Otherwise applicationWillTerminate
 * will be called instead.
 */
- (void)applicationDidEnterBackground:(UIApplication *)application
{
	db_.in_background = YES;
	[[GPS get] set_accuracy:LOW_ACCURACY reason:@"Entering background mode."];
	[db_ flush];
}

/** We were raised from the dead.
 * Revert bad stuff done in applicationDidEnterBackground to be nice.
 */
- (void)applicationDidBecomeActive:(UIApplication *)application
{
	db_.in_background = NO;
	[[GPS get] set_accuracy:HIGH_ACCURACY reason:@"Raising from background."];
}

/** Application shutdown. Save cache and stuff...
 * Note that the method could be called even during initialisation,
 * so you can't make any guarantees about objects being available.
 *
 * If background running is supported, applicationDidEnterBackground
 * is used instead.
 */
- (void)applicationWillTerminate:(UIApplication *)application
{
	if ([GPS get].gps_is_on)
		[db_ log:@"Terminating app while GPS was on..."];

	[db_ flush];
	[db_ close];

	// Save pending changes to user defaults.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
}

#pragma mark -
#pragma mark Memory management

/** Low on memory. Try to free as much as we can.
 */
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[db_ flush];
}

- (void)dealloc
{
	[tab_controller_ release];
	[window_ release];
	[super dealloc];
}

#pragma mark Normal methods

/** Handle reporting of errors to the user.
 * Pass the message for the error and a boolean telling to force
 * exit or let the user acknowledge the problem.
 */
- (void)handle_error:(NSString*)message do_abort:(BOOL)do_abort
{
	if (do_abort)
		abort_after_alert_ = YES;

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
		message:NON_NIL_STRING(message) delegate:self
		cancelButtonTitle:(do_abort ? @"Abort" : @"OK") otherButtonTitles:nil];
	[alert show];
	[alert release];
	DLOG(@"Error: %@", message);
}

/** Forces a deletion of the database.
 * The database will be recreated automatically. GPS detection will
 * be disabled for a moment to avoid race conditions.
 */
- (void)purge_database
{
	DLOG(@"Purging database.");
	[db_ flush];
	[db_ close];
	GPS *gps = [GPS get];
	const BOOL activate = gps.gps_is_on;
	[gps stop];

	[DB purge];

	db_ = [DB open_database];
	if (activate)
		[gps start];
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

@end

#pragma mark Global functions

BOOL g_is_multitasking = NO;
BOOL g_location_changes = NO;
BOOL g_region_monitoring = NO;

/** Updates the state of some global variables.
 * These are variables like g_is_multitasking, which can be read
 * by any one any time. Call this function whenever you want,
 * preferably during startup.
 */
static void _set_globals(void)
{
	UIDevice* device = [UIDevice currentDevice];

	if ([device respondsToSelector:@selector(isMultitaskingSupported)])
		g_is_multitasking = device.multitaskingSupported;
	else
		g_is_multitasking = NO;

	g_location_changes = NO;
	SEL getter = @selector(significantLocationChangeMonitoringAvailable);
	if ([CLLocationManager respondsToSelector:getter])
		if ([CLLocationManager performSelector:getter])
			g_location_changes = YES;

	getter = @selector(regionMonitoringAvailable);
	if ([CLLocationManager respondsToSelector:getter])
		if ([CLLocationManager performSelector:getter])
			g_region_monitoring = YES;
}

// vim:tabstop=4 shiftwidth=4 syntax=objc
