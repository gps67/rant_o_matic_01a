#!/usr/bin/awk -f
#!/usr/bin/gawk -f

# fortunately the data starts at day 0 of 1979
# but the average for the current incomplete year will be wrong


BEGIN {
	D_tmp = "/tmp/tmp_" # not secure not multiuser useful # ./tmp/tmp_
	D_tmp = "./tmp_" 
	D_tmp = "./tmp/tmp_" 
	# mk_tarball will ignore *.tmp
	filename_plot_script   = D_tmp "plot_script.gnuplot"
	filename_plot_data_day = D_tmp "plot_data_day.data.tmp"
	filename_plot_data_min = D_tmp "plot_data_min.data"
	filename_plot_data_max = D_tmp "plot_data_max.data"
	filename_plot_data_mid = D_tmp "plot_data_mid.data"
	filename_plot_data_avg1 = D_tmp "plot_data_avg1.data.tmp"
	filename_plot_data_avg2 = D_tmp "plot_data_avg2.data.tmp"
	filename_plot_data_avg3 = D_tmp "plot_data_avg3.data.tmp"
	filename_plot_png ="sea_ice_vol.png"
	plot_title="PIOMAS Arctic Sea Ice Volume"

	# I want to rename avg2 as avg365
	# but that comes from the A365 parameter (set next)

	A365=365*2
	A365=365*10
	A365=365*4
	A365=500 # days - makes less sense than < 365
	A365=300 # days
	A365=90 # days
	A365=180 # days
	A365=365*3
	A365=365*2
	A365=365*1

	F365=1.0*A365

	plot_to_png = 0
	plot_to_png = 1

	# plot or not
#	P_8 = 1
	P_max = 1
	P_min = 1
	P_mid = 0 # plot midyear avg
	P_avg = 1 # plot rolling day 365 average

	# remove old files to avoid making it look OK
	rm_f_filename( filename_plot_script )
	rm_f_filename( filename_plot_data_day )
	rm_f_filename( filename_plot_data_min )
	rm_f_filename( filename_plot_data_max )
	rm_f_filename( filename_plot_data_mid )
	rm_f_filename( filename_plot_data_avg1 ) # +8 against max
	rm_f_filename( filename_plot_data_avg2 ) # == avg for year A365
	rm_f_filename( filename_plot_data_avg3 ) # -8 against min
	rm_f_filename( filename_plot_png  )

	year_curr = -1

	data_day[0] = 0
	data_day_pos = 0
	data_day_max = 0

	plot_script = plot_script_daily()
	print plot_script > filename_plot_script
	close( filename_plot_script )
	RUN4( "nl -ba " filename_plot_script ) # line numbers are useful
	RUN4( "sh -c pwd" )
  	# print plot_script

	pipe_gnuplot = "gnuplot " filename_plot_script
	pipe_view_png = "gm display " filename_plot_png  " &"
	copy_png_to_FTP = "cp -p " filename_plot_png  " $HOME/FTP_/ "
	# ampersand optional, stops waiting for it # may need SHELL support

	process_data_file()

	RUN4( "gnuplot " filename_plot_script )
 if(plot_to_png) {
	RUN4( pipe_view_png )
	RUN4( copy_png_to_FTP )
 }

	# how to avoid the AWK filter theme
	# close( /dev/stdin ) # nope
	exit(0)
}
function get_filename_data_gz()
{
	# you have to edit out the 2016 ANYWAY
	# so option of linking to here or finding in 2016/FTP_
	FTP="/home/gps/2016/FTP_"
	FTP="~/FTP_"
	F="PIOMAS.vol.daily.1979.2016.Current.v2.1.dat"
	F="PIOMAS.vol.daily.1979.2017.Current.v2.1.dat"
	# DOH awk strings concat, no + required, nor allowed
	F=FTP "/" F ".gz"
	return F
}
function Q1( str ) {
	return "'" str "'"
}
function RUN4( cmd ) {
	print "## " cmd
	print 9 | cmd
	close( cmd ) # otherwise it is still running 
}
function rm_f_filename( filename )
{
	RUN4(" rm -f " filename )
}

