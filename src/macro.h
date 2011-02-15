#ifndef __MACRO_H__
#define __MACRO_H__

/// Returns the value var restrained to inclusive lower and higher limits.
#define MID(low,var,high)  (MIN(MAX(low, var), high))

/// Useful macro to get the number of elements in any array type.
#define DIM(x)	(sizeof((x)) / sizeof((x)[0]))

/// Log only if the symbol DEBUG is defined.
#ifdef DEBUG
#define DLOG(X, ...)		NSLog(X, ##__VA_ARGS__)
#import "VTPG_Common.h"
#else
#define DLOG(X, ...)		do {} while(0)
#define LOG_EXPR(X)			do {} while(0)
#endif // DEBUG

/// Log always, avoid stupid CamelCase.
#define LOG(X, ...)			NSLog(X, ##__VA_ARGS__)

/// Verifies if the mask value VAL is set in the variable.
#define IS_BIT(VAR,VAL)		((VAR) & (VAL))

/// Sets the mask value VAL to the variable.
#define SET_BIT(VAR,VAL)	((VAR) |= (VAL))

/// Clears the bits in mask value VAL of the variable.
#define DEL_BIT(VAR,VAL)	((VAR) &= ~(VAL))

/// Returns the emtpy string if the parameter is nil.
#define NON_NIL_STRING(VAR)	((nil == VAR) ? @"": VAR)

/// Experimenting with new runtime assert macro.
#ifdef DEBUG
#define RASSERT(COND,TEXT,EXPR)											\
	NSAssert(COND, TEXT)
#else
#define RASSERT(COND,TEXT,EXPR)											\
	if (!(COND)) {														\
		LOG(@"Runtime assertion %s, %@\nat %s:%s:%d", #COND, TEXT,		\
			__PRETTY_FUNCTION__, __FILE__, __LINE__);					\
		do {															\
			EXPR;														\
		} while (0);													\
	}
#endif

#define ASK_GETTER(OBJECT, GETTER, DEF)								\
	((![OBJECT respondsToSelector:@selector(GETTER)]) ? (DEF) :		\
		([OBJECT performSelector:@selector(GETTER)]))

#define IS_IPAD		(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

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
