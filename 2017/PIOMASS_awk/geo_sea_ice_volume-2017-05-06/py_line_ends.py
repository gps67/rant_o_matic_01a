#! /usr/bin/env python

filename='/home/gps/YEAR/src/SCRATCH_SCRIPTS/gnu_plot/geo_sea_ice_volume/tmp/tmp_plot_data_avg2.data.tmp'

fd = open( filename, "r" )
lines = fd.readlines()
line_first = lines[0]
line_last = lines[-1]
lines = None
#
# ok if not enough line that should have failed
#
if 0:
	print line_first
	print line_last
(Y1, V1) = line_first.split()
(Y2, V2) = line_last.split()

Y1 = float( Y1 )
Y2 = float( Y2 )

V1 = float( V1 )
V2 = float( V2 )

print "Y2 - Y1 == ", Y2 - Y1
print "V2 - V1 == ", V2 - V1
