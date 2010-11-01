// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "egodatabase/EGODatabase.h"

#import "GPS.h"

@class CLLocation;
@class Rows_to_attachment;

extern NSString *DB_bump_notification;

/** Wrapper around EGODatabase
 *
 * Holds the pointer to the real sqlite object and provides additional
 * wrapper helper functions to handle the database.
 */
@interface DB : EGODatabase
{
	/// Stores pointers to the logs not yet flushed to disk.
	NSMutableArray *buffer_;

	/// Stores the state of the application for log entries.
	BOOL in_background_;
}

@property (nonatomic, assign) BOOL in_background;

+ (NSString*)path;
+ (DB*)open_database;
+ (BOOL)purge;
+ (DB*)get;
- (void)close;
- (void)log:(id)text_or_location;
- (void)flush;
- (int)get_num_entries;
- (Rows_to_attachment*)prepare_to_attach;

@end


/** Temporary holder for SQLite to attachment interface.
 */
@interface Rows_to_attachment : NSObject
{
	/// Stores the top row to fetch.
	int max_row_;

	/// Pointer to database.
	DB* db_;

	BOOL remaining_;
}

- (id)initWithDB:(DB*)db max_row:(int)max_row;
- (void)delete_rows;
- (NSData*)get_attachment;
- (bool)remaining;

@end


/** In memory object holding log entry information before flushing.
 * This class is used to store the text or coordinate logs and
 * additional device information which is dependant of the recording
 * moment, like whether the device was in foreground/background or
 * the battery level value.
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
