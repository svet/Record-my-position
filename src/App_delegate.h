// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>

@class DB;
@class Tab_controller;

/** Application delegate
 *
 * Used to instantiate the main window view, create the tabs and
 * handle going back and forth between foreground/background modes.
 */
@interface App_delegate : NSObject <UIApplicationDelegate>
{
	/// Main window of the application.
	UIWindow *window_;

	/// Controlls the interface of the tabs.
	Tab_controller *tab_controller_;

	/// Pointer to the global database access object.
	DB *db_;

	/// Set this to YES if you want the pop up error to exit.
	BOOL abort_after_alert_;
}

/// Pointer to the global database access object.
@property (nonatomic, readonly) DB *db;


- (void)handle_error:(NSString*)message abort:(BOOL)abort;
- (void)purge_database;

@end

/// \file FlokiAppDelegate.h
/// Type of directory where we want to open a file.
enum DIR_TYPE_ENUM
{
	DIR_BUNDLE,		///< Open the program's bundle for data reading.
	DIR_DOCS,		///< Directory where persistent data is stored.
};
/// Required alias for enum.
typedef enum DIR_TYPE_ENUM DIR_TYPE;

NSString *get_path(NSString *filename, DIR_TYPE dir_type);
