#!/usr/bin/env bash

awk -F, '
BEGIN { OFS = "," }
FNR==3 { printf "%s,%s,%s,", $3,$5,$9 }
FNR==4 { printf "%s,%s,%s\n",  $3,$5,$9 } ' datos/*.tab.csv