#!/usr/bin/env bash

#= si2tool [-g @num] [-p @num] [-m @num] @cmd [@args @...]
#= Conjunto de utilidades para SI2.
#=
#= Este script contiene una serie de metodos para 
#= Se puede especificar el grupo con -g @num
#= Se puede especificar el numero de pareja con con -p @num
#= Se puede especificar la maquina con -m @num

# ESPECIAL: Si se ejecuta con source nos instalamos como comando
# en el entorno actual.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
	export J2EE_HOME='/usr/local/glassfish-4.1.1/glassfish'
	echo "export J2EE_HOME=$J2EE_HOME"
	alias si2tool="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/si2tool.sh"
	alias si2tool
	return 0
fi

# ----------------------------------------------------------------------------

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

# Traduce un codigo de grupo a un entero
group2num() {
	case "$1" in
		2401) echo 1 ;; 2311) echo 4 ;; 2361) echo 7 ;;
		2402) echo 2 ;; 2312) echo 5 ;; 2362) echo 8 ;;
		2403) echo 3 ;; 2313) echo 6 ;; 2363) echo 9 ;;
		*) abort "group2num: $1 es un numero de grupo invalido" ;;
	esac
}

# Constantes de configuracion
: ${SI2_GROUP:=2401}
: ${SI2_PAIR:=11}
: ${SI2_VM:=1}

# Permitimos leer opciones que especifiquen grupo, etc.
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

# ----------------------------------------------------------------------------

