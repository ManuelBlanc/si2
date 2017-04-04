#!/usr/bin/env bash

awk -F, '
NR == 1 { print "usuarios avg p90 rate avg p90 rate" }
FNR == 3 { printf "%s %i %i %f ", $2/10, $3, $5, $9 }
FNR == 4 { printf "%i %i %f\n",  $3, $5, $9 }
' datos/*.tab.csv > datos/agregado.tab.dsv

awk '
BEGIN { OFS=" " }
FNR == 1 { printf "%i%s", substr(FILENAME, 11, 4), OFS }
/TOT.MUESTRAS/ { getline; print $1, $2, $3, $4 }
' datos/*.mon.dsv > datos/agregado.mon.dsv