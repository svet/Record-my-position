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

	/// Stores the state of the application for log entries.
	BOOL in_background_;
}

@property (nonatomic, assign) BOOL in_background;

+ (NSString*)path;
+ (void)preserve_old_db;
+ (DB*)open_database;
+ (BOOL)purge;
+ (DB*)get;
- (void)close;
- (void)log:(id)text_or_location;
- (void)flush;
- (int)get_num_entries;
- (Rows_to_attachment*)prepare_to_attach;

- (int)log_note:(CLLocation*)location;
- (void)update_note:(int)num text:(NSString*)text;
- (void)delete_note:(int)num;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
