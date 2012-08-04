#import <CoreLocation/CoreLocation.h>

/// Possible values for the accuracy setting of the GPS.
enum ACCURACY_ENUM
{
	HIGH_ACCURACY,			///< Best the device can provide. Default.
	MEDIUM_ACCURACY,		///< About 50m.
	LOW_ACCURACY,			///< 150m or more.
};

/// Required alias for enum.
typedef enum ACCURACY_ENUM ACCURACY;


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

	/// Current accuracy setting.
	ACCURACY accuracy_;

	/// Remembers if we are saving all the positions.
	BOOL save_all_positions_;
}

@property (nonatomic, retain, readonly) CLLocation *last_pos;
@property (nonatomic, readonly, assign) BOOL gps_is_on;
@property (nonatomic, readonly, assign) ACCURACY accuracy;
@property (nonatomic, assign) BOOL save_all_positions;

+ (GPS*)get;
+ (NSString*)degrees_to_dms:(CLLocationDegrees)value latitude:(BOOL)latitude;
+ (NSString*)key_path;
- (id)init;
- (bool)start;
- (void)stop;
- (void)add_watcher:(id)watcher;
- (void)remove_watcher:(id)watcher;
- (void)set_accuracy:(ACCURACY)accuracy reason:(NSString*)reason;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
