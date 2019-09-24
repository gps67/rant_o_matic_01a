#!/bin/bash
#
# make the symb link to where the file is usually downloaded
# edit each year and person
# 2018 must edit awk script too
#

D1=${HOME}/YEAR/FTP_
F1=PIOMAS.vol.daily.1979.2017.Current.v2.1.dat.gz

set -x
ln -sf $D1/$F1 .
