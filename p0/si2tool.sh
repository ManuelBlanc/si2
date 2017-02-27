#!/usr/bin/env bash

## Modo sano
set -eu

## Constantes de configuracion
VM_USER='si2'
VM_HOST='10.1.11.1'
VM_USER_HOST="$VM_USER@$VM_HOST"
VM_J2EE='/opt/glassfish4/glassfish'

## Codigos de escape para dar formato
## tput usa la base de datos de terminfo para obtenerlos de forma portable
NORMAL=$(tput sgr0)
BOLD=$(tput bold)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 2)
GREEN=$(tput setaf 2)

## Utilidades
INFO()  { echo "${GREEN}==> $NORMAL$BOLD$1$NORMAL"; }
WARN()  { echo "${YELLOW}==> $NORMAL$BOLD$1$NORMAL"; }
ERR()   { echo "${RED}==> $NORMAL$BOLD$1$NORMAL"; }
abort() { ERR "$1"; exit 1; }

## ----------------------------------------------------------------------------

## Comprobamos que este la carpeta con la maquina virtual
[[ ! -d si2srv/ ]] || abort "" 

cmd__setup() {
	## Configuramos la interfaz eth0:0 con una IP 10.10.*.* para el host
	INFO 'Configurando la interfaz eth0. Se requiere la constraseña del usuario.'
	sudo /opt/si2/virtualip.sh eth0

	## Permitir cerrar maquina virtual
	if ! grep '^pref.vmplayer.exit.vmAction' ~/.vmware/preferences; then
		## TODO: Investigar si esto ayuda a que la VM sea completamente headless
		cat >> ~/.vmware/preferences <<-EOF
		pref.vmplayer.exit.vmAction = "disconnect" 
		hints.hideAll = "TRUE"
		msg.noOk = "TRUE"
		EOF
	fi

	## No deberia ser necesario porque VMware Player pregunta si has movido o
	## copiado la maquina virtual. Si seleccionas "La he copiado", genera
	## una MAC nueva aleatoriamente.
	# INFO 'Ejecutando si2fixMAC.sh'
	# (cd ./si2srv/ && ./si2fixMAC.sh 2401 11 1)

	INFO 'Arrancando la maquina virtual. Puedes cerrarla despues de que arranque.'
	vmplayer si2srv/si2srv.vmx &

	INFO 'Esperando a que haya conectividad'
	until ping -c1 "$VM_HOST" > /dev/null 2>&1; do
		echo -n '.'
		sleep 1
	done
	echo # Nueva linea

	INFO 'Configurando el ssh para poder conectarse con un certificado'
	ssh-keygen -t rsa
	ssh-add
	ssh-copy-id "$VM_USER_HOST"
}

cmd__ant()      { J2EE_HOME='/usr/local/glassfish-4.1.1/glassfish' ant "$@";           }
cmd__psql()     { psql –U alumnodb "${1:-visa}";                                       }
cmd__ssh()      { ssh "$VM_HOST" "$@";                                                 }
cmd__upload()   { scp "$1" "$VM_USER_HOST:${2:-/home/si2}";                            }
cmd__download() { scp "$VM_USER_HOST:$1" "${2:-.}";                                    }
cmd__asadmin()  { ssh $VM_USER_HOST "$VM_J2EE/bin/asadmin ${1:-start-domain domain1}"; }
cmd__log()      { ssh $VM_USER_HOST "$VM_J2EE/domains/domain1/logs/server.log" | less; }

cmd__info() {
	if_ip() { ifconfig "$1" | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'; }
	cat <<-EOF
	usuario@host     = $VM_USER_HOST
	IP de eth0:0     = $(if_ip eth0:0 2>&1)
	IP de vmnet1     = $(if_ip vmnet1 2>&1)
	IP de vmnet8     = $(if_ip vmnet8 2>&1)
	EOF
}

cmd__help() {
	cat <<-EOF
	uso: $BOLD$exe <comando> [<argumentos]$NORMAL

	Donde el comando es:
	   setup      Configuracion el host para la maquina virtual.
	   ant        Ejecuta un comando ant con el \$J2EE_HOME correcto
	   psql       Abre una sesion psql con la base de datos del servidor.
	   ssh        Se conecta via ssh o ejecuta un comando remotamente.
	   upload     Copia archivos de host -> vm.
	   download   Copia archivos de vm   -> host.
	   asadmin    Ejecuta un comando con asadmin
	   log        Muestra el log de Glassfish
	   help       Muestra esta ayuda
	EOF
}

exe="$0"
cmd="cmd__${1:-help}"

## Comprobamos que exista el subcomando como funcion
if [[ "$(type -t "$cmd")" != 'function' ]]; then
	abort "$exe: '$1' no es un comando valido. Vease '$exe help'"
fi

## shift devuelve 1 si no hay mas parametros posicionales
shift || true
"$cmd" "$@"
exit 0

## VERSION MAS ELABORADA:

## El comando 'compgen' se usa para genera todas los posible comandos
## Se leen a un array con 'read'. Este modo devuelve codigo de error /= 0
## asi que hay que poner un || true al final.
#IFS=$'\n' read -d '' -r -a matches < <(compgen -A function "$cmd") || true
#if [[ ${#matches[@]} -eq 0 ]]; then
#	abort "$exe: '$1' no es un comando valido. Vease '$exe help'"
#fi
#if [[ ${#matches[@]} -gt 1 ]]; then
#	ERR "$exe: el comando '$1' es ambiguo entre los siguientes:"
#	printf "%s\n" "${matches[@]}" | cut -c 6- | column
#	abort 'Por favor introduce algo mas especifico.'
#fi
