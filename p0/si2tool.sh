#!/usr/bin/env bash

## Modo sano
set -eu

## Variables de configuracion
VM_HOST='si2@10.1.11.1'
VM_J2EE='/opt/glassfish4/glassfish'
verbose=true

# Formateo
NORMAL=$(tput sgr0)
BOLD=$(tput bold)
RED=$(tput setaf 1)

# Utilidades
INFO()  { echo "==> $BOLD$1$NORMAL"; }
abort() { echo "${RED}error:${NORMAL} $1"; exit 1; }
# ----------------------------------------------------------------------------

#(cd si2srv/ && ./si2fixMAC.sh $GRUPO $PAREJA $PC)
# HOST_IP="$(/sbin/ifconfig eth0:0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')"


setup() {
	## Comprobamos que este la carpeta con la maquina virtual
	if [[ ! -d si2srv/ ]]; then
		INFO 'No se encontro si2srv/, intentando descomprimir si2srv.tgz'
		## Intentamos descomprimir el .tgz
		tar xzvf si2srv.tgz || abort 'No se pudo descomprimir el fichero ./si2srv.tgz'
	fi

	## Configuramos la interfaz nueva para el host
	INFO 'Configurando la interfaz eth0. Se requiere la constraseña del usuario.'
	sudo /opt/si2/virtualip.sh eth0

	## Permitir cerrar maquina virtual
	if ! grep '^pref.vmplayer.exit.vmAction' ~/.vmware/preferences; then
		echo 'pref.vmplayer.exit.vmAction = "disconnect"' >> ~/.vmware/preferences
	fi

	INFO "Para poder conectarse por ssh, ejecutar $0 ssh0"
}

connect_db() {
	local DB="${1:-visa}"
	INFO "Connectandose a la base de datos: $DB"
	psql –U alumnodb "$DB"
}

launch_vm() {
	INFO 'Ejecutando si2fixMAC.sh'
	(cd ./si2srv/ && ./si2fixMAC.sh 2401 11 1)

	INFO "Arrancando la maquina virtual"
	vmplayer si2srv/si2srv.vmx
}

setup_ssh() {
	ssh-keygen -t rsa
	ssh-add
	ssh-copy-id $VM_HOST
}

connect_ssh() {
	INFO "Connectandose por ssh a $VM_HOST"
	ssh "$VM_HOST"
}

do_scp() {
	scp "$1" "$VM_HOST:/home/si2"
}

do_asadmin() {
	local CMD="${1:-start-domain domain1}"
	ssh $VM_HOST "$VM_J2EE/bin/asadmin $CMD"
}

show_log() {
	INFO "Mostrando log de Glassfish"
	ssh $VM_HOST "$VM_J2EE/domains/domain1/logs/server.log" | less
}

run_ant() {
	local ANT_CMD="${1:-todo}"
	shift
	export J2EE_HOME='/usr/local/glassfish-4.1.1/glassfish'
	ant "$ANT_CMD" "$@"
}

show_help() {
	cat <<-EOF
	setup	-- Configuracion inicial
	db   	-- Conecta con la base de datos
	vm   	-- Arranca la maquina virtual
	ssh  	-- Se conecta via ssh
	scp  	-- Copia archivos a la maquina virtual
	log  	-- Muestra el log del servidor
	EOF
}

CMDLET="${1:-help}"
shift
case "$CMDLET" in
	setup 	) setup      	"$@" ;;
	db    	) connect_db 	"$@" ;;
	vm    	) launch_vm  	"$@" ;;
	ssh   	) connect_ssh	"$@" ;;
	ssh0  	) setup_ssh  	"$@" ;;
	asa   	) do_asadmin 	"$@" ;;
	scp   	) do_scp     	"$@" ;;
	log   	) show_log   	"$@" ;;
	ant   	) run_ant    	"$@" ;;
	*|help	) show_help  	     ;;
esac