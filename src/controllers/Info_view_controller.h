/** Shows an HTML to the user.
 *
 * Nothing fancy, the file comes from the bundle's resources.
 */
@interface Info_view_controller : UITableViewController
{
	/// Optional title for subcontroller, if not set will use a default string.
	NSString *title_;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSArray *items;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
