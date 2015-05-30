import Foundation

public class Test
{
    init(a: String) {
        println("Hello \(a)")
    }
}

@objc public class SGPS
{
    private let _GPS_IS_ON_KEY = "gps_is_on"
    private let _KEY_SAVE_SINGLE_POSITION = "save_single_positions"

    static private let cInstance: SGPS = SGPS();
    static private var cSaveAllPositions: Bool = false

    static func get() -> SGPS {
        return cInstance
    }

    public init()
    {
        let defaults = NSUserDefaults.standardUserDefaults()

        if defaults.boolForKey(_GPS_IS_ON_KEY) {
            start();
        }
        SGPS.cSaveAllPositions = defaults.boolForKey(_KEY_SAVE_SINGLE_POSITION);
    }

    public func start()
    {
        println("Starting!");
    }
}
