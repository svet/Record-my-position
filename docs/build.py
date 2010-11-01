#!/usr/bin/env python
# vim:tabstop=4 shiftwidth=4 encoding=utf-8
"""Builds the documentation. Some improvements over make or plain scripts.
"""

import glob
import logging
import os
import os.path
import subprocess
import sys


# The directory where the doxygen stuff will be put.
DOXY_DIR = "doxygen"

# List of pairs source->target for HTML generated documentation.
HTML_DOCS = [("%s.rst" % x, "%s.html" % x) for x in
	[os.path.splitext(x)[0] for x in glob.glob("*.rst")]]

# List of neato diagrams to be processed.
NEATO_SVG = glob.glob("*.neato")

# Commands to call external programs.
RST2HTML_PARAMS = ["rst2html.py", "--date", "--time"]
NEATO_PARAMS = ["neato", "-Tsvg", "-O"]


def verify_command(command_list, expected_string):
	"""f([string, ...], string) -> bool

	Returns True if the output of the specified command list
	contains the expected string.
	"""
	try:
		p = subprocess.Popen(command_list, stdout = subprocess.PIPE,
			stderr = subprocess.PIPE)
		for line in p.communicate():
			if line and line.find(expected_string) >= 0:
				return True
	except OSError:
		logging.error("Couldn't run %r", command_list)

	return False


def rebuild_doxy():
	"""f() -> None

	Calls doxygen to rebuild stuff.
	"""
	if not verify_command(["doxygen", "-h"], "Doxygen"):
		print ("You don't have Doxygen on your sistem. Please install the "
			"tool from http://www.doxygen.org/. If you are using macports, "
			"you can try 'sudo port install doxygen'.")
		sys.exit(1)

	logging.info("Building doxygen docs...")
	subprocess.check_call(["doxygen"])


def is_rebuild_needed(src, dest):
	"""f(string, string) -> bool

	Returns True if dest has to be rebuild from src, due to a
	missing file or more recent modification date.
	"""
	if not os.path.isfile(dest):
		return True

	src_time = os.path.getmtime(src)
	dest_time = os.path.getmtime(dest)
	return src_time >= dest_time


def rebuild_html_if_needed(src, dest):
	"""f(string, string) -> None

	Given the source path and destination path, verifies if
	rst2html has to be called on the file to update the html
	version.
	"""
	verified = False
	if is_rebuild_needed(src, dest):
		if not verified:
			if not verify_command(["rst2html.py", "-h"], "reStructuredText"):
				print ("You don't have rst2html.py on your system. Please "
					"install the docutils package from "
					"http://docutils.sourceforge.net/ and try again. You could "
					"also try running 'sudo easy_install docutils', or if you "
					"are using macports 'sudo port install py-docutils'.")
				sys.exit(1)
			verified = True

		logging.info("Building %r -> %r", src, dest)
		subprocess.check_call(RST2HTML_PARAMS + [src, dest])


def rebuild_svg_if_needed(src):
	"""f(string) -> None

	Pass the path to a neato diagram. The function will generate
	the svg version by appending .svg to the input src.
	"""
	dest = "%s.svg" % src
	if is_rebuild_needed(src, dest):
		if not verify_command(["neato", "-h"], "Automatically generate an"):
			print ("You don't have graphviz's neato on your system. Please "
				"install graphviz from http://www.graphviz.org/ or if you "
				"are using macports, try 'sudo port install graphviz'.")
			sys.exit(1)

		logging.info("Drawing %r -> %r", src, dest)
		subprocess.check_call(NEATO_PARAMS + [src])


def main():
	"""f() -> None

	Main entry point of the application.
	"""
	notify_doxy_rebuild = False
	if not os.path.isdir(DOXY_DIR):
		rebuild_doxy()
	else:
		notify_doxy_rebuild = True

	#for svg in NEATO_SVG:
	#	rebuild_svg_if_needed(svg)

	for src, dest in HTML_DOCS:
		rebuild_html_if_needed(src, dest)

	if notify_doxy_rebuild:
		print ("If you want to rebuild the doxygen documentation, "
			"delete the %r directory" % (DOXY_DIR))
	#else:
	#	print "If you want to build and install Xcode docs from doxygen, run:"
	#	print "cd %s/html && make install" % (DOXY_DIR)


if "__main__" == __name__:
	logging.basicConfig(level = logging.INFO)
	#logging.basicConfig(level = logging.DEBUG)
	main()
