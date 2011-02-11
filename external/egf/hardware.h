/**
 * \file hardware.h
 * \brief Functions to query the underlying hardware.
 * TODO: Add flag about bluetooth networking availability:
 * http://iphonedevelopment.blogspot.com/2009/10/device-detection-redux.html
 */

#ifndef __EGF_HARDWARE_H__
#define __EGF_HARDWARE_H__


typedef enum HW_FAMILY_ENUM HW_FAMILY;
typedef struct Hardware_info_t Hardware_info;


#define UDID_LEN			40

/// Family of the hardware device you might be using.
enum HW_FAMILY_ENUM
{
	HW_UNKNOWN = 0,
	HW_SIMULATOR,
	HW_IPHONE,
	HW_IPOD,
	HW_IPAD,
};


/** Information about the device you are running on.
 * The version attribute is negative for unknown hardware. Otherwise it is set
 * to 0 and successive versions depending on the detected hardware version.
 *
 * Currently known versions for iPhone family:
 * - 0: iPhone 1G
 * - 1: iPhone 3G
 * - 2: iPhone 3GS
 *
 * Currently known versions for iPod family:
 * - 0: iPod touch 1G
 * - 1: iPod touch 3G
 *
 * Currently known versions for iPad family:
 * - 0: iPad
 */
struct Hardware_info_t
{
	HW_FAMILY family;			// Hardware family.
	char version;				// Zero or positive means recognised version.
	char *name;					// Hardware name as C string.
	char udid[UDID_LEN + 1];	// UDID plus NULL terminator.
};


Hardware_info *get_hardware_info(void);
void destroy_hardware_info(Hardware_info **info);


#endif // __EGF_HARDWARE_H__

// vim:tabstop=4 shiftwidth=4 syntax=objc
