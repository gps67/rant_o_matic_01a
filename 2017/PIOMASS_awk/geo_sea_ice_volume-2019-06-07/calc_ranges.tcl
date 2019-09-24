#!/usr/bin/env tclsh

# calc_ranges.tcl
# the values have already been found, and put in files:
#	
#	tmp/tmp_plot_data_min.data
#	tmp/tmp_plot_data_max.data
#
# to compute the amount of ice - energy that is processed
# then soon wont be
#


########## move this to libr code ############
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
########## move that to libr code ############
##############################################

proc read_file_pairs { filename } {
  # read pairs of data values into a flat array
  set fd [open $filename r]
  set filetext [read $fd ]
  set pairs []
  foreach {when val} $filetext {
	lappend pairs $when $val
  }
  return $pairs
}

proc read_2 {} {
	# read the two files 
	global L_max
	global L_min
	set L_max [read_file_pairs tmp/tmp_plot_data_max.data ]
	set L_min [read_file_pairs tmp/tmp_plot_data_min.data ]
}

proc pop_list_pair { listname year_varname val_varname } {
	# pop 2 values from a flat list
	# use named var parameters
	# return true/false on eot
	# lurk list must be list with even number of elements
	# lassign is also good for this
	upvar $listname listvar
	upvar $year_varname year_var
	upvar $val_varname val_var
	if {$listvar == {}} {
		return false
	}
	set year_var [lindex $listvar 0]
	set val_var [lindex $listvar 1]
	set listvar [lrange $listvar 2 end]
	return true
}

proc pop_max {} {
	global L_max
	global Y_max
	global V_max
	pop_list_pair L_max Y_max V_max
}

proc pop_min {} {
	global L_min
	global Y_min
	global V_min
	pop_list_pair L_min Y_min V_min
}

proc test_2 {} {
	global L_max
	global L_min
	while {[pop_list_pair L_max max_year max_val]} {
		puts "pair $max_year $max_val"
	}
	return
	set Y_max {}
	set Y_min {}
	set V_max {}
	set V_min {}
}

proc step_all_melts {} {
	global Y_max
	global V_max
	global Y_min
	global V_min
	# load the two files and queue to two head items
	read_2
	pop_min ;# || exit
	pop_max ;# || exit
	# actually we know that first data is mid apr max
	while {$Y_max > $Y_min} {
		puts "## unexpected need to pop_min so that max is first ##"
		if {![pop_min]} break
	}
	set looping 1
	while {$looping} {
		# convert Y_year to D_date
		set D_max  [YEAR_FRAC_TO_YEAR_MM_DD $Y_max]
		set D_min  [YEAR_FRAC_TO_YEAR_MM_DD $Y_min]
		set V_melt [format {%4.1f} [expr $V_max - $V_min]]
		if {[pop_min]} {
			set V_freeze [format {%4.1f} [expr $V_max - $V_min]]
			if {![pop_max]} { set looping 0 }
		} else {
			set V_freeze "####"
			set looping 0
		}

		puts "$D_max melts $V_melt $D_min freezes $V_freeze"
	}
}


step_all_melts
exit
test_2
