// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "GPS.h"

#import "macro.h"

@interface GPS ()
@end

@implementation GPS

static GPS *g_;

@synthesize last_pos = last_pos_;

/** Returns the pointer to the singleton GPS class.
 * The class will be constructed if necessary.
 */
+ (GPS*)get
{
	if (!g_)
		g_ = [GPS new];

	return g_;
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

	// Set a filter for 5m.
	manager_.distanceFilter = 5;

	// Try to get the best accuracy possible.
	manager_.desiredAccuracy = kCLLocationAccuracyBest;
	manager_.delegate = self;

	return self;
}

/** Starts the GPS tracking.
 * Returns false if the location services are not available.
 */
- (bool)start
{
	if (manager_.locationServicesEnabled) {
		[manager_ startUpdatingLocation];
		return true;
	} else {
		return false;
	}
}

/** Stops the GPS tracking.
 * You can call this function anytime, doesn't really fail.
 */
- (void)stop
{
	[manager_ stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager*)manager
		didUpdateToLocation:(CLLocation*)new_location
		fromLocation:(CLLocation*)old_location
{
	DLOG(@"Updating to %@", [new_location description]);

	if (new_location.horizontalAccuracy < 0) {
		DLOG(@"Bad returned accuracy, ignoring update.");
		return;
	}

	// Keep the new location for map showing.
	[self willChangeValueForKey:@"last_pos"];
	[last_pos_ release];
	[new_location retain];
	last_pos_ = new_location;
	[self didChangeValueForKey:@"last_pos"];
}

@end
