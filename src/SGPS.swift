import Foundation

class SGPS
{
    static let cInstance: SGPS = SGPS()

    get { return cInstance; }
    init()
    {
        let defaults = NSUserDefaults.standardUserDefaults
        let gpsIsOn = defaults.boolForKey(_GPS_IS_ON_KEY);

    }
}
//		const BOOL gps_is_on = [defaults boolForKey:_GPS_IS_ON_KEY];
//		if (gps_is_on)
//			[g_ start];
//
//		g_->save_all_positions_ =
//			![defaults boolForKey:_KEY_SAVE_SINGLE_POSITION];