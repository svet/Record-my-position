#!/usr/bin/env python
# vim:tabstop=4 shiftwidth=4
"""Converts CSV files with expected geodetic data into nice KML files.
"""

from __future__ import with_statement

from contextlib import closing
from optparse import OptionParser

import StringIO
import csv
import logging
import os
import os.path
import sys
import time
import xml.etree.ElementTree as ET
import zipfile


ROW_LOG = 0
ROW_POSITION = 1
ROW_NOTE = 2
UNEXPECTED_LOG_TYPE = "unexpected?"
TIME_THRESHOLD = int(1 * 60 * 60)

LOG_TYPES = {
	ROW_LOG: "log entry",
	ROW_POSITION: "coordinate",
	ROW_NOTE: "note",
	}


class Track:
	"""Holds the information for a more or less related group of positions."""
	def __init__(self, positions):
		"""f([]) -> Track

		Constructs a Track object with the parameter as the positions attribute.
		"""
		self.positions = positions


def process_arguments():
	"""f() -> options, [string, ...]

	Parses the commandline arguments. The user only needs to
	specify csv files, which will be converted into kml ones.
	"""
	parser = OptionParser()
	parser.add_option("-Z", "--no-zip", dest="no_zip", action="store_true",
		help = "generate uncompressed KML files instead of KMZ.")
	parser.add_option("-g", "--gpx", dest="gpx", action="store_true",
		help = "generate basic GPX files too.")
	options, args = parser.parse_args()
	if len(args) < 1:
		logging.error("No input. Please specify *.csv files.")
		parser.print_help()
		sys.exit(1)

	# Check validity of input files.
	for filename in args:
		if not os.path.isfile(filename):
			logging.error("Invalid input %r.", filename)
			sys.exit(3)

	return options, args


def load_csv(filename):
	"""f(string) -> [{string: ?, ...}, ...]

	Loads a CSV file and returns a list of dictionaries, each
	representing one valid position.
	"""
	rows = []
	with open(filename, "rb") as input:
		reader = csv.reader(input)
		count = 0
		for row in reader:
			count += 1
			try:
				type, text = int(row[0]), row[1],
				longitude, latitude = float(row[2]), float(row[3])
				longitude_text, latitude_text = row[4], row[5]
				h_accuracy, v_accuracy = float(row[6]), float(row[7])
				altitude = float(row[8])
				timestamp = int(row[9])

				try:
					in_background = int(row[10])
					requested_accuracy = int(row[11])
					speed, direction = float(row[12]), float(row[13])
					battery_level = float(row[14])
				except IndexError:
					in_background = requested_accuracy = speed = direction = 0
					battery_level = 0

				try:
					external_power, reachability = int(row[15]), int(row[16])
				except IndexError:
					external_power, reachability = 0, -1

				rows.append((type, text, longitude, latitude, longitude_text,
					latitude_text, h_accuracy, v_accuracy, altitude, timestamp,
					in_background, requested_accuracy, speed, direction,
					battery_level, external_power, reachability))
			except ValueError:
				logging.warn("Ignoring line %d", count)

	return rows


def filter_csv_rows(rows):
	"""f([(), ...]) -> [Track, ...]

	Filters a loaded csv converting raw positions into individual track objects.

	Also performs other tasks, like generating coordinates for
	log messages based on interpolation.
	"""
	rows = rows[:]

	# Filter "backwards" positions according to the timestamps.
	to_remove = []
	for pos in range(1, len(rows)):
		now = rows[pos][9]
		prev = rows[pos - 1][9]

		if now < prev:
			logging.info("Removing backwards position item %d", pos + 1)
			to_remove.append(pos)

	while to_remove:
		del rows[to_remove.pop()]

	# Interpolate log positions based on time.
	for pos in range(len(rows)):
		type = rows[pos][0]
		if ROW_LOG != type:
			continue

		# Find previous and next coordinates.
		prev = pos - 1
		while prev >= 0:
			type = rows[prev][0]
			if ROW_POSITION == type or ROW_NOTE == type:
				break
			prev -= 1

		next = pos + 1
		while next < len(rows):
			type = rows[next][0]
			if ROW_POSITION == type or ROW_NOTE == type:
				break
			next += 1

		# Interpolate coordinate among found extremes, or copy from them.
		timestamp = rows[pos][9]
		if prev >= 0 and next < len(rows):
			coord = interpolate_position(rows, prev, next, timestamp)
		elif prev >= 0:
			coord = interpolate_position(rows, prev, prev, timestamp)
		elif next < len(rows):
			coord = interpolate_position(rows, next, next, timestamp)
		else:
			continue

		(type, text, lon, lat, lon_text, lat_text, h, v, altitude,
			timestamp, in_background, requested_accuracy, speed, direction,
			battery_level, external_power, reachability) = rows[pos]
		rows[pos] = (type, text, coord[0], coord[1],
			lon_text, lat_text, h, v, altitude, timestamp, in_background,
			requested_accuracy, speed, direction, battery_level,
			external_power, reachability)

	# Separate positions in tracks according to timestamps.
	tracks = []
	current = []
	for position_data in rows:
		# No entries? Add inconditionally.
		if len(current) < 1:
			current.append(position_data)
			continue

		now = position_data[9]
		prev = current[-1][9]
		if abs(now - prev) > TIME_THRESHOLD:
			tracks.append(Track(current))
			current = []

		current.append(position_data)

	if current:
		tracks.append(Track(current))

	return tracks


