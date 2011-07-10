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


- (void)handle_error:(NSString*)message do_abort:(BOOL)do_abort;
- (void)purge_database;

@end

/// \file App_delegate.h

/// Read these variables to know what is supported on the device.
extern BOOL g_is_multitasking;
extern BOOL g_location_changes;
extern BOOL g_region_monitoring;

// vim:tabstop=4 shiftwidth=4 syntax=objc