#= help [@cmd]
#= Muestra la ayuda de un comando, o de todos.
#= La informacion se extrae del propio fichero usando codigo Perl ilegible.
cmd__help() {
	if ! type perl > /dev/null; then
		abort 'La ayuda usa perl. Abre el fichero directamente para ver los comentarios.'
	fi
	if [[ ${#@} -eq 0 ]]; then
		echo "uso: $BOLD$exe$NORMAL <comando> [<argumentos>]"
		echo ""
		echo "Los subcomandos validos son:"
		perl -lane '
			sub bold { `tput bold`.$_[0].`tput sgr0` }
			next unless (/^#=/);
			#next unless $. > 70;
			printf "   %-20s %s", (bold $F[1]), (<> =~ s/^#=\s+//r);
			while (<> =~ /^#=/) {};
		' "${BASH_SOURCE[0]}"
	else
		perl -wlane '
			$\="\n";
			sub under { `tput smul`.$_[0].`tput rmul` }
			sub bold  { `tput bold`.$_[0].`tput sgr0` }
			sub formatize {
				$_[0] =~ s/@([\w.-]+)/under $1/ge;
				$_[0] =~ s/((?:^|\s|(?<=\[))-[\w.-]+)/bold $1/ge;
				return $_[0];
			}
			next unless (/^#= \Q'$1'/);
			shift @F;
			$cmd = bold shift @F;
			chomp($des = ($_ = <>) =~ s/^#=\s+//r);
			print bold "NAME";
			print "   $cmd -- $des\n";
			print bold "SYNOPSIS";
			print "   $cmd ", join " ", (map { formatize $_ } @F), "\n";
			print bold "DESCRIPTION";
			while (($_ = <>) =~ s/^#=\s+//) {
				chomp; next if /^$/; print "   ", formatize $_;
			}
			$found = 1;
			exit 0;
			END { print "Ayuda no encontrada." unless $found; }
		' "${BASH_SOURCE[0]}" | less
	fi
}

#= init
#= Configura la maquina local.
#= + Ejecuta el script /opt/si2/virtualip.sh.
#= + Añade preferencias utiles a ~/.vmware/preferences
#= + Prepara un certificado para uso con ssh
cmd__init() {
	INFO "Configurando la interfaz eth0:0 para el host"
	INFO "Se requiere la constraseña del usuario $(whoami)."
	sudo /opt/si2/virtualip.sh eth0

	# Usamos como heuristica para ver si se han añadido las opciones adicionales
	# ver si esta una clave especifica en el fichero.
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

#= fixmac
#= Arregla la MAC de una maquina virtual.
#= Se genera a partir del grupo, pareja y numero de ordenador.
cmd_fixmac() {
	perl -i.orig -lane '
	if s/^ethernet0\.address/ {
		printf "%s = \"00:50:56:%s:%02x:%02x\"\n", $1, a1, pareja, PC;
	}
	elsif s/^ethernet1\.address/ {
		printf ("%s = \"00:50:56:%02x:%s:%02x\"\n", $1, pareja, a1, PC);
	}
	else {
		print;
	}
	' si2srv.vmx
}

#= setup
#= Configura una maquina virtual.
#= + Copia el certificado ssh (si existe) a la maquina virtual.
#= + Crea un .bash_profile remotamente con cosas utiles.
#= + Arranca el domain1 con asadmin.
cmd__setup() {
	ping -c1 "$VM_HOST" > /dev/null 2>&1 || abort 'No se pudo conectar con la maquina virtual'

	if [[ -f ~/.ssh/id_rsa ]]; then
		INFO "Copiando la identidad a la maquina virtual $VM_USER_HOST."
		INFO "Se requiere la contraseña del usuario $VM_USER"
		ssh-copy-id "$VM_USER_HOST"
	fi

	# Usamos una combinacion de cat y ssh para escribir un fichero remotamente.
	# Se hace esto en vez de usar scp porque el "fichero" de origen es un heredoc.
	cat <<-EOF | ssh "$VM_USER_HOST" 'cat > .bash_profile'
	# Cargamos tambien el .bashrc (con colores!)
	force_color_prompt=true
	source ~/.bashrc

	# Variables de configuracion para Glassfish
	export J2EE_HOME="$VM_J2EE"
	export PATH="$PATH:\$J2EE_HOME/bin"

	# Algunos aliases utiles
	alias ..='cd ..'
	export LS_COLORS='*~=37:di=34:fi=0:ln=32:pi=5:so=33:bd=33:cd=33:or=92:mi=92:ex=31'
	alias l='ls -F --color'
	alias ll='l -Ghal'
	EOF

	# Arrancamos el dominio
	cmd__asadmin start-domain domain1
}

#= ant @cmd
#= Ejecuta un comando ant con el $J2EE_HOME correcto.
cmd__ant() { J2EE_HOME='/usr/local/glassfish-4.1.1/glassfish' ant "$@"; }

#= psql [@db]
#= Abre una sesion psql con la base de datos del servidor.
#= La base de datos por defecto (valor de @db) es 'visa'.
cmd__psql() {
	ssh -t $VM_USER_HOST 'psql -U alumnodb visa';
}

#= ssh [@cmd]
#= Abre una conexion ssh con la maquina virtual.
#= Si se especifica un comando, se ejecuta en vez de abrir una sesion interactiva.
cmd__ssh() { ssh "$VM_USER_HOST" "$*"; }

#= upload @path-host [@path-vm]
#= Sube un fichero a la maquina virtual
#= El valor de @path-vm por defecto es ~/home/si2
cmd__upload() { scp "$1" "$VM_USER_HOST:${2:-/home/si2}"; }

#= download @path-vm [@path-host]
#= Descarga un fichero de la maquina virtual.
#= El valor de @path-host por defecto es . (directorio actual)
cmd__download() { scp "$VM_USER_HOST:$1" "${2:-.}"; }

#= asadmin @cmd
#= Ejecuta un comando con asadmin.
cmd__asadmin() { cmd__ssh "$VM_J2EE/bin/asadmin $*"; }

#= log
#= Muestra el log de Glassfish.
cmd__log() { ssh $VM_USER_HOST "cat $VM_J2EE/domains/domain1/logs/server.log" | less +G; }

#= jakarta
#= Se descarga Jakarta JMeter de la maquina virtual
cmd__jakarta() {
	scp "$VM_USER_HOST:/opt/SI2/jakarta-jmeter.tgz" ~/Desktop
	cd ~/Desktop
	tar xzvf jakarta-jmeter.tgz
}

#= info
#= Muestra el valor de varias variables de configuracion.
cmd__info() {
	if_ip() { ifconfig "$1" | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'; }
	print_var() { printf "${BOLD}%-16s${NORMAL} = %s\n" "$1" "$2"; }
	set +e
	print_var 'user@host'    "$(whoami)@$(hostname)"
	print_var 'eth0:0 inet'  "$(if_ip eth0:0 2>&1)"
	print_var 'vmnet1 inet'  "$(if_ip vmnet1 2>&1)"
	print_var 'vmnet8 inet'  "$(if_ip vmnet8 2>&1)"
	print_var 'SI2_GROUP'    "$SI2_GROUP"
	print_var 'SI2_PAIR'     "$SI2_PAIR"
	print_var 'SI2_VM'       "$SI2_VM"
	print_var 'VM_USER'      "$VM_USER"
	print_var 'VM_HOST'      "$VM_HOST"
	print_var 'VM_USER_HOST' "$VM_USER_HOST"
	print_var 'VM_J2EE'      "$VM_J2EE"
	print_var 'J2EE_HOME'    "$J2EE_HOME"
}

# ----------------------------------------------------------------------------

exe="$(basename "$0")"
cmd="cmd__${1:-help}"

# Comprobamos que exista el subcomando como funcion
if [[ "$(type -t "$cmd")" != 'function' ]]; then
	abort "$exe: '$1' no es un comando valido. Vease '$exe help'"
fi

# shift devuelve 1 si no hay mas parametros posicionales
shift || true
"$cmd" "$@"
exit 0