def interpolate_position(positions, pos1, pos2, timestamp):
	"""f([], int, int, int) -> (float, float)

	From a position set, and given two position indices, the
	function will take these two positions and inteprolate a
	new coordinate based on the timestamp that separates them.
	If the timestamp goes out of range, the nearest position
	is returned.
	"""
	x1, y1 = positions[pos1][2:4]
	x2, y2 = positions[pos2][2:4]
	t1, t2 = positions[pos1][9], positions[pos2][9]
	assert t1 <= t2, "Two coordinates with inverted timestamps? (%d, %d)" % (
		pos1, pos2)

	if timestamp <= t1:
		return x1, y1
	if timestamp >= t2:
		return x2, y2

	factor = float(timestamp - t1) / float(t2 - t1)
	return x1 + factor * (x2 - x1), y1 + factor * (y2 - y1)


def internal_time_to_gpx_timestamp(utc_timestamp):
	"""f(float) -> string

	Converts a time in UTC to a string for the gpx xml file format.
	"""
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % time.gmtime(utc_timestamp)[:6]


def convert_to_gpx(filename):
	"""f(string) -> None

	Converts the input csv file into a gpx file, replacing the extension.
	"""
	out_filename = "%s.gpx" % (os.path.splitext(filename)[0])
	logging.info("%r -> %r", filename, out_filename)
	tracks = filter_csv_rows(load_csv(filename))
	if len(tracks) < 1:
		logging.error("No data found in %r", filename)
		return



	output = StringIO.StringIO()
	output.write("""<?xml version="1.0" encoding="UTF-8" standalone="no" ?>

<gpx xmlns="http://www.topografix.com/GPX/1/1">
	<metadata><link href="https://github.com/gradha/Record-my-position/">
	<text>Record-my-position</text></link><time>%s</time></metadata>
""" % internal_time_to_gpx_timestamp(tracks[0].positions[0][9]))

	for track in tracks:
		generate_gpx_track(track, output)

	output.write("</gpx>")
	buf = output.getvalue()
	output.close()

	with open(out_filename, "wb") as output: output.write(buf)

	# Validate generated xml.
	ET.fromstring(buf)


def generate_gpx_track(track, output):
	"""f(Track, io-bbject) -> None

	Outputs valid KML xml for the track.
	"""
	times = [x[9] for x in track.positions]
	min_time, max_time = min(times), max(times)
	min_hour, min_min = time.localtime(min_time)[3:5]
	max_hour, max_min = time.localtime(max_time)[3:5]

	# Filter out log entries.
	positions = [x for x in track.positions if len(x[1]) < 1]

	output.write("""<trk><name>%02d:%02d-%02d:%02d, %s positions</name>
<trkseg>""" % (min_hour, min_min, max_hour, max_min, len(positions)))

	for f in range(len(positions)):
		(type, text, lon, lat, lon_text, lat_text, h, v, altitude,
			timestamp, in_background, requested_accuracy, speed, direction,
			battery_level, external_power, reachability) = positions[f]

		l = []
		l.append("""<trkpt lat="%f" lon="%f">""" % (lat, lon))
		if altitude:
			l.append("""<ele>%f</ele>\n""" % altitude)
		l.append("<time>%s</time>" % internal_time_to_gpx_timestamp(timestamp))
		if h >= 0:
			l.append("<hdop>%0.2f</hdop>" % h)
		if v >= 0:
			l.append("<vdop>%0.2f</vdop>" % v)
		if direction >= 0 and direction <= 360:
			l.append("<course>%0.2f</course>" % direction)
		if speed >= 0:
			l.append("<speed>%0.3f</speed>" % speed)

		l.append("</trkpt>\n")
		output.write("".join(l))

	output.write("""</trkseg></trk>""")



