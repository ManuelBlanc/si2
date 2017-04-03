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
if [[ $# -eq 3 ]]; then
	end="${3}"
	inc="${2}"
	start="${1}"
elif [[ $# -eq 2 ]]; then
	end="${2}"
	inc="50"
	start="${1}"
elif [[ $# -eq 1 ]]; then
	end="$1"
	inc="50"
	start="$inc"
else
	abort "Numero de parametros incorrecto ($#)"
fi
ramp_time=10
server=10.1.11.2
cmdrunner="$HOME/.si2jmeter/apache-jmeter-2.13/lib/ext/CMDRunner.jar"
outdir="datos"

if [[ -d "$outdir" ]]; then
	WARN "Ya existe un directorio $outdir"
else
	mkdir datos
fi

INFO 'Limpiando la base de datos.'
psql -h 10.1.11.1 -U alumnodb visa <<< 'truncate table pago'

for ((i=$start; i <= $end; i+= $inc)); do

	outfile="$outdir/test$(printf %04i $i)"

	INFO "Ejecutando prueba para $(printf %4i $i) usuarios"
	jmeter -n -t P2-curvaProductividad.jmx -l "$outfile.jtl" -Jthreads="$i" &
	jmeter_pid=$!

	sleep "$ramp_time"
	INFO 'Arrancando el monitor'
	./si2-monitor.sh "$server" > "$outfile.mon.dsv" &

	wait "$jmeter_pid"
	killall "si2-monitor.sh" || : # Nunca falles!

	INFO 'Terminado la prueba. Generando el AggregateReport'
	java -jar "$cmdrunner" --tool Reporter --plugin-type AggregateReport --generate-csv "$outfile.tab.csv" --input-jtl "$outfile.jtl"

	INFO 'Limpiando la base de datos.'
	psql -h 10.1.11.1 -U alumnodb visa <<< 'truncate table pago'

	echo # Linea en blanco 
done
