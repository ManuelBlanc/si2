#!/usr/bin/env bash

GRUPO=2401
PAREJA=11
PC=1

{ # Nuevo contexto

# Activamos la sanidad
set -eu
# Formateo
NORMAL=$(tput sgr0)
BOLD=$(tput bold)
# Utilidades
INFO()  { echo "==> $BOLD$1$NORMAL"; }

## Vamos al directorio donde esta este script
cd "$( dirname "${BASH_SOURCE[0]}" )"

## Descomprimimos la maquina virtual (si no esta descomprimida)
[ -d si2srv/ ] || tar xvzf si2srv.tgz

## Ejecutamos el fichero de configuracion de MAC
(cd si2srv/ && ./si2fixMAC.sh $GRUPO $PAREJA $PC)

## Permitimos cerrar la maquina virtual y que siga corriendo
echo 'pref.vmplayer.exit.vmAction = "disconnect"' >> ~/.vmware/preferences

## Asignamos la interfaz eth0:0 a la maquina virtual
sudo /opt/si2/virtualip.sh eth0

VIRTUAL_IP="$(/sbin/ifconfig eth0:0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')"

## Y arrancamos la maquina virtual
(cd si2srv/ && vmplayer ./si2srv.vmx)

ssh "si2@$VIRTUAL_IP"

}
