======================
Record my GPS position
======================

:author: Grzegorz Adam Hankiewicz <gradha@imap.cc>

.. contents::

.. section-numbering::

.. raw:: pdf

   PageBreak oneColumn

General
=======

Record my GPS position is a simple iPhone client to record and save GPS
information. The stored positions in the database can later be extracted
through iTunes file interface or emailed in CSV/GPX format to process for
different purposes with external programs.

The CSV dumps contains all the possible device information while the GPX
version is just for convenience allowing you to view positions in another
program, since most information is stripped.  The ``csv_to_kml/csv_to_kml.py``
script can convert the CSV file to a prettier KML/GPX file for opening in
`Google Earth`__.

__ http://earth.google.com/

Note that for the moment the program only uses active GPS, which
drains the battery quickly, even when running in the background.
Don't run it for more than an hour if you want to use your iPhone
as something other than a dead weight.

The app works for the iPod touch, but the accuracy varies a lot
and you depend on wifi location, so you won't get very useful
readings in open fields, only in crowded cities which may have been
previously mapped by Skyhook (http://www.skyhookwireless.com/), the
people doing wifi core location for Apple. On the plus side I had
my iPod touch on with the program running in the background for a
whole day and didn't consume more than a quarter of the battery,
so it seems the wifi location doesn't require as much power.

This program was possible due to `eFaber`__ being nice guys and
allowing me to release this as open source. You can browse more
software made by eFaber at http://itunes.com/apps/svetoslavivantchev/.


__ http://efaber.net/


App store
=========

.. image:: https://github.com/downloads/gradha/Record-my-position/record_my_gps_position_qr_appstore.png
   :align: right

Record my GPS position can be downloaded for free from the Apple
App Store
(http://itunes.com/apps/electrichandssoftware/recordmygpsposition/). You
can find other of my creations on the App Store under my Electric
Hands Software brand (http://itunes.com/apps/electrichandssoftware/)
which you can also find at http://elhaso.com/.


Requests and issues
===================

For requests and problems, feel free to use github's tracker at
https://github.com/gradha/Record-my-position/issues.


Source code
===========

Requirements
------------

The source code uses SDK 4.1 and deploys on 3.x. Patches are welcome
to make it compile out of the box with previous SDK versions. In
order to dynamically generate the versioned splash number, you need
Cobra (http://cobra-language.com/) to compile the
``script/watermark.cobra`` program and run it.


Installation
------------

Here are the steps to compile and build yourself everything:

* Perform some terminal magic::

    git clone git://github.com/gradha/Record-my-position.git
    cd Record-my-position
    git submodule init
    git submodule update

* If you want to generate the versioned splash images::

    cobra scripts/watermark.cobra -run-args vX.Y.Z

  If you don't want to bother with cobra, simply copy the
  ``Default*.png`` images from ``resources/reference`` to ``resources``
  so that XCode can find something.
* Open Record_my_position.xcodeproj with XCode and build and run.
* Turn on the GPS tracking and record some positions.
* In the **Share** tab use the button that sends you the logs.
* Process the CSV logs with ``csv_to_kml/csv_to_kml.py``, a Python
  script. It generates KML or GPX files.
* Open the converted KML/GPX files with `Google Earth`__.

__ http://earth.google.com/


License
-------

Unless otherwise stated, this source code is available under the
BSD license (http://www.opensource.org/licenses/bsd-license.php).
This license doesn't apply to the source code found in the *external*
subdirectory, which has its own license as it wasn't written by me
(external source code should contain its license attached or embedded
somewhere, if not, contact me to fix that).  Here's the license
template applied to this project:

Copyright (c) 2011, Grzegorz Adam Hankiewicz.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name of Electric Hands Software nor the names of its
  contributors may be used to endorse or promote products derived
  from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.


