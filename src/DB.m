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

#define _DB_MODEL_KEY			@"last_db_model"
#define _DB_MODEL_VERSION		2


NSString *DB_bump_notification = @"DB_bump_notification";


@interface DB ()
@end

@implementation DB

@synthesize in_background = in_background_;

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
 *
 * The function will check the user's default settings and verify
 * that the database model for the user is the same as the one we are
 * expecting. Otherwise it removes the file to force a purge.
 */
+ (DB*)open_database
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	const int db_version = [defaults integerForKey:_DB_MODEL_KEY];
	if (_DB_MODEL_VERSION != db_version) {
		DLOG(@"Preious DB model %d, I was expecting %d. Purging!", db_version,
			_DB_MODEL_VERSION);
		[DB purge];
	}

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
			@"type INTEGER NOT NULL,"
			@"text TEXT,"
			@"longitude REAL NOT NULL,"
			@"latitude REAL NOT NULL,"
			@"h_accuracy REAL NOT NULL,"
			@"v_accuracy REAL NOT NULL,"
			@"altitude REAL NOT NULL,"
			@"timestamp INTEGER NOT NULL,"
			@"in_background BOOL NOT NULL,"
			@"requested_accuracy INTEGER NOT NULL,"
			@"speed REAL NOT NULL,"
			@"direction REAL NOT NULL,"
			@"battery_level REAL NOT NULL,"
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

	[defaults setInteger:_DB_MODEL_VERSION forKey:_DB_MODEL_KEY];
	DLOG(@"Disk db open at %@", path);
	[[GPS get] add_watcher:db];
	return db;
}

/** Tries to remove the database file.
 * You should close the database before trying to remove it.
 *
 * Returns YES if the file was deleted.
 */
