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

	BOOL gps_is_on_;

	/// Watchdog timer to detect GPS entering into zombie state.
	NSTimer *zasca_;

	/// Set this to YES if you want to avoid logging by the GPS class.
	BOOL nolog_;
}

@property (nonatomic, retain, readonly) CLLocation *last_pos;
@property (nonatomic, readonly, assign) BOOL gps_is_on;

+ (GPS*)get;
+ (NSString*)degrees_to_dms:(CLLocationDegrees)value latitude:(BOOL)latitude;
+ (NSString*)key_path;
- (id)init;
- (bool)start;
- (void)stop;
- (void)add_watcher:(id)watcher;
- (void)remove_watcher:(id)watcher;


@end
