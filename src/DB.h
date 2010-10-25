// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "egodatabase/EGODatabase.h"

@class CLLocation;

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
+ (DB*)get_db;
- (void)log:(id)text_or_location;
- (void)flush;
- (int)get_num_entries;

@end
