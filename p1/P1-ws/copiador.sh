#!/bin/sh

set -e

cp() {
	command cp -v "$@"
}

cp -r ../P1-base/datagen .
cp -r ../P1-base/sql .
cp -r ../P1-base/web .

cp -r ../P1-base/postgresql.properties .
cp -r ../P1-base/postgresql.xml .

cp_server() {
	local DST
	DST="${2:-./src/server/ssii2/$1}"
	mkdir -p "$(dirname "$DST")"
	cp -r "../P1-base/src/ssii2/$1" "$DST"
}
cp_client() {
	local DST
	DST="${2:-./src/client/ssii2/$1}"
	mkdir -p "$(dirname "$DST")"
	cp -r "../P1-base/src/ssii2/$1" "$DST"
}


cp_client visa/error/
cp_client visa/ValidadorTarjeta.java
cp_client filtros/CompruebaSesion.java
cp_client controlador/ComienzaPago.java
cp_client controlador/GetPagos.java
cp_client controlador/DelPagos.java
cp_client controlador/ServletRaiz.java
cp_client controlador/ProcesaPago.java
cp_server visa/dao/DBTester.java ./src/server/ssii2/visa/DBTester.java
cp_server visa/PagoBean.java
cp_server visa/TarjetaBean.java

cp ../P1-base/postgresql-jdbc4.jar .

# Cositas extras que no vienen en el enunciado
cp_client ../P1-base/src/ssii2/visa/PagoBean.java
cp_client ../P1-base/src/ssii2/visa/TarjetaBean.java
find src/client/ssii2 -type f -print0 | xargs -0 sed -i 's/VisaDAO/VisaDAOWS/g'

if [[ -f './src/server/ssii2/visa/VisaDAOWS.java' ]];
	echo "$(tput setaf 1) - ACHTUNG!!! - $(tput sgr0)"
	echo 'No se ha copiado /src/server/ssii2/visa/VisaDAOWS.java'
	echo 'para que no se sobreescriba trabajo sin querer'
else
	cp_server visa/dao/VisaDAO.java ./src/server/ssii2/visa/VisaDAOWS.java
fi