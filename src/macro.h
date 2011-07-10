#ifndef __MACRO_H__
#define __MACRO_H__

#import "ELHASO.h"

#define _MAKE_DEFAULT_LABEL_COLOR(LABEL) do { \
	LABEL.textColor = [UIColor whiteColor]; \
	LABEL.backgroundColor = [UIColor clearColor]; \
	LABEL.shadowColor = [UIColor blackColor]; \
	LABEL.shadowOffset = CGSizeMake(2, 1); \
} while(0)

#define _MAKE_BUTTON_LABEL_COLOR(LABEL) do { \
	LABEL.textColor = [UIColor darkTextColor]; \
	LABEL.backgroundColor = [UIColor clearColor]; \
	LABEL.shadowColor = [UIColor lightGrayColor]; \
	LABEL.shadowOffset = CGSizeMake(0, 1); \
} while(0)

#endif // __MACRO_H__

// vim:tabstop=4 shiftwidth=4 syntax=objc