function flush_year_end() {

	# year_min_YF is the YEAR.frac when the min was seen
	# days_past_min is number of days AFTER min seen
	# days_past_max is ...

	Y_min2 = sprintf( "%.2f", year_min_YF )
	Y_max2 = sprintf( "%.2f", year_max_YF )
	L_min = Y_min2 " " year_min_vol 
	L_max = Y_max2 " " year_max_vol
	if( seen_peak_min )
		print L_min > filename_plot_data_min
	if( seen_peak_max )
		print L_max > filename_plot_data_max
	if( 320 < year_vol_avg_count ) { # allow a few missing points
		year_vol_avg = year_vol_avg_sum / year_vol_avg_count
		L_avg = year_curr + 0.5 " " year_vol_avg
		print L_avg > filename_plot_data_mid
	}
	# print L | pipe_gnuplot
}

function line_in( year, year_frac, day, vol ) {
	fmt_3 = "%.4f"
	fmt_3 = "%.3f"
	if( year_curr != year ) {
	 if( year_curr != -1 ) flush_year_end()
	 year_curr = year
	 year_min_vol = vol
	 year_max_vol = vol
	 recent_min_vol = vol
	 recent_max_vol = vol

	 seen_upslope = 0 # defunct peak from two slope detectors
	 seen_downslope = 0
	 
	 seen_peak_max = 0
	 seen_peak_min = 0
	 days_past_peak = 0
	 peak_was_hi = 1
	 year_vol_avg_sum = 0
	 year_vol_avg_count = 0
	 year_min_YF = year_frac
	 year_max_YF = year_frac
	}
	year_frac3 = sprintf( fmt_3, year_frac )
	Y_now = year_frac
	# looking for PEAK - cant be within 10 days of year start or data end
	# this only works because data is already quite smooth
	# a zig zag noise would accumulate days of BOTH
	# ANY noise spoils monatonic tests here, should go for 10 less than peak

	D10 = 10
	D10 = 1
	D10 = 9
	D10 = 7 # 2016-04 only 8 days before end of month after max !!
	D10 = 3
	D20 = 20 
	C1 = "~"
	C2 = " "
	C3 = " "

	days_past_max ++
	days_past_min ++
	days_past_peak ++

	if( vol < recent_min_vol ) {
		# new min evolving
		C1 = "<"
		recent_min_vol = vol
		days_past_min = 0 
		days_past_peak = 0
		peak_was_hi = 0
		if( vol < year_min_vol ) {
			year_min_vol = vol
			year_min_YF = year_frac;
		}
	}
	if( recent_max_vol < vol ) {
		# new max
		C1 = ">"
		recent_max_vol = vol
		days_past_max = 0
		days_past_peak = 0
		peak_was_hi = 1
		if( year_max_vol < vol ) {
			year_max_vol = vol
			year_max_YF = year_frac;
		}
	}
	{
		if( days_past_peak > D10 ) {
		 if( peak_was_hi ) {
			seen_peak_max = 1
			days_past_max = 0
		 } else {
			seen_peak_min = 1
			days_past_min = 0
		 }
				C2 = "P"
		}
	}

 if(0) {
		S12 = C1 C2 C3
	printf( "day %3d vol %.3f %s days_past_min_max %3d,%3d seen up,down %d,%d seen min_max %d,%d\n",
		day, vol, S12,
		days_past_min,
		days_past_max,
		seen_upslope,
		seen_downslope,
		seen_peak_min,
		seen_peak_max )
 }

	year_vol_avg_sum += vol
	year_vol_avg_count += 1

	data_day_avg = 1
	data_day_pos ++
	if( data_day_pos == A365 ) data_day_pos = 1
	if( data_day_max < A365 ) {
		data_day_max ++
		# print "data_day_max " data_day_max
		data_day_avg = 0
		vol_old = 0
	} else {
		# print "data_day_max " data_day_max
		vol_old = data_day[ data_day_pos ] 
	}

	data_day[ data_day_pos ] = vol
	year_vol_avg1_sum += vol - vol_old
	if( data_day_avg ) {
		A365_half = F365/(365.0*2.0) 
		year_frac3 = sprintf( fmt_3, (year_frac - A365_half ))
		L_day_1 = year_frac3 " " (year_vol_avg1_sum/F365 + 8.0)
		L_day_2 = year_frac3 " " (year_vol_avg1_sum/F365)
		L_day_3 = year_frac3 " " (year_vol_avg1_sum/F365 - 8.0)
		print L_day_2 > filename_plot_data_avg2
	 if( P_8 ) {
		print L_day_1 > filename_plot_data_avg1
		print L_day_3 > filename_plot_data_avg3
	 }
	}

	year_frac3 = sprintf( fmt_3, year_frac )
	L_day = year_frac3 " " vol
	print L_day > filename_plot_data_day
}

