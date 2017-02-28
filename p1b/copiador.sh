#!/usr/bin/env bash

set -e

cp -vnr ../p1a/P1-ws/* P1-ejb/
cp -vr P1-ejb-base/* P1-ejb/
rm -vrf P1-ejb/conf/serverws