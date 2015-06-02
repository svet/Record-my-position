import Foundation
import CoreLocation


enum Accuracy
{
    case High, Medium, Low
}

@objc class SGPS : NSObject, CLLocationManagerDelegate
{
    private let _GPS_IS_ON_KEY = "gps_is_on"
    private let _KEY_SAVE_SINGLE_POSITION = "save_single_positions"

    static private let cInstance: SGPS = SGPS()

    private var mSaveAllPositions = false
    private var mGpsIsOn = false
    private var mManager: CLLocationManager
    private var mAccuracy: Accuracy
    private var mNoLog = false

    static func get() -> SGPS
    {
        return cInstance
    }

    override init()
    {
        println("Initializing SGPS")
        mManager = CLLocationManager()
        //assert(nil !== mManager) TODO: Why does the check fail?
        mAccuracy = .High
        super.init()

        // Set no filter and try to get the best accuracy possible.
        mManager.distanceFilter = kCLDistanceFilterNone
        mManager.desiredAccuracy = kCLLocationAccuracyBest
        mManager.delegate = self

        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.boolForKey(_GPS_IS_ON_KEY) {
            start()
        }
        mSaveAllPositions = defaults.boolForKey(_KEY_SAVE_SINGLE_POSITION)
    }

    deinit {
        stop()
        //mManager = nil
    }

    var saveAllPositions: Bool {
        get { return mSaveAllPositions }
        set {
            mSaveAllPositions = newValue
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(newValue, forKey:_KEY_SAVE_SINGLE_POSITION)
            defaults.synchronize()
        }
    }

    var gpsIsOn: Bool {
        get { return mGpsIsOn }
        set {
            mGpsIsOn = newValue
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(newValue, forKey:_GPS_IS_ON_KEY)
            defaults.synchronize()
        }
    }

    func stop()
    {
        println("Stopping, not implemented!")
    }

    func pingWatchdog()
    {
        println("Pinging watchdog, not implemented!");
    }

    /** Converts a coordinate from degrees to decimal minute second format.
     * Specify with the latitude bool if you are converting the latitude
     * part of the coordinates, which has a different letter.
     *
     * \return Returns the string with the formated value as
     * Ddeg Mmin Ssec X, where X is a letter.
     */
    static func degreesToDms(value: CLLocationDegrees, latitude: Bool) -> String
    {
        let degrees = Int(fabs(value))
        let min_rest = (fabs(value) - Double(degrees)) * 60.0;
        let minutes = Int(min_rest);
        let seconds = (min_rest - Double(minutes)) * 60.0;
        var letter = ""
        if latitude {
            if value >= 0 {
                letter = "N"
            } else {
                letter = "S"
            }
        } else {
            if value >= 0 {
                letter = "E"
            } else {
                letter = "W"
            }
        }

        return String(format: "%ddeg %dmin %0.2fsec %@",
            degrees, minutes, seconds, letter)
    }

    /** Starts the GPS tracking.
     * Returns false if the location services are not available.
     */
    func start() -> Bool
    {
        if CLLocationManager.locationServicesEnabled() {
            if (!mGpsIsOn && !mNoLog) {
                DB.get().log("Starting to update location")
            }

            pingWatchdog()

            mManager.startUpdatingLocation()
            gpsIsOn = true
    		return true
    	} else {
            gpsIsOn = false
            return false
    	}
    }
}
