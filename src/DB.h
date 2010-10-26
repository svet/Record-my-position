// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "egodatabase/EGODatabase.h"

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
}

+ (NSString*)path;
+ (DB*)open_database;
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
