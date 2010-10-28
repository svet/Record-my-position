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


#define _BUFFER					50
#define _MAX_EXPORT_ROWS		10000

#define _ROW_TYPE_LOG			0
#define _ROW_TYPE_COORD			1

NSString *DB_bump_notification = @"DB_bump_notification";


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
+ (DB*)get
{
	App_delegate *app = (id)[[UIApplication sharedApplication] delegate];
	return [app db];
}

/** Closes the database.
 * Unlinks the observer before doing so.
 */
- (void)close
{
	[[GPS get] remove_watcher:self];
	[super close];
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

	[[NSNotificationCenter defaultCenter]
		postNotificationName:DB_bump_notification object:self];
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
				@"v_accuracy, altitude, timestamp) VALUES (NULL, ?, NULL, "
				@"?, ?, ?, ?, ?, ?)",
				[NSNumber numberWithInt:_ROW_TYPE_COORD],
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
				@"altitude, timestamp) VALUES (NULL, ?, ?, 0, 0, -1, -1,"
				@"-1, strftime(\"%s\", \"now\"))",
				[NSNumber numberWithInt:_ROW_TYPE_LOG], log, nil];
		}

		if (result.errorCode)
			LOG(@"Couldn't insert %@:\n\t%@", log, result.errorMessage);
	}

	[pool drain];
	[data release];
}

/** Returns the number of entries collected so far.
 */
- (int)get_num_entries
{
	NSString *query = @"SELECT COUNT(id) FROM Positions";
	EGODatabaseResult *result = [self executeQuery:query];
	LOG_ERROR(result, query, NO);
	int total = 0;
	if (result.count > 0) {
		EGODatabaseRow *row = [result rowAtIndex:0];
		total += [row intForColumnIndex:0];
	}
	return total + buffer_.count;
}

/** Queries the database for rows to make an attachment from.
 * This will return a pointer to a Rows_to_attachment structure
 * which remembers the correct state of how many rows were prepared
 * to read, and other interesting stuff, so the GPS readings can
 * continue working in the background.
 */
- (Rows_to_attachment*)prepare_to_attach
{
	[self flush];

	int max_row = -1;
	NSString *query = @"SELECT MAX(id) FROM Positions";
	EGODatabaseResult *result = [self executeQuery:query];
	LOG_ERROR(result, query, NO);
	if (result.count > 0) {
		EGODatabaseRow *row = [result rowAtIndex:0];
		max_row = [row intForColumnIndex:0];
	}

	return [[Rows_to_attachment alloc] initWithDB:self
		max_row:max_row];
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

/****************************************************************************/

@implementation Rows_to_attachment

/** Constructs the object to handle attachments.
 * Pass the database pointer and the maximum row to export.
 */
- (id)initWithDB:(DB*)db max_row:(int)max_row
{
	if (!(self = [super init]))
		return nil;

	max_row_ = max_row;
	db_ = db;

	return self;
}

/** Returns the attachment to send as csv file.
 * Returns nil if there is no attachment or there was a problem (more likely)
 */
- (NSData*)get_attachment
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	EGODatabaseResult *result = [db_ executeQueryWithParameters:@"SELECT "
		@"id, type, text, longitude, latitude, h_accuracy, v_accuracy,"
		@"altitude, timestamp FROM Positions WHERE id <= ? LIMIT ?",
		[NSNumber numberWithInt:max_row_],
		[NSNumber numberWithInt:_MAX_EXPORT_ROWS], nil];
	LOG_ERROR(result, nil, YES);

	NSMutableArray *strings = [NSMutableArray
		arrayWithCapacity:_MAX_EXPORT_ROWS / 4];

	int last_id = -2;
	for (EGODatabaseRow* row in result) {
		last_id = [row intForColumnIndex:0];
		const int type = [row intForColumnIndex:1];
		const int timestamp = [row intForColumnIndex:8];
		if (_ROW_TYPE_LOG == type) {
			[strings addObject:
				[NSString stringWithFormat:@"%d,%@,0,0,0,0,-1,-1,-1,%d",
				_ROW_TYPE_LOG, [row stringForColumnIndex:2], timestamp]];
		} else if (_ROW_TYPE_COORD == type) {
			const double longitude = [row doubleForColumnIndex:3];
			const double latitude = [row doubleForColumnIndex:4];
			[strings addObject:[NSString stringWithFormat:@"%d,,"
				@"%0.8f,%0.8f,%@,%@,%0.1f,%0.1f,%0.1f,%d", _ROW_TYPE_COORD,
				longitude, latitude, [GPS degrees_to_dms:longitude latitude:NO],
				[GPS degrees_to_dms:latitude latitude:YES],
				[row doubleForColumnIndex:5], [row doubleForColumnIndex:6],
				[row doubleForColumnIndex:7], timestamp]];
		} else {
			NSAssert(0, @"Unknown database row type?!");
		}
	}

	NSString *string = [[strings componentsJoinedByString:@"\n"] retain];

	[pool drain];

	if (string && string.length < 2) {
		[string release];
		return nil;
	}

	NSData *ret = [string dataUsingEncoding:NSUTF8StringEncoding];
	NSAssert(ret.length >= string.length, @"Bad data conversion?");
	[string release];

	/* Signal remaining rows? */
	if (last_id >= 0 && last_id != max_row_) {
		max_row_ = last_id;
		remaining_ = YES;
	}

	return ret;
}

/** Deletes the rows returned by get_attachment.
 * Note that if you call this before get_attachment: the whole
 * database will be wiped out, since get_attachment might have limited
 * the maximum row to _MAX_EXPORT_ROWS.
 */
- (void)delete_rows
{
	EGODatabaseResult *result = [db_ executeQueryWithParameters:@"DELETE "
		@"FROM Positions WHERE id <= ?",
		[NSNumber numberWithInt:max_row_], nil];
	LOG_ERROR(result, nil, NO);
}

/** Returns YES if there were remaining rows not returned by get_attachment.
 */
- (bool)remaining
{
	return remaining_;
}

@end
