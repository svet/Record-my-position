// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "DB.h"

#import "App_delegate.h"
#import "GPS.h"
#import "macro.h"

#import <CoreLocation/CoreLocation.h>
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


#define _BUFFER			50

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
			@"id INTEGER PRIMARY KEY AUTOINCREMENT,"
			@"type INTEGER,"
			@"text TEXT,"
			@"longitude REAL,"
			@"latitude REAL,"
			@"h_accuracy REAL,"
			@"v_accuracy REAL,"
			@"altitude REAL,"
			@"timestamp INTEGER,"
			@"CONSTRAINT Positions_unique UNIQUE (id))",
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
	[[GPS get] add_watcher:db];
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

/** Logs a text or location object.
 * The object is added to the memory buffer, which is flushed as needed. 
 * Returns YES if the operation succeeded.
 */
- (void)log:(id)text_or_location
{
	NSAssert(text_or_location, @"Need a non null object");
	if (!buffer_)
		buffer_ = [[NSMutableArray alloc] initWithCapacity:_BUFFER];

	[buffer_ addObject:text_or_location];

	if (buffer_.count >= _BUFFER)
		[self flush];
}

/** Stores the circular buffer to disk, freing the current buffer_.
 * You can call this function as many times as you want.
 */
- (void)flush
{
	NSMutableArray *data = buffer_;
	buffer_ = nil;
	if (!data)
		return;

	DLOG(@"Flushing %d entries to disk.", data.count);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	EGODatabaseResult *result;

	for (id log in data) {
		if ([log respondsToSelector:@selector(coordinate)]) {
			CLLocation *location = log;
			result = [self executeQueryWithParameters:@"INSERT into Positions "
				@"(id, type, text, longitude, latitude, h_accuracy,"
				@"v_accuracy, altitude, timestamp) VALUES (NULL, 1, NULL, "
				@"?, ?, ?, ?, ?, ?)",
				[NSNumber numberWithDouble:location.coordinate.longitude],
				[NSNumber numberWithDouble:location.coordinate.latitude],
				[NSNumber numberWithDouble:location.horizontalAccuracy],
				[NSNumber numberWithDouble:location.verticalAccuracy],
				[NSNumber numberWithDouble:location.altitude],
				[NSNumber numberWithInt:
					[location.timestamp timeIntervalSince1970]],
				nil];
		} else {
			NSAssert([log isKindOfClass:[NSString class]], @"Bad log type?");
			result = [self
				executeQueryWithParameters:@"INSERT into Positions (id, type,"
				@"text, longitude, latitude, h_accuracy, v_accuracy,"
				@"altitude, timestamp) VALUES (NULL, 0, ?, 0, 0, -1, -1,"
				@"-1, time(\"now\"))", log, nil];
		}

		if (result.errorCode)
			LOG(@"Couldn't insert %@:\n\t%@", log, result.errorMessage);
	}

	[pool drain];
	[data release];
}

#pragma mark KVO

/** Watches GPS changes.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:[GPS key_path]])
		[self log:[GPS get].last_pos];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change
			context:context];
}

@end
