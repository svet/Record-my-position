#import "db/DB.h"

#import "App_delegate.h"
#import "GPS.h"
#import "db/DB_log.h"
#import "db/Rows_to_attachment.h"
#import "db/internal.h"
#import "macro.h"

#import <CoreLocation/CoreLocation.h>


#define _BUFFER					50

#define _DB_MODEL_KEY			@"last_db_model"
#define _DB_MODEL_VERSION		3


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
			@"external_power INTEGER NOT NULL,"
			@"reachability INTEGER NOT NULL,"
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
		if (DB_ROW_TYPE_COORD == log->row_type_) {
			ret = [self executeUpdateWithParameters:@"INSERT into Positions "
				@"(id, type, text, longitude, latitude, h_accuracy,"
				@"v_accuracy, altitude, timestamp, in_background,"
				@"requested_accuracy, speed, direction, battery_level,"
				@"external_power, reachability) "
				@"VALUES (NULL, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,"
				@"?, ?)",
				[NSNumber numberWithInt:DB_ROW_TYPE_COORD],
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
				[NSNumber numberWithBool:log->external_power_],
				[NSNumber numberWithBool:log->reachability_],
				nil];
		} else {
			NSAssert(DB_ROW_TYPE_LOG == log->row_type_, @"Bad log type?");
			ret = [self
				executeUpdateWithParameters:@"INSERT into Positions (id, type,"
				@"text, longitude, latitude, h_accuracy, v_accuracy,"
				@"altitude, timestamp, in_background,"
				@"requested_accuracy, speed, direction, battery_level,"
				@"external_power, reachability) "
				@"VALUES (NULL, ?, ?, 0, 0, -1, -1,-1, ?, ?, ?, ?, ?, ?,"
				@"?, ?)",
				[NSNumber numberWithInt:DB_ROW_TYPE_LOG], log.text,
				[NSNumber numberWithInt:log->timestamp_],
				[NSNumber numberWithBool:log->in_background_],
				[NSNumber numberWithInt:log->accuracy_],
				[NSNumber numberWithDouble:log.location.speed],
				[NSNumber numberWithDouble:log.location.course],
				[NSNumber numberWithFloat:log->battery_level_],
				[NSNumber numberWithBool:log->external_power_],
				[NSNumber numberWithBool:log->reachability_],
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

#pragma mark Handling of notes

/** Logs a special note log with location.
 * This function flushes the database to disk, then creates a special
 * log entry whose identifier is returned back. With the returned
 * identifier you can later call update_note: or delete_note:.
 */
- (int)log_note:(CLLocation*)location;
{
	[self flush];

	DB_log *log = [[DB_log alloc] init_with_location:location
		in_background:in_background_ accuracy:[[GPS get] accuracy]];
	RASSERT(log, @"Couldn't create DB_log", return -1);

	const BOOL ret = [self executeUpdateWithParameters:@"INSERT into Positions "
		@"(id, type, text, longitude, latitude, h_accuracy,"
		@"v_accuracy, altitude, timestamp, in_background,"
		@"requested_accuracy, speed, direction, battery_level,"
		@"external_power, reachability) "
		@"VALUES (NULL, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,"
		@"?, ?)",
		[NSNumber numberWithInt:DB_ROW_TYPE_NOTE],
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
		[NSNumber numberWithBool:log->external_power_],
		[NSNumber numberWithBool:log->reachability_],
		nil];

	if (!ret) {
		LOG(@"Couldn't insert %@:\n\t%@", log, [self lastErrorMessage]);
		return -1;
	}

	[[NSNotificationCenter defaultCenter]
		postNotificationName:DB_bump_notification object:self];

	return [self last_insert_rowid];
}

/** Given a note identifier, updates the text.
 * Note that passing nil or a zero length text won't do anything
 * to the database.
 */
- (void)update_note:(int)num text:(NSString*)text
{
	if (!text || text.length < 1)
		return;

	const BOOL ret = [self executeUpdateWithParameters:@"UPDATE Positions "
		@"SET text = ? WHERE id = ?",
		text, [NSNumber numberWithInt:num], nil];

	if (!ret)
		LOG(@"Couldn't update %d with %@:\n\t%@", num, text,
			[self lastErrorMessage]);
}

/** Removes a note from the database according to its identifier.
 */
- (void)delete_note:(int)num
{
	NSString *sql = [NSString stringWithFormat:@"DELETE FROM Positions "
		@"WHERE id = %d", num];	
	EGODatabaseResult *result = [self executeQuery:sql];
	LOG_ERROR(result, sql, NO);

	// TODO: Sent notification of decreased log.
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

// vim:tabstop=4 shiftwidth=4 syntax=objc
