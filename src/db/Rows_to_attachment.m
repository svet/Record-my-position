#import "db/Rows_to_attachment.h"

#import "GPS.h"
#import "db/DB.h"
#import "db/internal.h"
#import "macro.h"

#include <time.h>

#define _MAX_EXPORT_ROWS		10000

/// Forward static declarations.
static NSString *gpx_timestamp(const time_t timestamp);


@implementation Attachment

@synthesize data = data_;
@synthesize mime_type = mime_type_;
@synthesize extension = extension_;

- (void)dealloc
{
	[data_ release];
	[mime_type_ release];
	[extension_ release];
	[super dealloc];
}


@end


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

/** Builds and returns the attachments to send.
 * This function always generates a CSV attachment. Pass YES if you
 * want to generate also a GPX version. This function has the side
 * effect of modifying max_row_ and remaining_ to allow multiple
 * exportations.
 *
 * Returns an empty array if there is no attachment or there was a
 * problem (more likely)
 */
- (NSArray*)get_attachments:(BOOL)make_gpx
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

	NSMutableArray *ret = [[NSMutableArray arrayWithCapacity:2] retain];
	NSMutableArray *csv_strings = [NSMutableArray
		arrayWithCapacity:_MAX_EXPORT_ROWS / 4];

	NSMutableArray *gpx_strings = make_gpx ? [NSMutableArray
		arrayWithCapacity:_MAX_EXPORT_ROWS / 4] : nil;

	BOOL add_header = YES;
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
		const int external_power = [row intForColumnIndex:14];
		const int reachability = [row intForColumnIndex:15];

		// Should we preppend a text header with the column names?
		if (add_header) {
			[csv_strings addObject:@"type,text,longitude,latitude,longitude,"
				@"latitude,h_accuracy,v_accuracy,altitude,timestamp,"
				@"in_background,requested_accuracy,speed,direction,"
				@"battery_level, external_power, reachability"];

			if (gpx_strings) {
				[gpx_strings addObject:@"<?xml version=\"1.0\" encoding=\"UTF-"
					@"8\" standalone=\"no\" ?>\n<gpx xmlns=\"http://www."
					@"topografix.com/GPX/1/1\">\n\t<metadata><link href=\""
					@"https://github.com/gradha/Record-my-position/\">\n\t"
					@"<text>Record-my-position</text></link>"];
				[gpx_strings addObject:[NSString stringWithFormat:@"\t<time>%@"
					@"</time></metadata>\n<trk><name>%@</name><trkseg>",
					gpx_timestamp(timestamp), gpx_timestamp(timestamp)]];
			}
			add_header = NO;
		}

		if (DB_ROW_TYPE_LOG == type) {
			[csv_strings addObject:
				[NSString stringWithFormat:@"%d,%@,0,0,0,0,-1,-1,-1,%d,"
				@"%d,%d,-1.0,-1.0,%0.2f,%d,%d",
				type, [row stringForColumnIndex:2], timestamp,
				in_background, requested_accuracy, battery_level,
				external_power, reachability]];
		} else if (DB_ROW_TYPE_COORD == type || DB_ROW_TYPE_NOTE == type) {
			NSString *text = NON_NIL_STRING([row stringForColumnIndex:2]);
			const double longitude = [row doubleForColumnIndex:3];
			const double latitude = [row doubleForColumnIndex:4];
			const double h_accuracy = [row doubleForColumnIndex:5];
			const double v_accuracy = [row doubleForColumnIndex:6];
			const double altitude = [row doubleForColumnIndex:7];
			[csv_strings addObject:[NSString stringWithFormat:@"%d,%@,"
				@"%0.8f,%0.8f,%@,%@,%0.1f,%0.1f,%0.1f,%d,"
				@"%d,%d,%0.2f,%0.2f,%0.2f,%d,%d", type, text,
				longitude, latitude, [GPS degrees_to_dms:longitude latitude:NO],
				[GPS degrees_to_dms:latitude latitude:YES],
				h_accuracy, v_accuracy, altitude, timestamp,
				in_background, requested_accuracy, speed, direction,
				battery_level, external_power, reachability]];

			if (gpx_strings) {
				NSString *elevation = (!altitude) ? @"" :
					[NSString stringWithFormat:@"<ele>%0.2f</ele>", altitude];
				NSString *hdop = (h_accuracy < 0) ? @"" : [NSString
					stringWithFormat:@"<hdop>%0.2f</hdop>", h_accuracy];
				NSString *vdop = (v_accuracy < 0) ? @"" : [NSString
					stringWithFormat:@"<vdop>%0.2f</vdop>", v_accuracy];
				NSString *course = (direction < 0 || direction > 360) ? @"" :
					[NSString stringWithFormat:@"<course>%0.2f</course>",
					direction];
				NSString *speed_tag = (speed < 0) ? @"" : [NSString
					stringWithFormat:@"<speed>%0.3f</speed>", speed];
				[gpx_strings addObject:[NSString stringWithFormat:@"<trkpt "
					@"lat=\"%0.8f\" lon=\"%0.8f\">%@<time>%@</time>"
					@"%@%@%@%@</trkpt>", latitude, longitude, elevation,
					gpx_timestamp(timestamp), hdop, vdop, course, speed_tag]];
			}
		} else {
			NSAssert(0, @"Unknown database row type?!");
			return ret;
		}
	}

	if (gpx_strings)
		[gpx_strings addObject:@"</trkseg></trk></gpx>"];

	NSString *csv_string = [[csv_strings componentsJoinedByString:@"\n"] retain];
	NSString *gpx_string = !make_gpx ? nil :
		[[gpx_strings componentsJoinedByString:@"\n"] retain];

	[pool drain];
	[ret autorelease];

	if (csv_string) {
		if (csv_string.length > 1) {
			NSData *csv = [csv_string dataUsingEncoding:NSUTF8StringEncoding];
			NSAssert(csv.length >= csv_string.length, @"Bad data conversion?");
			Attachment *wrapper = [Attachment new];
			wrapper.data = csv;
			wrapper.extension = @"csv";
			wrapper.mime_type = @"text/csv";
			[ret addObject:wrapper];
			[wrapper release];
		}
		[csv_string release];
	}

	if (gpx_string) {
		if (gpx_string.length > 1) {
			NSData *gpx = [gpx_string dataUsingEncoding:NSUTF8StringEncoding];
			NSAssert(gpx.length >= gpx_string.length, @"Bad data conversion?");
			Attachment *wrapper = [Attachment new];
			wrapper.data = gpx;
			wrapper.extension = @"gpx";
			wrapper.mime_type = @"text/xml";
			[ret addObject:wrapper];
			[wrapper release];
		}
		[gpx_string release];
	}

	if (ret.count < 1) {
		return ret;
	} else {
		/* Signal remaining rows? */
		if (last_id >= 0 && last_id != max_row_) {
			max_row_ = last_id;
			remaining_ = YES;
		}

		return ret;
	}
}

/** Deletes the rows returned by get_attachments.
 * Note that if you call this before get_attachments: the whole
 * database will be wiped out, since get_attachments: might have limited
 * the maximum row to _MAX_EXPORT_ROWS.
 */
- (void)delete_rows
{
	EGODatabaseResult *result = [db_ executeQueryWithParameters:@"DELETE "
		@"FROM Positions WHERE id <= ?",
		[NSNumber numberWithInt:max_row_], nil];
	LOG_ERROR(result, nil, NO);
}

/** Returns YES if there were remaining rows not returned by get_attachments.
 */
- (bool)remaining
{
	return remaining_;
}

@end

/** Returns an autoreleased string with the gpx timestamp of the parameter.
 */
NSString *gpx_timestamp(const time_t timestamp)
{
	DLOG(@"Calling by %ld", timestamp);
	struct tm *t = gmtime(&timestamp);
	if (!t)
		return @"Timestamp memory error";
	else
		return [NSString stringWithFormat:@"%04d-%02d-%02dT%02d:%02d:%02dZ",
			1900 + t->tm_year, t->tm_mon, t->tm_mday, t->tm_hour, t->tm_min,
			t->tm_sec];
}

// vim:tabstop=4 shiftwidth=4 syntax=objc
