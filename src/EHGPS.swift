import Foundation
import CoreLocation
import UIKit


@objc internal enum Accuracy: Int
{
    case High, Medium, Low
}

@objc class EHGPS : NSObject, CLLocationManagerDelegate
{
    private let _GPS_IS_ON_KEY = "gps_is_on"
    private let _KEY_SAVE_SINGLE_POSITION = "save_single_positions"
    private let _WATCHDOG_SECONDS = 60 * 60.0
    static internal let KEY_PATH = "lastPos"
    static private var cDB: DB?

    static private let cInstance: EHGPS = EHGPS()

    private var mSaveAllPositions = false
    private var mGpsIsOn = false
    private var mManager: CLLocationManager
    private var mNoLog = false
    private var mZasca: NSTimer?
    internal var mAccuracy: Accuracy
    internal var lastPos: CLLocation?

    static func get() -> EHGPS
    {
        return cInstance
    }

    /** Constructor for the class.
     * The constructor avoids side effects moving some code to postInit()
     * which you need to call.
     */
    override init()
    {
        DLOG("Initializing EHGPS")
        mManager = CLLocationManager()
        mAccuracy = .High
        super.init()

        // Set no filter and try to get the best accuracy possible.
        mManager.distanceFilter = kCLDistanceFilterNone
        mManager.desiredAccuracy = kCLLocationAccuracyBest
        mManager.delegate = self
    }

    /** Finishes the initialization.
     * Call this with the DB dependency to inject.
     */
    func postInit(db: DB)
    {
        EHGPS.cDB = db
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
            assert(nil != EHGPS.cDB)
            if (!gpsIsOn && !mNoLog) {
                EHGPS.cDB!.log("Starting to update location")
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
    /** Stops the GPS tracking.
     * You can call this function anytime, doesn't really fail.
     */
    func stop() {
        if gpsIsOn && !mNoLog {
            assert(nil != EHGPS.cDB)
            EHGPS.cDB!.log("Stopping location updates");
        }
        stopWatchdog()
        gpsIsOn = false
        mManager.stopUpdatingLocation()
    }

    /** Registers an observer for changes to last_pos.
     * Observers will monitor the key_path value.
     */
    func addWatcher(watcher: NSObject) {
        addObserver(watcher, forKeyPath:EHGPS.KEY_PATH,
            options: .New, context: nil)
    }

    /** Removes an observer for changes to last_pos.
     */
    func removeWatcher(watcher: NSObject) {
        removeObserver(watcher, forKeyPath: EHGPS.KEY_PATH)
    }

    /** Changes the desired accuracy of the GPS readings.
     * If the GPS is on, it will be reset just in case. Provide a reason
     * for the change or nil if you don't want to log the change.
     */
    func setAccuracy(accuracy: Accuracy, reason: String?)
    {
        if accuracy == mAccuracy {
            return
        }

        mAccuracy = accuracy
        let message = "Setting accuracy to \(accuracy)";

        switch accuracy {
        case .High:
            mManager.distanceFilter = kCLDistanceFilterNone
            mManager.desiredAccuracy = kCLLocationAccuracyBest

        case .Medium:
            mManager.distanceFilter = 50
            mManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        case .Low:
            mManager.distanceFilter = 150
            mManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        if gpsIsOn {
            assert(nil != EHGPS.cDB)
            if let reason = reason {
                EHGPS.cDB!.log(String(format: "%@ Reason: %@", message, reason))
            } else {
                EHGPS.cDB!.log(message)
            }

            mNoLog = true
            stop()
            start()
            mNoLog = false
        }
    }

    /** Something bad happened retrieving the location. What?
     * We ignore location errors only. Rest are logged.
     */
    func locationManager(manager: CLLocationManager!,
        didFailWithError error: NSError!)
    {
        if CLError.LocationUnknown == CLError(rawValue: error.code) {
            return
        }

        assert(nil != EHGPS.cDB)
        EHGPS.cDB!.log("location error: " + error.localizedDescription)
    }

    /** Receives a location update.
     * This generates the correct KVO messages to notify observers.
     * Also resets the watchdog. Repeated locations based on timestamp
     * will be discarded.
     */
    func locationManager(manager: CLLocationManager!,
        didUpdateLocations locations: [AnyObject]!)
    {
        let newLocation = locations.last as! CLLocation
        if newLocation.horizontalAccuracy < 0 {
            DLOG("Bad returned accuracy, ignoring update.")
            return
        }

        if let pos = lastPos
            where pos.timestamp.isEqualToDate(newLocation.timestamp) {

            DLOG("Discarding repeated location \(newLocation.description)")
            return
        }

        DLOG("Updating to \(newLocation.description)")
        // TODO: Do we need here the Objc KVO dance?
        lastPos = newLocation

        pingWatchdog()
    }

    /** Starts or refreshes the timer used for the GPS watchdog.
     * Sometimes if you loose network signal the GPS will stop updating
     * values even though the hardware may well be getting them. The
     * watchdog will set a time and force a stop/start if there were no
     * recent updates received.
     *
     * You have to call this function every time you start to watch
     * updates and every time you receive one, so the watchdog timer is
     * reset.
     *
     * Miss Merge: I'm walking on sunshine, woo hoo!
     */
    func pingWatchdog()
    {
        if let timer = mZasca {
            timer.invalidate()
        }

        mZasca = NSTimer.scheduledTimerWithTimeInterval(_WATCHDOG_SECONDS,
            target: self, selector: Selector("zasca"),
            userInfo: nil, repeats: false)
    }

    /** Stops the watchdog, if it is on. Otherwise does nothing.
     */
    func stopWatchdog()
    {
        if let timer = mZasca {
            timer.invalidate()
        }

        mZasca = nil
    }

    /** Handles the stop/start of the GPS.
     * Note that the stop/start will automatically reschedule the watchdog.
     */
    func zasca()
    {
        assert(nil != EHGPS.cDB)
        EHGPS.cDB!.log("Watchdog timer kicking in due to inactivity.")
        mNoLog = true
        stop()
        start()
        mNoLog = false
    }
}

// TODO: Figure how to make this conditional on compilation.
func DLOG(text: String) { NSLog("%@", text) }