// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import <UIKit/UIKit.h>

@interface Share_tab : UIViewController
{
	UILabel *counter_;

	int num_entries_;
}

@property (nonatomic, assign) int num_entries;

- (id)init;

@end