def convert_to_kml(filename, do_zip):
	"""f(string, bool) -> None

	Converts the input csv file into an KML file, replacing the extension.
	If the do_zip flag is set, a compressed KMZ file will be generated instead.
	"""
	if do_zip:
		out_filename = "%s.kmz" % (os.path.splitext(filename)[0])
	else:
		out_filename = "%s.kml" % (os.path.splitext(filename)[0])

	logging.info("%r -> %r", filename, out_filename)
	tracks = filter_csv_rows(load_csv(filename))
	if len(tracks) < 1:
		logging.error("No data found in %r", filename)
		return

	short_name = os.path.splitext(os.path.basename(filename))[0]

	output = StringIO.StringIO()
	output.write("""<?xml version='1.0' encoding='latin1'?>
<kml xmlns='http://earth.google.com/kml/2.2'>
<Document><name>%s</name><open>1</open>
 <description>Positions recorded with http://github.com/gradha/Record-my-position</description>
 <Style id='r1'><LineStyle><color>bb0000ff</color><width>5</width></LineStyle></Style>
 <Style id='r2'><LineStyle><color>bb5a5aff</color><width>5</width></LineStyle></Style>
 <Style id='r3'><LineStyle><color>bb688bff</color><width>5</width></LineStyle></Style>
 <Style id='r4'><LineStyle><color>bb3262ff</color><width>5</width></LineStyle></Style>
 <Style id='r5'><LineStyle><color>bb0076ff</color><width>5</width></LineStyle></Style>
 <Style id='b1'><LineStyle><color>bbff0000</color><width>5</width></LineStyle></Style>
 <Style id='g1'><LineStyle><color>bb00ff00</color><width>5</width></LineStyle></Style>
""" % (short_name))

	for track in tracks:
		generate_kml_track(track, output)

	output.write("</Document></kml>")
	buf = output.getvalue()
	output.close()

	if do_zip:
		z = zipfile.ZipFile(out_filename, "w", zipfile.ZIP_DEFLATED)
		z.writestr("doc.kml", buf)
		z.close()
	else:
		with open(out_filename, "wb") as output: output.write(buf)

	# Validate generated xml.
	ET.fromstring(buf)


def generate_kml_track(track, output):
	"""f(Track, io-bbject) -> None

	Outputs valid KML xml for the track.
	"""
	times = [x[9] for x in track.positions]
	min_time, max_time = min(times), max(times)
	min_hour, min_min = time.localtime(min_time)[3:5]
	max_hour, max_min = time.localtime(max_time)[3:5]

	output.write("""<Folder><name>%02d:%02d-%02d:%02d, %s positions</name>
<open>0</open>""" % (min_hour, min_min, max_hour, max_min,
		len(track.positions)))
	color = 1

	for f in range(len(track.positions)):
		(type, text, lon, lat, lon_text, lat_text, h, v, altitude,
			timestamp, in_background, requested_accuracy, speed, direction,
			battery_level, external_power, reachability) = track.positions[f]
		# Prepare extra names' title for points.
		extra_name = ""
		if len(text) < 1:
			text = ""
		else:
			extra_name = " log"

		# Find next coordinate.
		next_type, next_lon, next_lat = None, None, None
		if f + 1 < len(track.positions):
			next_type = track.positions[f + 1][0]
			next_lon, next_lat = track.positions[f + 1][2:4]

		hour, minute, second = time.localtime(timestamp)[3:6]

		# Use different color for log interpolated values.
		color_text = "r%d" % color
		if ROW_LOG == type and ROW_LOG == next_type:
			color_text = "b1"
		elif ROW_NOTE == type:
			color_text = "g1"

		output.write("""<Placemark><styleUrl>%s</styleUrl>
<name>%d %02d:%02d:%02d%s</name>\n""" % (color_text,
			f + 1, hour, minute, second, extra_name))

		write_kml_position_description(output, track.positions[f])

		output.write("<MultiGeometry>\n")
		# Draw the line segment only if there is a next endpoint.
		if next_lon and next_lat:
			output.write("<LineString><coordinates>%f,%f,0\n%f,%f,0"
				"</coordinates></LineString>\n""" % (lon, lat,
				next_lon, next_lat))

		output.write("<Point><coordinates>%f,%f,0</coordinates></Point>" % (
			lon, lat))
		output.write("</MultiGeometry></Placemark>")

		# Rotate color
		color = color + 1
		if color > 5:
			color = 1

	output.write("""</Folder>""")


def write_kml_position_description(output, position_data):
	"""f(file, (...)) -> None

	Pretty formats the position data into the file like object
	creating a kml description tag.
	"""
	(type, text, lon, lat, lon_text, lat_text, h, v, altitude,
		timestamp, in_background, requested_accuracy, speed, direction,
		battery_level, external_power, reachability) = position_data

	lines = []
	if len(text) > 1:
		lines.append(text.strip() + "\n")

	lines.append("Type: %s" % LOG_TYPES.get(type, UNEXPECTED_LOG_TYPE))

	if h > 0:
		lines.append("Horizontal accuracy: %0.0fm." % h)

	if in_background:
		lines.append("Captured during background operation.")
	else:
		lines.append("Captured during foreground operation.")

	lines.append("Battery %0.0f%%." % (battery_level * 100))
	if external_power > 0:
		lines.append("External power source present.")
	else:
		lines.append("Running on own batteries.")
	if reachability > 0:
		lines.append("Connected online.")
	elif 0 == reachability:
		lines.append("Online reachability not possible.")

	lines.append("Timestamp %d" % (timestamp))
	lines.append("\t%04d-%02d-%02d %02d:%02d:%02d." % (
		time.localtime(timestamp)[0:6]))

	output.write("<description>%s</description>" % "\n".join(lines))


def main():
	"""f() -> None

	Main entry point for the program.
	Process specified input files in sounds mode.
	"""
	options, files = process_arguments()
	for filename in files:
		convert_to_kml(filename, not options.no_zip)
		if options.gpx:
			convert_to_gpx(filename)


if "__main__" == __name__:
	logging.basicConfig(level = logging.DEBUG)
	main()
