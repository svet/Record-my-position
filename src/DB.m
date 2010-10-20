// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "DB.h"

#import "App_delegate.h"
#import "macro.h"

#import <time.h>

#ifdef DEBUG
#define LOG_ERROR(RES,QUERY,DO_ASSERT) do {									\
	if (RES.errorCode) {													\
		if (QUERY)															\
			DLOG(@"DB error running %@.\n%@", QUERY, RES.errorMessage);		\
		else																\
			DLOG(@"DB error code %d.\n%@", RES.errorCode, RES.errorMessage);\
		NSAssert(!(DO_ASSERT), @"Database query error");					\
	}																		\
} while(0)
#else
#define LOG_ERROR(RES,QUERY,DO_ASSERT) do { RES = nil; } while(0)
#endif

@interface DB ()
@end

@implementation DB

/** Returns the path to the database filename.
 */
+ (NSString*)path
{
	return get_path(@"appdb", DIR_DOCS);
}

/** Called once per application, initialises the global application database.
 * This function will generate the database tables if they weren't present.
 * Returns the DB pointer with a retain count of one or nil if there were
 * problems and the application should abort.
 */
+ (DB*)open_database
{
	NSString *path = [DB path];
	DB *db = [[DB databaseWithPath:path] retain];
	if (![db open]) {
		LOG(@"Couldn't open db %@", path);
		[db release];
		return nil;
	}

	NSArray *tables = [NSArray arrayWithObjects:
		@"CREATE TABLE IF NOT EXISTS Positions ("
			@"id INTEGER PRIMARY KEY,"
			@"name VARCHAR(255),"
			@"last_updated INTEGER,"
			@"CONSTRAINT Owners_unique UNIQUE (id, name))",
		nil];

	EGODatabaseResult *result;
	for (NSString *query in tables) {
		result = [db executeQuery:query];
		if (result.errorCode) {
			LOG(@"Couldn't %@: %@", query, result.errorMessage);
			[db release];
			return nil;
		}
	}

	DLOG(@"Disk db open at %@", path);
	return db;
}

/** Returns the application's pointer to the open database.
 * Nil if where were problems.
 */
+ (DB*)get_db
{
	App_delegate *app = (id)[[UIApplication sharedApplication] delegate];
	return [app db];
}

@end
