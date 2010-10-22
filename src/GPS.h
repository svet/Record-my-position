// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <CoreLocation/CoreLocation.h>

/** Wraps and controlls the GPS collection of data.
 *
 * Holds the pointer to the real sqlite object and provides additional
 * wrapper helper functions to handle the database.
 */
@interface GPS : NSObject <CLLocationManagerDelegate>
{
	/// Pointer to the manager activating/desactivating Core Location.
	CLLocationManager *manager_;

	/// Last received position.
	CLLocation *last_pos_;
}

@property (nonatomic, retain, readonly) CLLocation *last_pos;

+ (GPS*)get;
- (id)init;
- (bool)start;
- (void)stop;

@end
