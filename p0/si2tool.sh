#!/usr/bin/env bash


## ESPECIAL: Si nos estan sourceando configuramos el entorno local
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	echo 'Instalado en el entorno local:'; echo

	export J2EE_HOME='/usr/local/glassfish-4.1.1/glassfish'
	echo "export J2EE_HOME=$J2EE_HOME"

	alias si2tool="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/si2tool.sh"
	alias si2tool
	return 0
fi

## ----------------------------------------------------------------------------

## Modo sano
set -eu

## Codigos de escape para dar formato
## tput usa la base de datos de terminfo para obtenerlos de forma portable
NORMAL=$(tput sgr0)
BOLD=$(tput bold)
UNDER=$(tput smul)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 2)
GREEN=$(tput setaf 2)

## Utilidades
INFO()  { >&2 echo "${GREEN}==> $NORMAL$BOLD$1$NORMAL"; }
WARN()  { >&2 echo "${YELLOW}==> $NORMAL$BOLD$1$NORMAL"; }
ERR()   { >&2 echo "${RED}==> $NORMAL$BOLD$1$NORMAL"; }
abort() { >&2 ERR "$1"; exit 1; }

## ----------------------------------------------------------------------------

## Traduce un codigo de grupo a un entero
group2num() {
	case "$1" in
		2401) echo 1 ;; 2402) echo 2 ;; 2403) echo 3 ;;
		2311) echo 4 ;; 2312) echo 5 ;; 2313) echo 6 ;;
		2361) echo 7 ;; 2362) echo 8 ;; 2363) echo 9 ;;
		*) abort "group2num: $1 es un numero de grupo invalido" ;;
	esac
}

## Constantes de configuracion
: ${SI2_GROUP:=2401}
: ${SI2_PAIR:=11}
: ${SI2_VM:=1}

## Permitimos leer opciones que especifiquen grupo, etc.
while getopts g:p:m: opt; do
	case $opt in
		g) SI2_GROUP="$OPTARG" ;;
		p) SI2_PAIR="$OPTARG" ;;
		m) SI2_VM="$OPTARG" ;;
	    \?) abort 'error procesando las opciones' ;;
	esac
done
shift $((OPTIND-1))

VM_GROUP_ID=$(group2num $SI2_GROUP)
: ${VM_USER:=si2}
: ${VM_HOST:=10.$VM_GROUP_ID.$SI2_PAIR.$SI2_VM}
: ${VM_USER_HOST:="$VM_USER@$VM_HOST"}
: ${VM_J2EE:=/opt/glassfish4/glassfish}

## ----------------------------------------------------------------------------

cmd__init() {
	INFO "Configurando la interfaz eth0:0 para el host"
	INFO "Se requiere la constraseña del usuario $(whoami)."
	sudo /opt/si2/virtualip.sh eth0

	if ! grep '^pref.vmplayer.exit.vmAction' ~/.vmware/preferences > /dev/null 2>&1; then
		INFO "Configurando preferencias locales de vmware."
		INFO "Se permite cerrar el vmplayer sin que se apague la maquina virtual"
		cat >> ~/.vmware/preferences <<-EOF
		pref.vmplayer.exit.vmAction = "disconnect"
		hints.hideAll = "TRUE"
		msg.noOk = "TRUE"
		EOF
	fi

	INFO 'Preparando una identidad para las conexiones ssh con certificado'
	ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ''
	ssh-add

}

cmd__setup() {
	ping -c1 "$VM_HOST" > /dev/null 2>&1 || abort 'No se pudo conectar con la maquina virtual'

	INFO "Copiando la identidad a la maquina virtual $VM_USER_HOST."
	INFO "Se requiere la contraseña del usuario $VM_USER"
	ssh-copy-id "$VM_USER_HOST"

	cat <<-EOF | ssh "$VM_USER_HOST" 'cat > .bash_profile'
	force_color_prompt=true
	source ~/.bashrc

	export J2EE_HOME="$VM_J2EE"
	export PATH="$PATH:\$J2EE_HOME/bin"

	alias ..='cd ..'
	export LS_COLORS='*~=37:di=34:fi=0:ln=32:pi=5:so=33:bd=33:cd=33:or=92:mi=92:ex=31'
	alias l='ls -F --color'
	alias ll='l -Ghal'
	EOF

	cmd__asadmin start-domain domain1
}

cmd__ant()      { J2EE_HOME='/usr/local/glassfish-4.1.1/glassfish' ant "$@";               }
cmd__psql()     { ssh -t $VM_USER_HOST 'psql -U alumnodb visa';                            }
cmd__ssh()      { ssh "$VM_USER_HOST" "$@";                                                }
cmd__upload()   { scp "$1" "$VM_USER_HOST:${2:-/home/si2}";                                }
cmd__download() { scp "$VM_USER_HOST:$1" "${2:-.}";                                        }
cmd__asadmin()  { ssh $VM_USER_HOST "$VM_J2EE/bin/asadmin $*";                             }
cmd__log()      { ssh $VM_USER_HOST "cat $VM_J2EE/domains/domain1/logs/server.log" | less; }

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
	show_help() {
		local length=$((3 + ${#1}))
		echo -n "   $BOLD$1$NORMAL"
		while shift; do
			if [[ "$1" == '--' ]]; then
				shift; printf ' %.0s' $(seq 1 $((35-$length))); echo "$1"
				return 0
			fi
			if [[ "$1" == @* ]]; then
				((length += 2 + ${#1}))
				echo -n " [$UNDER${1:1}$NORMAL]"
			else
				((length += 1 + ${#1}))
				echo -n " $UNDER$1$NORMAL"
			fi
		done
	}

	echo "uso: $BOLD$exe$NORMAL <comando> [<argumentos>]"
	echo ""
	echo "Los subcomandos validos son:"
	show_help 'init'                            -- 'Configura la maquina local.'
	show_help 'setup'                           -- 'Configura una maquina virtual.'
	show_help 'ant' 'cmd'                       -- 'Ejecuta un comando ant con el $J2EE_HOME correcto'
	show_help 'psql'                            -- 'Abre una sesion psql con la base de datos del servidor.'
	show_help 'ssh' '@cmd'                      -- 'Se conecta via ssh o ejecuta un comando remotamente.'
	show_help 'upload' 'path_host' '@path_vm'   -- 'Copia archivos de host -> vm.'
	show_help 'download' 'path_vm' '@path_host' -- 'Copia archivos de vm   -> host.'
	show_help 'asadmin' 'cmd'                   -- 'Ejecuta un comando con asadmin.'
	show_help 'log'                             -- 'Muestra el log de Glassfish.'
	show_help 'help'                            -- 'Muestra esta ayuda.'
}

## ----------------------------------------------------------------------------

exe="$(basename "$0")"
cmd="cmd__${1:-help}"

## Comprobamos que exista el subcomando como funcion
if [[ "$(type -t "$cmd")" != 'function' ]]; then
	abort "$exe: '$1' no es un comando valido. Vease '$exe help'"
fi

## shift devuelve 1 si no hay mas parametros posicionales
shift || true
"$cmd" "$@"
exit 0
