// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "egodatabase/EGODatabase.h"

/** Wrapper around EGODatabase
 *
 * Holds the pointer to the real sqlite object and provides additional
 * wrapper helper functions to handle the database.
 */
@interface DB : EGODatabase
{
}

+ (NSString*)path;
+ (DB*)open_database;
+ (DB*)get_db;

@end
