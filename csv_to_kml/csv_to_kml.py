#!/usr/bin/env python
# vim:tabstop=4 shiftwidth=4 encoding=utf-8
"""Converts CSV files with expected geodetic data into nice KML files.
"""

from __future__ import with_statement

from contextlib import closing
from optparse import OptionParser

import csv
import logging
import os
import os.path
import xml.etree.ElementTree as ET


ROW_LOG = 0
ROW_POSITION = 1


class Track:
	"""Holds the information for a more or less related group of positions."""
	pass


def process_arguments():
	"""f() -> [string, ...]

	Parses the commandline arguments. The user only needs to
	specify csv files, which will be converted into kml ones.
	"""
	parser = OptionParser()
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

	return args


def load_csv(filename):
	"""f(string) -> [{string: ?, ...}, ...]

	Loads a CSV file and returns a list of dictionaries, each
	representing one valid position.
	"""
	rows = []
	with open(filename, "rb") as input:
		reader = csv.reader(input)
		for row in reader:
			type, text = int(row[0]), row[1], 
			longitude, latitude = float(row[2]), float(row[3])
			longitude_text, latitude_text = row[4], row[5]
			h_accuracy, v_accuracy = float(row[6]), float(row[7])
			altitude = float(row[8])
			timestamp = int(row[9])
			rows.append((type, text, longitude, latitude, longitude_text,
				latitude_text, h_accuracy, v_accuracy, altitude, timestamp))

	return rows


def filter_csv_rows(rows):
	"""f([(), ...]) -> [Track, ...]

	Filters a loaded csv converting raw positions into individual track objects.
	"""
	t = Track()
	t.positions = rows
	return [t]


def process_file(filename):
	"""f(string) -> None

	Converts the input csv file into an kml file, replacing the extension.
	"""
	kml_filename = "%s.kml" % (os.path.splitext(filename)[0])
	logging.info("%r -> %r", filename, kml_filename)
	tracks = filter_csv_rows(load_csv(filename))
	if len(tracks) < 1:
		logging.error("No data found in %r", filename)
		return

	short_name = os.path.splitext(os.path.basename(filename))[0]

	with open(kml_filename, "wb") as output:
		output.write("""<?xml version='1.0' encoding='latin1'?>
<kml xmlns='http://earth.google.com/kml/2.2'>
<Document><name>%s</name>
	<open>1</open>
		<description>Positions recorded with http://github.com/gradha/Record-my-position</description>
    	<Style id='red'><LineStyle><color>bb0000ff</color><width>5</width></LineStyle></Style>
		<Style id='orange'><LineStyle><color>bb00b4ff</color><width>4</width></LineStyle></Style>
""" % (short_name))

		for track in tracks:
			generate_track(track, output)

		output.write("</Document></kml>")

	# Validate generated kml..
	ET.parse(kml_filename);


def generate_track(track, output):
	"""f(Track, io-bbject) -> None

	Outputs valid kml xml for the track.
	"""
	output.write("""<Folder><name>%s</name><open>0</open>
	<Placemark><styleUrl>red</styleUrl><MultiGeometry><LineString>
	<tessellate>1</tessellate><coordinates>
""" % ("%d" % len(track.positions)))

	for (type, text, lon, lat, lon_text, lat_text, h, v, altitude,
			timestamp) in track.positions:
		if ROW_POSITION != type:
			continue

		output.write("%0f,%f,0\n" % (lon, lat))

	output.write("""</coordinates></LineString></MultiGeometry>
</Placemark></Folder>
""")


def main():
	"""f() -> None

	Main entry point for the program.
	Process specified input files in sounds mode.
	"""
	for filename in process_arguments():
		process_file(filename)


if "__main__" == __name__:
	logging.basicConfig(level = logging.DEBUG)
	main()