function process_data_file() {
	F = get_filename_data_gz()

	CMD = "zcat " F 
	LNO = 0
	while(( CMD | getline ) > 0 ) {
		LNO ++
		if(LNO == 1 ) continue
		# if( LNO > 7) break
		year=$1
		day=$2
		vol=$3
		# convert day of year to fraction of year
		YY=year + (day/365.0) # different to A365
		line_in( year, YY, day, vol )
	}

# SHOULD CALL but not doing so because min max not passed
	if( year_curr != -1 ) flush_year_end()

	close(CMD) # it exited ? code ?
	close( filename_plot_data_day )
	close( filename_plot_data_min )
	close( filename_plot_data_max )
	# was BUG not flushing avg before graph plotted!! errm all 3
	close( filename_plot_data_avg1 )
	close( filename_plot_data_avg2 )
	close( filename_plot_data_avg3 )
	# old way # close( pipe_gnuplot )
	# belt and braces
	fflush()
}

function plot_script_daily()
{

	plot_title_line_max = "max" # 
	plot_title_line_day = "day" # better than "<CAT"
	plot_title_line_min = "min" # 
	plot_title_line_mid = "mid" # is annual average
	plot_title_line_avg1 = "avg2+8" # 
	plot_title_line_avg2 = "avg" # rolling average
	plot_title_line_avg3 = "avg2-8" # 
	plot_Y_label = "1000 km3"
	plot_filename = "<cat"
	plot_filename = filename_plot_data_day

	CRLF = "\n"
	T = ""
 if(plot_to_png) {
	T = T CRLF "set terminal png"
	T = T CRLF "set output " Q1(filename_plot_png)
	T = T CRLF "set term png size 1200, 800"
	
 } else {
#	T = T CRLF "set output " Q1(filename_plot_png)
 }
#	T = T CRLF "set xrange [1960:2040]"
#	T = T CRLF "set xrange [:2040]"
#	T = T CRLF "set xrange [1975:2020]"
	T = T CRLF "set xrange [1950:2100]"
	T = T CRLF "set yrange [0:40]"
#	T = T CRLF "set yrange [-10:40]"
	T = T CRLF "set title " Q1(plot_title)
	T = T CRLF "set ylabel " Q1(plot_Y_label)
	T = T CRLF "set multiplot"
	T = T CRLF "plot \\" 
P_max&&	T = T CRLF Q1(filename_plot_data_max) " with lines title " Q1(plot_title_line_max) ", \\"
	T = T CRLF Q1(filename_plot_data_day) " with lines title " Q1(plot_title_line_day) ", \\"
P_mid&&	T = T CRLF Q1(filename_plot_data_mid) " with linespoints title " Q1(plot_title_line_mid) ", \\"
P_8&&	T = T CRLF Q1(filename_plot_data_avg1) " with lines title " Q1(plot_title_line_avg1) ", \\"
P_avg&&	T = T CRLF Q1(filename_plot_data_avg2) " with lines title " Q1(plot_title_line_avg2) ", \\"
P_8&&	T = T CRLF Q1(filename_plot_data_avg3) " with lines title " Q1(plot_title_line_avg3) ", \\"
P_min&&	T = T CRLF Q1(filename_plot_data_min) " with lines title " Q1(plot_title_line_min)
	T = T CRLF 
 if(!plot_to_png) {
	T = T CRLF "set nomultiplot"
	T = T CRLF "pause 111" # I dont know, and its in bg
	T = T CRLF "pause 11"
	T = T CRLF "pause -1"
 }
	T = T CRLF 
	return T
}

{
	print "## EVERY LINE"
	exit(22)
}
