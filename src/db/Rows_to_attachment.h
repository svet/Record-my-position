@class DB;
@class Rows_to_attachment;

/** Temporary holder for SQLite to attachment interface.
 * The holder will remember how many rows are being prepared so
 * that other GPS events can be registered in the background and not
 * be deleted if the user wants to purge the sent attachments in the
 * end.
 */
@interface Rows_to_attachment : NSObject
{
	/// Stores the top row to fetch.
	int max_row_;

	/// Pointer to database.
	DB* db_;

	BOOL remaining_;
}

- (id)initWithDB:(DB*)db max_row:(int)max_row;
- (void)delete_rows;
- (NSData*)get_attachment;
- (bool)remaining;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
