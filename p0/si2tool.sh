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
INFO()  { verbose && echo "==> $BOLD$1$NORMAL"; }
abort() { echo "${RED}error:${NORMAL} $1"; exit 1; }
# ----------------------------------------------------------------------------

#(cd si2srv/ && ./si2fixMAC.sh $GRUPO $PAREJA $PC)
# HOST_IP="$(/sbin/ifconfig eth0:0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')"


setup() {
	## Comprobamos que este la maquina virtual en el mismo directorio
	[[ -f si2srv.tgz ]] || abort 'No se encontro la maquina virtual si2srv.tgz'
	
	## La descomprimimos
	tar xzvf si2srv.tgz
	sudo /opt/si2/virtualip.sh eth0

	## Permitir cerrar maquina virtual
	if ! grep; then
		echo 'pref.vmplayer.exit.vmAction = "disconnect"' >> ~/.vmware/preferences
	fi

	## Generar y copiar identidad para ssh sin contraseña
	ssh-keygen -t rsa
	ssh-copy-id $USR_HOST
}

connect_db() {
	local DB="${1:-visa}"
	INFO "Connectandose a la base de datos: $DB"
	psql –U alumnodb "$DB"
}

launch_vm() {
	local VM="${1:-si2srv/si2srv.vmx}"
	INFO "Arrancando la maquina virtual"
	vmplayer "$VM"
}

connect_ssh() {
	INFO "Connectandose por ssh a $VM_HOST"
	ssh "$VM_HOST"
}

show_log() {
	INFO "Mostrando log de Glassfish"
	ssh $USR_HOST $VM_J2EE/domains/domain1/logs/server.log | less
}

run_ant() {
	local ANT_CMD="${1:-todo}"
	shift
	export J2EE_HOME='/usr/local/glassfish-4.1.1/glassfish'
	ant "$ANT_CMD" "$@"
}

show_help() {
	echo <<-EOF
	setup -- Configuracion inicial
	db 	  -- Conecta con la base de datos
	vm 	  -- Arranca la maquina virtual
	ssh	  -- Se conecta via ssh
	log	  -- Muestra el log del servidor
	EOF
}

CMDLET="$1"
shift
case "$CMDLET" in
	setup 	) setup      	"$@" ;;
	db    	) connect_db 	"$@" ;;
	vm    	) launch_vm  	"$@" ;;
	ssh   	) connect_ssh	"$@" ;;
	log   	) show_log   	"$@" ;;
	ant   	) run_ant    	"$@" ;;
	*|help	) show_help  	     ;;
esac