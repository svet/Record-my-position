// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "egodatabase/EGODatabase.h"

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
