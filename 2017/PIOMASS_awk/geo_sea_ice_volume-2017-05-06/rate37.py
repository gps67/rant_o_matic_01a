#!/usr/bin/env python

COMMENT = """
The blue line is the daily running 365 day average,
so it stops 6 months ago, but includes "today"

It is computed and retained in a 37.3 * 365 line text file,
using a decimal fraction of the year.
If you want those, get the gnuplot/awk/tcl/py project 
and run it (linux helps, WIN32 may be possible)
then look in the file tmp_plot_data_avg2.data.tmp
Here are the two end points:

	1979.503 25.387
#del	2016.829 12.9045
	2016.914 12.8125

The graph has noise, but the very first and last blue points
seem representative, of a straight line, with kicks every 30 years,
possibly a curve getting steeper.

The data before 1979 is absent (satellite readings),
 but it must follow the trend for 3 years or so.
I would hazard a guess of the blue line going back in time to
come from a flat 30, maybe someone can fit other things,
but without any interpolation, beyond 3 years at the same straight line,
it is clear to say that 4 decades ago,
the Arctic sea ice was twice as much as it is now.

One half gone, the other ... well mobile warmth effect kicks in
(melting ice melts where it was, heat in warm water moves about)

The first and last blue points are:
"""

# T1 = 1979.503
# V1 = 25.387
# T2 = 2016.914
# V2 = 12.8125

# edit the following over the next 2.5 years, it will extrpolate less
# stop when it truncates under-extra-polates

filename='tmp/tmp_plot_data_avg2.data.tmp'

fd = open( filename, "r" )
lines = fd.readlines()
line_first = lines[0]
line_last = lines[-1]
lines = None
fd.close()
#
# ok if not enough line that should have failed
#
if 0:
	print line_first
	print line_last
(T1, V1) = line_first.split()
(T2, V2) = line_last.split()

T1 = float( T1 )
T2 = float( T2 )

V1 = float( V1 )
V2 = float( V2 )

if 0:
	print "T2 - T1 == ", T2 - T1
	print "V2 - V1 == ", V2 - V1

YEARS37 = T2 - T1
MELT37 = V2 - V1 # a negative- number means melt, a positive+ means more ice
MELT1 = MELT37 / YEARS37 # average melt per year for linear end to end (-ve)

YEARS40 = 40.0
MELT40 = MELT1 * YEARS40

PRE_MELT_37 = V1
PRE_MELT_40 = V2 - MELT40
V0 = PRE_MELT_40 
T0 = T2 - YEARS40

RATE37 = MELT37 / V2 # (approx -0.48 when V1 -0.98 when v2 )
RATIO37 = ( V2 / V1 ) * 100.0 # (approx 0.51)
RATIO40 = ( V2 / V0 ) * 100.0
RATIO1  = ( -MELT1 / V0 ) * 100.0

def P( name, value, desc ):
	print( '%-9s %9.4f  %s' % (name, value, desc ))
print
print( '# values plucked from ' + filename )
print

P( "T2", T2, "Middle of recent year" )
P( "T1", T1, "Middle of first year" )
P( "T0", T0, "Middle of extrapolated-to-40 years ago" )
print
P( "V2", V2, "NEW at T2 avg 365" )
P( "V1", V1, "Old at T1 avg 365 (unit 1000 km3)" )
P( "V0", V0, "OLD at T0 avg 365 - extrapolated by %3.1f years" % (T1 - T0) )
print
P( "YEARS37", YEARS37, "Years between mid year averages (37ish)" )
P( "MELT37", MELT37, "Vol melt over 37ish years (1000 km3)" )
P( "MELT1", MELT1, "Vol melt per year (1000 km3 / year)" )
# P( "RATE37", RATE37, "RATE37 -loss/left melt over 37 years" )
P( "RATIO37", RATIO37, "percent of what it was %4.1f years ago" % YEARS37 )
P( "RATIO1", RATIO1, "percent MELT EACH YEAR over 37 years" )
P( "RATIO40", RATIO40, "percent of what it was 40 years ago" )


# OUTPUT
"""
# you must edit the end points into this script

T2        2016.9140  Middle of recent year
T1        1979.5030  Middle of first year
T0        1976.9140  Middle of extrapolated-to-40 years ago

V2          12.8125  NEW at T2 avg 365
V1          25.3870  Old at T1 avg 365 (unit 1000 km3)
V0          26.2572  OLD at T0 avg 365 - extrapolated by 2.6 years

YEARS37     37.4110  Years between mid year averages (37ish)
MELT37     -12.5745  Vol melt over 37ish years (1000 km3)
MELT1       -0.3361  Vol melt per year (1000 km3 / year)
RATIO37     50.4687  percent of what it was 37.4 years ago
RATIO1       1.2801  percent MELT EACH YEAR over 37 years
RATIO40     48.7961  percent of what it was 40 years ago
"""
