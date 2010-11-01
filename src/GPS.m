// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "GPS.h"

#import "DB.h"
#import "macro.h"

#define _KEY_PATH			@"last_pos"
#define _WATCHDOG_SECONDS	(10 * 60)

@interface GPS ()
- (void)ping_watchdog;
- (void)stop_watchdog;
- (void)zasca;
@end

@implementation GPS

static GPS *g_;

@synthesize last_pos = last_pos_;
@synthesize gps_is_on = gps_is_on_;
@synthesize accuracy = accuracy_;

/** Returns the pointer to the singleton GPS class.
 * The class will be constructed if necessary.
 */
+ (GPS*)get
{
	if (!g_)
		g_ = [GPS new];

	return g_;
}

/** Converts a coordinate from degrees to decimal minute second format.
 * Specify with the latitude bool if you are converting the latitude
 * part of the coordinates, which has a different letter.
 *
 * \return Returns the string with the formated value as
 * Ddeg Mmin Ssec X, where X is a letter.
 */
+ (NSString*)degrees_to_dms:(CLLocationDegrees)value latitude:(BOOL)latitude
{
	const int degrees = fabsl(value);
	const double min_rest = (fabs(value) - degrees) * 60.0;
	const int minutes = min_rest;
	const double seconds = (min_rest - minutes) * 60.0;
	char letter = 0;
	if (latitude) {
		if (value > 0)
			letter = 'N';
		else if (value < 0)
			letter = 'S';
	} else {
		if (value > 0)
			letter = 'E';
		else if (value < 0)
			letter = 'W';
	}
	if (letter)
		return [NSString stringWithFormat:@"%ddeg %dmin %0.2fsec %c",
			degrees, minutes, seconds, letter];
	else
		return [NSString stringWithFormat:@"%ddeg %dmin %0.2fsec",
			degrees, minutes, seconds];
}

/** Initialises the GPS class.
 */
- (id)init
{
	if (!(self = [super init]))
		return nil;

	manager_ = [[CLLocationManager alloc] init];
	if (!manager_) {
		LOG(@"Couldn't instantiate CLLocationManager!");
		return nil;
	}

	// Set no filter and try to get the best accuracy possible.
	accuracy_ = HIGH_ACCURACY;
	manager_.distanceFilter = kCLDistanceFilterNone;
	manager_.desiredAccuracy = kCLLocationAccuracyBest;
	manager_.delegate = self;
	return self;
}

- (void)dealloc
{
	[self stop];
	[manager_ release];
	[super dealloc];
}

/** Starts the GPS tracking.
 * Returns false if the location services are not available.
 */
- (bool)start
{
	if (manager_.locationServicesEnabled) {
		if (!self.gps_is_on && !nolog_)
			[[DB get] log:@"Starting to update location"];

		[self ping_watchdog];

		[manager_ startUpdatingLocation];
		gps_is_on_ = YES;
		return true;
	} else {
		gps_is_on_ = NO;
		return false;
	}
}

/** Stops the GPS tracking.
 * You can call this function anytime, doesn't really fail.
 */
- (void)stop
{
	if (self.gps_is_on && !nolog_)
		[[DB get] log:@"Stopping to update location"];
	[self stop_watchdog];
	gps_is_on_ = NO;
	[manager_ stopUpdatingLocation];
}

/** Returns the string used by add_watcher: and removeObserver:.
 */
+ (NSString*)key_path
{
	return _KEY_PATH;
}

/** Registers an observer for changes to last_pos.
 * Observers will monitor the key_path value.
 */
- (void)add_watcher:(id)watcher
{
	[self addObserver:watcher forKeyPath:_KEY_PATH
		options:NSKeyValueObservingOptionNew context:nil];
}

/** Removes an observer for changes to last_pos.
 */
- (void)remove_watcher:(id)watcher
{
	[self removeObserver:watcher forKeyPath:_KEY_PATH];
}

/** Changes the desired accuracy of the GPS readings.
 * If the GPS is on, it will be reset just in case. Provide a reason
 * for the change or nil if you don't want to log the change.
 */