+ (BOOL)purge
{
	NSString *path = [DB path];
	NSFileManager *manager = [NSFileManager defaultManager];

	if (![manager fileExistsAtPath:path])
		return NO;

	NSError *error = nil;
	if ([manager removeItemAtPath:path error:&error]) {
		DLOG(@"Deleted %@", path);
		return YES;
	} else {
		DLOG(@"Couldn't unlink %@: %@", path, error);
		return NO;
	}
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

	const ACCURACY accuracy = [[GPS get] accuracy];
	DB_log *log = nil;
	if ([text_or_location respondsToSelector:@selector(coordinate)])
		log = [[DB_log alloc] init_with_location:text_or_location
			in_background:in_background_ accuracy:accuracy];
	else
		log = [[DB_log alloc] init_with_string:text_or_location
			in_background:in_background_ accuracy:accuracy];

	if (log)
		[buffer_ addObject:log];
	else
		DLOG(@"Couldn't add to buffer %@", text_or_location);

	if (buffer_.count >= _BUFFER)
		[self flush];

	if (log)
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

	for (DB_log *log in data) {
		BOOL ret = NO;
		if (_ROW_TYPE_COORD == log->row_type_) {
			ret = [self executeUpdateWithParameters:@"INSERT into Positions "
				@"(id, type, text, longitude, latitude, h_accuracy,"
				@"v_accuracy, altitude, timestamp, in_background,"
				@"requested_accuracy, speed, direction, battery_level) "
				@"VALUES (NULL, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
				[NSNumber numberWithInt:_ROW_TYPE_COORD],
				[NSNumber numberWithDouble:log.location.coordinate.longitude],
				[NSNumber numberWithDouble:log.location.coordinate.latitude],
				[NSNumber numberWithDouble:log.location.horizontalAccuracy],
				[NSNumber numberWithDouble:log.location.verticalAccuracy],
				[NSNumber numberWithDouble:log.location.altitude],
				[NSNumber numberWithInt:
					[log.location.timestamp timeIntervalSince1970]],
				[NSNumber numberWithBool:log->in_background_],
				[NSNumber numberWithInt:log->accuracy_],
				[NSNumber numberWithDouble:log.location.speed],
				[NSNumber numberWithDouble:log.location.course],
				[NSNumber numberWithFloat:log->battery_level_],
				nil];
		} else {
			NSAssert(_ROW_TYPE_LOG == log->row_type_, @"Bad log type?");
			ret = [self
				executeUpdateWithParameters:@"INSERT into Positions (id, type,"
				@"text, longitude, latitude, h_accuracy, v_accuracy,"
				@"altitude, timestamp, in_background,"
				@"requested_accuracy, speed, direction, battery_level) "
				@"VALUES (NULL, ?, ?, 0, 0, -1, -1,-1, ?, ?, ?, ?, ?, ?)",
				[NSNumber numberWithInt:_ROW_TYPE_LOG], log.text,
				[NSNumber numberWithInt:log->timestamp_],
				[NSNumber numberWithBool:log->in_background_],
				[NSNumber numberWithInt:log->accuracy_],
				[NSNumber numberWithDouble:log.location.speed],
				[NSNumber numberWithDouble:log.location.course],
				[NSNumber numberWithFloat:log->battery_level_],
				nil];
		}

		if (!ret)
			LOG(@"Couldn't insert %@:\n\t%@", log, [self lastErrorMessage]);

		[log release];
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
		@"altitude, timestamp, in_background, requested_accuracy,"
		@"speed, direction, battery_level "
		@"FROM Positions WHERE id <= ? LIMIT ?",
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
		const int in_background = [row intForColumnIndex:9];
		const int requested_accuracy = [row intForColumnIndex:10];
		const double speed = [row doubleForColumnIndex:11];
		const double direction = [row doubleForColumnIndex:12];
		const double battery_level = [row doubleForColumnIndex:13];

		if (_ROW_TYPE_LOG == type) {
			[strings addObject:
				[NSString stringWithFormat:@"%d,%@,0,0,0,0,-1,-1,-1,%d,"
				@"%d,%d,-1.0,-1.0,%0.2f",
				_ROW_TYPE_LOG, [row stringForColumnIndex:2], timestamp,
				in_background, requested_accuracy, battery_level]];
		} else if (_ROW_TYPE_COORD == type) {
			const double longitude = [row doubleForColumnIndex:3];
			const double latitude = [row doubleForColumnIndex:4];
			[strings addObject:[NSString stringWithFormat:@"%d,,"
				@"%0.8f,%0.8f,%@,%@,%0.1f,%0.1f,%0.1f,%d,"
				@"%d,%d,%0.2f,%0.2f,%0.2f", _ROW_TYPE_COORD,
				longitude, latitude, [GPS degrees_to_dms:longitude latitude:NO],
				[GPS degrees_to_dms:latitude latitude:YES],
				[row doubleForColumnIndex:5], [row doubleForColumnIndex:6],
				[row doubleForColumnIndex:7], timestamp,
				in_background, requested_accuracy, speed, direction,
				battery_level]];
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


/****************************************************************************/

@implementation DB_log

@synthesize text = text_;
@synthesize location = location_;

/** Constructs a text oriented log entry.
 */
- (id)init_with_string:(NSString*)text in_background:(BOOL)in_background
	accuracy:(ACCURACY)accuracy
{
	if (!(self = [super init]))
		return nil;

	self.text = text;
	row_type_ = _ROW_TYPE_LOG;
	accuracy_ = accuracy;
	timestamp_ = time(0);
	in_background_ = in_background;
	battery_level_ = [[UIDevice currentDevice] batteryLevel];

	return self;
}

/** Constructs a location oriented log entry.
 */
- (id)init_with_location:(CLLocation*)location
	in_background:(BOOL)in_background accuracy:(ACCURACY)accuracy
{
	if (!(self = [super init]))
		return nil;

	self.location = location;
	row_type_ = _ROW_TYPE_COORD;
	accuracy_ = accuracy;
	timestamp_ = time(0);
	in_background_ = in_background;
	battery_level_ = [[UIDevice currentDevice] batteryLevel];

	return self;
}

/** Debugging helper message.
 * Returns a string with a textual description of the object.
 */
- (NSString*)description
{
	if (_ROW_TYPE_COORD == row_type_)
		return [NSString stringWithFormat:@"DB_log(%@)",
			[self.location description]];
	else
		return [NSString stringWithFormat:@"DB_log(%@)", self.text];
}

@end
