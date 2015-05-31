import Foundation
import CoreLocation


enum Accuracy
{
    case High, Medium, Low
}

@objc public class SGPS : NSObject, CLLocationManagerDelegate
{
    private let _GPS_IS_ON_KEY = "gps_is_on"
    private let _KEY_SAVE_SINGLE_POSITION = "save_single_positions"

    static private let cInstance: SGPS = SGPS();
    private var mSaveAllPositions: Bool {
        get { return self.mSaveAllPositions }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(newValue, forKey:_KEY_SAVE_SINGLE_POSITION)
            defaults.synchronize()
        }
    }

    private var mManager: CLLocationManager
    private var mAccuracy: Accuracy

    static func get() -> SGPS
    {
        return cInstance
    }

    override public init()
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

    public var mGpsIsOn: Bool {
        get {
            return self.mGpsIsOn
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(newValue, forKey:_GPS_IS_ON_KEY)
            defaults.synchronize()
        }
    }

    public func start()
    {
        println("Starting!")
    }

    public func stop()
    {
        println("Stopping")
    }
}
