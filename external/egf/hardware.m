// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#include "egf/hardware.h"

#include "macro.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysctl.h>
#include <sys/types.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSString.h>
#import <UIKit/UIDevice.h>


/** Returns a ::Hardware_info_t structure about the current hardware.
 * You can call this function any time anywhere in your code.
 *
 * \return Returns a ::Hardware_info_t which you must call
 * destroy_hardware_info() on, or NULL if there were problems.
 */
Hardware_info *get_hardware_info(void)
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	size_t size;
	sysctlbyname("hw.machine", 0, &size, 0, 0);
	Hardware_info *info = malloc(sizeof(Hardware_info));
	if (!info) {
		DLOG(@"Not enough memory to get_hardware_info().");
		goto exit;
	}
	info->name = calloc(1, size);
	if (!info->name) {
		DLOG(@"Not enough memory to get hardware name (%lu).", size);
		free(info);
		info = 0;
		goto exit;
	}

	info->udid[0] = 0;
	UIDevice *dev = [UIDevice currentDevice];
	NSString *udid = dev.uniqueIdentifier;
	if (udid) {
		if (UDID_LEN == strlen([udid cStringUsingEncoding:1])) {
			strncpy(info->udid, [udid cStringUsingEncoding:1], UDID_LEN);
			info->udid[UDID_LEN] = 0;
		} else {
			DLOG(@"Unexpected UDID length for '%@'.", udid);
		}
	} else {
		DLOG(@"Couldn't read UDID.");
	}

	sysctlbyname("hw.machine", info->name, &size, 0, 0);
	DLOG(@"Retrieved hardware string '%s'.", info->name);

#define RETURN(STR,FAMILY_ENUM,VER) do {									\
	if (!strcmp(info->name, STR)) {											\
		info->family = FAMILY_ENUM;											\
		info->version = VER;												\
		goto exit;															\
	}																		\
} while (0)

	// Parse information.
	RETURN("iPad1,1", HW_IPAD, 0);
	RETURN("iPhone1,1", HW_IPHONE, 0);
	RETURN("iPhone1,2", HW_IPHONE, 1);
	RETURN("iPhone2,1", HW_IPHONE, 1);
	RETURN("iPod1,1", HW_IPOD, 0);
	RETURN("iPod2,1", HW_IPOD, 1);
	RETURN("i386", HW_SIMULATOR, 0);

#undef RETURN

	// Failed, try to identify something else...
	info->version = -1;
	info->family = HW_UNKNOWN;

	if (!strncmp(info->name, "iPhone", 6)) {
		DLOG(@"Detected new iPhone model.");
		info->family = HW_IPHONE;
	} else if (!strncmp(info->name, "iPod", 4)) {
		DLOG(@"Detected new iPhone model.");
		info->family = HW_IPOD;
	} else if (!strncmp(info->name, "iPad", 4)) {
		DLOG(@"Detected new iPad model.");
		info->family = HW_IPAD;
	} else {
		DLOG(@"Unknown hardware!!!");
	}

exit:
	[pool release];
	return info;
}

/// Frees the memory returned by get_hardware_info().
void destroy_hardware_info(Hardware_info **info)
{
	assert(info);
	Hardware_info *i = *info;

	if (i) {
		free(i->name);
		free(i);
	}

	*info = 0;
}

