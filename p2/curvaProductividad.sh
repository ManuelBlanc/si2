#!/usr/bin/env bash

# Modo sano: se aborta si se encuentra un error o variable no definida
set -eu

# Codigos de escape para dar formato (vease `man tput`)
NORMAL=$(tput sgr0)
BOLD=$(tput bold)
UNDER=$(tput smul)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)

# Utilidades
INFO()  { >&2 echo "${GREEN}==> $NORMAL$BOLD$1$NORMAL"; }
WARN()  { >&2 echo "${YELLOW}==> $NORMAL$BOLD$1$NORMAL"; }
ERR()   { >&2 echo "${RED}==> $NORMAL$BOLD$1$NORMAL"; }
abort() { >&2 ERR "$1"; exit 1; }

# ----------------------------------------------------------------------------

# Parametros de configuracion
inc=50
max=500
ramp_time=1
server=10.1.11.2

for ((i=$inc; i <= $max; i+= $inc)); do

	outfile="curva/test$(printf %04i $i)"

	INFO "Ejecutando prueba para $(printf %4i $i) usuarios"
	(echo jmeter -n -t P2_ej6.jmx -Jthreads="$i" -Joutfile="$outfile.jmeter.csv"; sleep $((RANDOM % 3 + ramp_time + 5))) &
	jmeter_pid=$!

	sleep "$ramp_time"
	(echo ./si-monitor.sh "$server" "> $outfile.monitor.dsv"; sleep 1000) &
	monitor_pid=$!

	wait "$jmeter_pid"
	kill "$monitor_pid" > /dev/null 2>&1 && echo 'RIPPED'
	echo
done