- (void)set_accuracy:(ACCURACY)accuracy reason:(NSString*)reason
{
	if (accuracy_ == accuracy)
		return;

	accuracy_ = accuracy;
	NSString *message = nil;
#define _MSG(X) \
	message = @"Setting accuracy to " # X ".";

	switch (accuracy) {
		case HIGH_ACCURACY:
			_MSG(HIGH_ACCURACY);
			manager_.distanceFilter = kCLDistanceFilterNone;
			manager_.desiredAccuracy = kCLLocationAccuracyBest;
			break;

		case MEDIUM_ACCURACY:
			_MSG(MEDIUM_ACCURACY);
			manager_.distanceFilter = 50;
			manager_.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
			break;

		case LOW_ACCURACY:
			_MSG(LOW_ACCURACY);
			manager_.distanceFilter = 150;
			manager_.desiredAccuracy = kCLLocationAccuracyHundredMeters;
			break;

		default:
			NSAssert(0, @"Unexpected accuracy value");
			return;
	}
#undef _MSG

	if (self.gps_is_on) {
		if (reason.length > 0)
			[[DB get] log:[NSString stringWithFormat:@"%@ Reason: %@",
				message, reason]];
		else
			[[DB get] log:message];

		nolog_ = YES;
		[self stop];
		[self start];
		nolog_ = NO;
	}
}

#pragma mark CLLocationManagerDelegate

/** Something bad happened retrieving the location. What?
 * We ignore location errors only. Rest are logged.
 */
- (void)locationManager:(CLLocationManager *)manager
	didFailWithError:(NSError *)error
{
	if (kCLErrorLocationUnknown == error)
		return;

	[[DB get] log:[NSString stringWithFormat:@"location error: %@", error]];
}

/** Receives a location update.
 * This generates the correct KVO messages to notify observers.
 * Also resets the watchdog. Repeated locations based on timestamp
 * will be discarded.
 */
- (void)locationManager:(CLLocationManager*)manager
		didUpdateToLocation:(CLLocation*)new_location
		fromLocation:(CLLocation*)old_location
{
	if (new_location.horizontalAccuracy < 0) {
		DLOG(@"Bad returned accuracy, ignoring update.");
		return;
	}

	if (self.last_pos &&
			[self.last_pos.timestamp isEqualToDate:new_location.timestamp]) {
		DLOG(@"Discarding repeated location %@", [new_location description]);
		return;
	}

	DLOG(@"Updating to %@", [new_location description]);

	// Keep the new location for map showing.
	[self willChangeValueForKey:_KEY_PATH];
	[new_location retain];
	[last_pos_ release];
	last_pos_ = new_location;
	[self didChangeValueForKey:_KEY_PATH];

	[self ping_watchdog];
}

#pragma mark Watchdog

/** Starts or refreshes the timer used for the GPS watchdog.
 * Sometimes if you loose network signal the GPS will stop updating
 * values even though the hardware may well be getting them. The
 * watchdog will set a time and force a stop/start if there were no
 * recent updates received.
 *
 * You have to call this function every time you start to watch
 * updates and every time you receive one, so the watchdog timer is
 * reset.
 *
 * Miss Merge: I'm walking on sunshine, woo hoo!
 */
- (void)ping_watchdog
{
	if (zasca_)
		[zasca_ invalidate];

	zasca_ = [NSTimer scheduledTimerWithTimeInterval:_WATCHDOG_SECONDS
		target:self selector:@selector(zasca) userInfo:nil repeats:NO];
}

/** Stops the watchdog, if it is on. Otherwise does nothing.
 */
- (void)stop_watchdog
{
	if (zasca_)
		[zasca_ invalidate];
	zasca_ = nil;
}

/** Handles the stop/start of the GPS.
 * Note that the stop/start will automatically reschedule the watchdog.
 */
- (void)zasca
{
	[[DB get] log:@"Watchdog timer kicking in due to inactivity."];
	nolog_ = YES;
	[self stop];
	[self start];
	nolog_ = NO;
}

@end
