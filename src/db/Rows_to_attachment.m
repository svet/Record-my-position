// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "db/Rows_to_attachment.h"

#import "GPS.h"
#import "db/DB.h"
#import "db/internal.h"
#import "macro.h"



#define _MAX_EXPORT_ROWS		10000

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
		@"speed, direction, battery_level, external_power, reachability "
		@"FROM Positions WHERE id <= ? LIMIT ?",
		[NSNumber numberWithInt:max_row_],
		[NSNumber numberWithInt:_MAX_EXPORT_ROWS], nil];
	LOG_ERROR(result, nil, YES);

	NSMutableArray *strings = [NSMutableArray
		arrayWithCapacity:_MAX_EXPORT_ROWS / 4];

	BOOL add_header = YES;
	int last_id = -2;
	for (EGODatabaseRow* row in result) {
		// Should we preppend a text header with the column names?
		if (add_header) {
			[strings addObject:@"type,text,longitude,latitude,longitude,"
				@"latitude,h_accuracy,v_accuracy,altitude,timestamp,"
				@"in_background,requested_accuracy,speed,direction,"
				@"battery_level, external_power, reachability"];
			add_header = NO;
		}

		last_id = [row intForColumnIndex:0];
		const int type = [row intForColumnIndex:1];
		const int timestamp = [row intForColumnIndex:8];
		const int in_background = [row intForColumnIndex:9];
		const int requested_accuracy = [row intForColumnIndex:10];
		const double speed = [row doubleForColumnIndex:11];
		const double direction = [row doubleForColumnIndex:12];
		const double battery_level = [row doubleForColumnIndex:13];
		const int external_power = [row intForColumnIndex:14];
		const int reachability = [row intForColumnIndex:15];

		if (DB_ROW_TYPE_LOG == type) {
			[strings addObject:
				[NSString stringWithFormat:@"%d,%@,0,0,0,0,-1,-1,-1,%d,"
				@"%d,%d,-1.0,-1.0,%0.2f,%d,%d",
				DB_ROW_TYPE_LOG, [row stringForColumnIndex:2], timestamp,
				in_background, requested_accuracy, battery_level,
				external_power, reachability]];
		} else if (DB_ROW_TYPE_COORD == type) {
			const double longitude = [row doubleForColumnIndex:3];
			const double latitude = [row doubleForColumnIndex:4];
			[strings addObject:[NSString stringWithFormat:@"%d,,"
				@"%0.8f,%0.8f,%@,%@,%0.1f,%0.1f,%0.1f,%d,"
				@"%d,%d,%0.2f,%0.2f,%0.2f,%d,%d", DB_ROW_TYPE_COORD,
				longitude, latitude, [GPS degrees_to_dms:longitude latitude:NO],
				[GPS degrees_to_dms:latitude latitude:YES],
				[row doubleForColumnIndex:5], [row doubleForColumnIndex:6],
				[row doubleForColumnIndex:7], timestamp,
				in_background, requested_accuracy, speed, direction,
				battery_level, external_power, reachability]];
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
