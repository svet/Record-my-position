======================================
Record my position: Internal db schema
======================================

.. vim:tabstop=4 shiftwidth=4 encoding=utf-8 noexpandtab

:author: Grzegorz Adam Hankiewicz <gradha@titanium.sabren.com>

.. contents::

.. section-numbering::

.. raw:: pdf

   PageBreak oneColumn

General
=======

Information on the sqlite database file format for the Record-my-position
app (https://github.com/gradha/Record-my-position).

There is a single table to record events, but depending on the type
of the row it may contain a coordinate event or a log event.
Coordinate events are triggered by the hardware. Log events indicate
important app status changes and they may help to define why the
log may have less entries (eg. the application entered into the
background and the GPS accuracy was reduced to save battery).


Log table
---------

**id** INTEGER PRIMARY KEY AUTOINCREMENT:
	Identifier of the log entry in the database. This identifier
	is unique and always autoincrementing.
**type** INTEGER:
	Identifier of the event type. Available events are:

	 * 0: Text log entry.
	 * 1: Hardware GPS event.
	 * 2: Note (hybrid of log with location)
**text** TEXT NULL:
	Optional text field entry. Usually not null when the type
	of event is a log entry. Otherwise not used.
**longitude** REAL:
	Stores the longitude of a geodetic coordinate in decimal format.
**latitude** REAL:
	Stores the latitude of a geodetic coordinate in decimal format.
**h_accuracy** REAL:
	Stores the horizontal accuracy of the reading in meters.
**v_accuracy** REAL:
	Stores the vertical accuracy of the reading in meters.
**altitude** REAL:
	Stores the altitude of the reading in meters. Usually
	negative if not available.
**timestamp** INTEGER:
	Timestamp of the reading, stored in UTC time.
**in_background** BOOL:
	Set to true if the log entry was generated while the
	application was in background. Pre 4.x firmware devices
	didn't support background running, so they will always have
	this column set to false.
**requested_accuracy** INTEGER:
	Identifier of the requested accuracy setting when the event
	was generated. Available values are:

	 * 0: High accuracy, application in foreground.
	 * 1: Medium accuracy, applicaiton in foreground but lost focus.
	 * 2: Low accuracy, application in background.
**speed** REAL:
	This value reflects the instantaneous speed of the device
	in the direction of its current heading. A negative value
	indicates an invalid speed. Because the actual speed can
	change many times between the delivery of subsequent location
	events, you should use this property for informational
	purposes only.
**direction** REAL:
	Course values are measured in degrees starting at due north
	and continuing clockwise around the compass. Thus, north
	is 0 degrees, east is 90 degrees, south is 180 degrees, and
	so on. Course values may not be available on all devices.
	A negative value indicates that the direction is invalid.
**battery_level** REAL:
	Current battery level with precission of 5% over whole
	battery level as a normalized value going from 0 to 1.
**external_power** INTEGER:
	If the value is zero, it means that the device is not plugged
	in into external power sources or it doesn't really know.
	If the value is positive, it means that the device is
	charging or at full power and still connected to a power
	source.
**reachability** INTEGER:
	If the value is negative, the reachability status is unknown
	or not supported. If the value is zero, the external online
	site is not available. If the value is positive, the
	configured external online site is available through a
	network connection.
