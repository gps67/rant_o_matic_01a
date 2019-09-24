#!/usr/bin/env tclsh

# print out every years minimum and maximum vales
# the values have already been found, and put in files:
#	
#	tmp/tmp_plot_data_min.data
#	tmp/tmp_plot_data_max.data
#
# this tcl script is good at converting 1999.99 to 1999-12-30 +- 3 days
# it also prints the date of the last data sample (how else would you know)
#
# the original data used day-of-year adjusted to a 365 day year
# the gawk script converted to a floating point year
# this script converts it back to YEAR-MM-DD (but the fraction may be approx)

# the gawk script also does a rolling average which may be more use
# but it is useful to know WHEN the peaks tend to be, and it turns out:
#
# MAX ICE
#	YEAR-04-09
#	YEAR-05-01
# MIN ICE
#	YEAR-09-12
#	YEAR-09-23
#

puts "# this just lists data from input, but as YEAR-MM-DD not YEAR.FRAC"
puts "# Date as rounded fraction of year to day is approx within 3 days"
puts "# BUG prior to Sept the min is 01-Jan which is much more than min"
puts "# FIX require 3 days of values on other side of peak (GIGO)"
puts "#"

proc YEAR_FRAC_TO_YEAR_MM_DD {when} {
	# eg when == "1999.99"
 #	set y1 [::tcl::mathfunc::floor $when]
	set y1 [::tcl::mathfunc::int $when]
	set y12 [expr $when - $y1]

	# exported data result
	global day_of_year 
	set day_of_year [expr $y12 * 365 + 0.5 ]
	set day_of_year [::tcl::mathfunc::int $day_of_year]
	set day_of_year [format "%3d" $day_of_year]
	

	set t1 [clock scan "$y1-01-01 00:00"]
	set t12 [expr $y12 * 365 * 24 * 60 * 60]
	set t2 [expr $t1 + $t12]
	set t2 [::tcl::mathfunc::int [::tcl::mathfunc::round $t2]]
	# t2 is now the unix time in seconds of YEAR.FRAC

	set fmt {%Y-%m-%d}
	set YEAR_MM_DD [clock format $t2 -format $fmt]
	return $YEAR_MM_DD
}

proc show2 { day_of_year YEAR_MM_DD val {msg ""} } {
#	puts "WHEN $day_of_year +-3days $YEAR_MM_DD  VAL = $val $msg"
	puts "$YEAR_MM_DD  $val  # $msg"
}

foreach {file_max msg} {
	tmp/tmp_plot_data_max.data "MAX"
	tmp/tmp_plot_data_min.data "MIN"
} {
  puts "# reading from $file_max"

  set fd [open $file_max r]
  set filetext [read $fd ]
  foreach {when val} $filetext {
	set YEAR_MM_DD [YEAR_FRAC_TO_YEAR_MM_DD $when ]
	show2 $day_of_year $YEAR_MM_DD $val $msg
	# puts "WHEN $day_of_year +-3days $YEAR_MM_DD  VAL = $val"
	# puts "$YEAR_MM_DD  $val"
  }
}

set file_all tmp/tmp_plot_data_day.data.tmp
set fd [open $file_all]
set filetext [read $fd]
foreach {when val} $filetext {
	# do nothing
}
set YEAR_MM_DD [YEAR_FRAC_TO_YEAR_MM_DD $when ]
set msg "most recent date data"
show2 $day_of_year $YEAR_MM_DD $val $msg
