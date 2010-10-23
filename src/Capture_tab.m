// vim:tabstop=4 shiftwidth=4 encoding=utf-8 syntax=objc

#import "Capture_tab.h"

#import "GPS.h"
#import "macro.h"


#define _KEY_PATH			@"last_pos"


@interface Capture_tab ()
- (void)switch_changed;
- (void)update_gui;
@end


@implementation Capture_tab

@synthesize old_location = old_location_;

- (id)init
{
	if (!(self = [super init]))
		return nil;

	self.title = @"Capture";
	return self;
}

- (void)dealloc
{
	[timer_ invalidate];
	[[GPS get] removeObserver:self forKeyPath:_KEY_PATH];
	[switch_ removeTarget:self action:@selector(switch_changed)
		forControlEvents:UIControlEventValueChanged];
	[clock_ release];
	[ago_ release];
	[movement_ release];
	[switch_ release];
	[altitude_ release];
	[precission_ release];
	[latitude_ release];
	[longitude_ release];
	[start_title_ release];
	[old_location_ release];
	[super dealloc];
}

- (void)loadView
{
	[super loadView];

	start_title_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 210, 20)];
	start_title_.text = @"1";
	start_title_.backgroundColor = [UIColor clearColor];
	start_title_.textColor = [UIColor blackColor];
	[self.view addSubview:start_title_];

	switch_ = [[UISwitch alloc] initWithFrame:CGRectMake(220, 20, 100, 20)];
	[switch_ addTarget:self action:@selector(switch_changed)
		forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:switch_];

	longitude_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 90, 300, 20)];
	longitude_.text = @"2";
	longitude_.backgroundColor = [UIColor clearColor];
	longitude_.textColor = [UIColor blackColor];
	[self.view addSubview:longitude_];

	latitude_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 110, 300, 20)];
	latitude_.text = @"3";
	latitude_.backgroundColor = [UIColor clearColor];
	latitude_.textColor = [UIColor blackColor];
	[self.view addSubview:latitude_];

	precission_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, 300, 20)];
	precission_.text = @"4";
	precission_.backgroundColor = [UIColor clearColor];
	precission_.textColor = [UIColor blackColor];
	[self.view addSubview:precission_];

	altitude_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 150, 300, 20)];
	altitude_.text = @"5";
	altitude_.backgroundColor = [UIColor clearColor];
	altitude_.textColor = [UIColor blackColor];
	[self.view addSubview:altitude_];

	ago_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 170, 300, 20)];
	ago_.text = @"6";
	ago_.backgroundColor = [UIColor clearColor];
	ago_.textColor = [UIColor blackColor];
	[self.view addSubview:ago_];

	movement_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 190, 300, 20)];
	movement_.text = @"7";
	movement_.backgroundColor = [UIColor clearColor];
	movement_.textColor = [UIColor blackColor];
	[self.view addSubview:movement_];

	clock_ = [[UILabel alloc] initWithFrame:CGRectMake(10, 300, 300, 100)];
	clock_.text = @"00:00:00";
	clock_.numberOfLines = 1;
	clock_.backgroundColor = [UIColor clearColor];
	clock_.textColor = [UIColor blackColor];
	clock_.textAlignment = UITextAlignmentCenter;
	clock_.adjustsFontSizeToFitWidth = YES;
	clock_.font = [UIFont systemFontOfSize:80];
	[self.view addSubview:clock_];
}

/** The view is going to be shown. Update it.
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self update_gui];

	if (!timer_)
		timer_ = [NSTimer scheduledTimerWithTimeInterval:1 target:self
			selector:@selector(update_gui) userInfo:nil repeats:YES];
}

/** The view is going to dissappear.
 */
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	[timer_ invalidate];
	timer_ = 0;
}

/** User toggled on/off GUI switch.
 */
- (void)switch_changed
{
	GPS *gps = [GPS get];

	if ([switch_ isOn]) {
		if (![gps start]) {
			switch_.on = false;

			UIAlertView *alert = [[UIAlertView alloc]
				initWithTitle:@"GPS" message:@"Couldn't start GPS"
				delegate:nil cancelButtonTitle:@"Oh!" otherButtonTitles:nil];
			[alert show];
			[alert release];
		} else {
			[gps addObserver:self forKeyPath:_KEY_PATH
				options:NSKeyValueObservingOptionNew context:nil];
		}
	} else {
		[gps removeObserver:self forKeyPath:_KEY_PATH];
		[gps stop];
	}

	[self update_gui];
}

/** Handles updating the gui labels and other state.
 */
- (void)update_gui
{
	// Clock time.
	NSDate *now = [NSDate date];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterMediumStyle];
	clock_.text = [formatter stringFromDate:now];
	[formatter release];

	// State of capture.
	if (switch_.on)
		start_title_.text = @"Reading GPS...";
	else
		start_title_.text = @"GPS off";

	// Last location.
	CLLocation *location = [GPS get].last_pos;
	if (!location) {
		longitude_.text = @"No last position";
		latitude_.text = @"";
		precission_.text = @"";
		altitude_.text = @"";
		ago_.text = @"";
		movement_.text = @"";
		return;
	}

	longitude_.text = [NSString stringWithFormat:@"Longitude: %@",
		[GPS degrees_to_dms:location.coordinate.longitude latitude:NO]];

	latitude_.text = [NSString stringWithFormat:@"Latitude: %@",
		[GPS degrees_to_dms:location.coordinate.latitude latitude:YES]];

	const CLLocationAccuracy v = (location.horizontalAccuracy +
		location.horizontalAccuracy) / 2.0;
	precission_.text = [NSString stringWithFormat:@"Precission: %0.0fm", v];

	altitude_.text = (location.verticalAccuracy < 0) ? @"Altitude: ?" :
		[NSString stringWithFormat:@"Altitude: %0.0fm +/- %0.1fm",
			location.altitude, location.verticalAccuracy];

	NSTimeInterval diff = [now timeIntervalSinceDate:location.timestamp];
	ago_.text = [NSString stringWithFormat:@"%@ ago", (diff > 60 ? 
		[NSString stringWithFormat:@"%d minute(s)", (int)diff / 60] :
		[NSString stringWithFormat:@"%d second(s)", (int)diff])];

	if (self.old_location) {
		movement_.text = [NSString
			stringWithFormat:@"New pos changed %0.0f meters",
			[self.old_location distanceFromLocation:location]];
		if (![self.old_location.timestamp isEqualToDate:location.timestamp])
			self.old_location = location;
	} else {
		movement_.text = @"First position!";
		self.old_location = location;
	}
}

/** Watches GPS changes.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:_KEY_PATH])
		[self update_gui];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change
			context:context];
}

@end
