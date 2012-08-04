// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "DB_log.h"

#import "db/internal.h"
#import "macro.h"

#import "EHReachability.h"

#import <CoreLocation/CoreLocation.h>
#import <time.h>


@implementation DB_log

@synthesize text = text_;
@synthesize location = location_;

/** Constructs a text oriented log entry.
 */
- (id)init_with_string:(NSString*)text in_background:(BOOL)in_background
	accuracy:(ACCURACY)accuracy
{
	if (!(self = [super init]))
		return nil;

	self.text = text;
	row_type_ = DB_ROW_TYPE_LOG;
	accuracy_ = accuracy;
	timestamp_ = time(0);
	in_background_ = in_background;
	UIDevice *device = [UIDevice currentDevice];
	battery_level_ = device.batteryLevel;
	external_power_ = (UIDeviceBatteryStateCharging == device.batteryState ||
		UIDeviceBatteryStateFull == device.batteryState);
	reachability_ = !(NotReachable == [EHReachability current_status]);

	return self;
}

/** Constructs a location oriented log entry.
 */
- (id)init_with_location:(CLLocation*)location
	in_background:(BOOL)in_background accuracy:(ACCURACY)accuracy
{
	if (!(self = [super init]))
		return nil;

	self.location = location;
	row_type_ = DB_ROW_TYPE_COORD;
	accuracy_ = accuracy;
	timestamp_ = time(0);
	in_background_ = in_background;
	UIDevice *device = [UIDevice currentDevice];
	battery_level_ = device.batteryLevel;
	external_power_ = (UIDeviceBatteryStateCharging == device.batteryState ||
		UIDeviceBatteryStateFull == device.batteryState);
	reachability_ = !(NotReachable == [EHReachability current_status]);

	return self;
}

/** Debugging helper message.
 * Returns a string with a textual description of the object.
 */
- (NSString*)description
{
	if (DB_ROW_TYPE_COORD == row_type_)
		return [NSString stringWithFormat:@"DB_log(%@)",
			[self.location description]];
	else
		return [NSString stringWithFormat:@"DB_log(%@)", self.text];
}

@end
