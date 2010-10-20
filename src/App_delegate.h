// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>

@class DB;
@class Tab_controller;

@interface App_delegate : NSObject <UIApplicationDelegate>
{
	/// Main window of the application.
	UIWindow *window_;

	/// Controlls the interface of the tabs.
	Tab_controller *tab_controller_;

	/// Pointer to the global database access object.
	DB *db_;
}

/// Pointer to the global database access object.
@property (nonatomic, readonly) DB *db;

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
