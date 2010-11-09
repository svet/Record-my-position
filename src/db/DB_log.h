// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "GPS.h"

@class CLLocation;

/** In memory object holding log entry information before flushing.
 * This class is used to store the text or coordinate logs and
 * additional device information which is dependant of the recording
 * moment, like whether the device was in foreground/background or
 * the battery level value.
 *
 * Consider all these objects as immutable. There are no accessors
 * for most attributes because this class is basically a glorified
 * structure.
 */
@interface DB_log : NSObject
{
@public
	/// Used to differentiate originating row types. Don't trust the pointers.
	int row_type_;

	/// Seconds since epoch for the event.
	int timestamp_;

	/// Tells if the application was in foreground.
	BOOL in_background_;

	/// Battery level at the time of logging.
	float battery_level_;

	/// Accuracy setting at the time of logging.
	ACCURACY accuracy_;

	/// Tells if the device is connected to an external power source.
	BOOL external_power_;

	/// Tells if online connection to an external site is possible.
	BOOL reachability_;

@protected
	/// Stores the pointer to the text object. May be nil.
	NSString *text_;

	/// Stores the pointer to the location object. May be nil.
	CLLocation *location_;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) CLLocation *location;

- (id)init_with_string:(NSString*)text in_background:(BOOL)in_background
	accuracy:(ACCURACY)accuracy;

- (id)init_with_location:(CLLocation*)location
	in_background:(BOOL)in_background accuracy:(ACCURACY)accuracy;

- (NSString*)description;

@end
