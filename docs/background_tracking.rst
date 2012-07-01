=======================================
Record my position: Background tracking
=======================================

.. vim:tabstop=4 shiftwidth=4 encoding=utf-8 noexpandtab

:author: Grzegorz Adam Hankiewicz <gradha@imap.cc>

.. contents::

.. section-numbering::

.. raw:: pdf

   PageBreak oneColumn

General
=======

The information about background tracking is very sparse, and on
top of that is quite hard to debug correctly (running around on the
street with a macbook pro?). On top of this, the background location
options like significant updates and region monitoring provided by
iOS 4 have really bad accuracy. Well, to be honest, even foreground
GPS accuracy is quite bad when you aren't asking for it.

My conclusion is that to have a location aware application that
doesn't pinpoint you 10km away from your real position you need
some background trickery. In foreground you can track 100% accuracy,
then leaving foreground you have two options:

 * Set up a region to monitor an event.
 * Use low resolution location tracking.


Monitoring regions
------------------

Monitoring regions is not very accurate. According to internet
babbling, you shouldn't expect a resolution much better than 1km.
That's problematic if you are writing an application that should
differentiate between bars on the same city square (less than 200m).

However, monitoring regions has a really nice feature: if your
application is not running and the region is registered, iOS will
wake you up when the boundary is tresspassed.


Low resolution tracking
-----------------------

When you ask the GPS to give you positions, you can specify how
accurate you want them to be. By specifying 100m or higher, you are
avoiding many updates and lowering battery consumption. You will
still consume more battery than when using regions, and the accuracy
is probably on par.


The hybrid approach
-------------------

Since you can't trust the accuracy of any of the background
methods, the best would be to use them to receive updates, and when
those updates or events are received, the application enters a
**burst mode** where very accurate GPS information is requested for
up to 30 seconds or until the accuracy is less than 50m horizontally.
When the burst mode ends, the application goes back to sleep state.




