#!/bin/sh 
 
if [ $# -ne 3 ]; then 
  echo $0 " grupo pareja PC"; 
  exit 1; 
fi 
 
if [ ! -f "si2srv.vmx.bak" ]; then 
  echo "No existe si2srv.vmx.bak"; 
  exit 1; 
fi 
 
cat si2srv.vmx.bak |  
awk -vgrupo=$1 -vpareja=$2 -vPC=$3 -F"=" ' 
BEGIN{ 
  GRUPOS["2401"]="f1"; 
  GRUPOS["2402"]="f2"; 
  GRUPOS["2403"]="f3"; 
  GRUPOS["2311"]="f4"; 
  GRUPOS["2312"]="f5"; 
  GRUPOS["2313"]="f6"; 
  GRUPOS["2361"]="f7"; 
  GRUPOS["2362"]="f8"; 
  GRUPOS["2363"]="f9"; 
  a1=GRUPOS[grupo];  
  if (a1=="" || pareja < 1 || pareja > 200 || PC <1 || PC >100) exit 1; 
} 
{ 
  if ($1=="ethernet0.address ")  
    printf ("%s = \"00:50:56:%s:%02x:%02x\"\n",$1,a1,pareja,PC); 
  else if ($1=="ethernet1.address ")  
    printf ("%s = \"00:50:56:%02x:%s:%02x\"\n",$1,pareja,a1,PC); 
  else print; 
}' >si2srv.vmx.new 
 
if [ $? != "0" ]; then 
  echo "Error estableciendo MACs"; 
  exit 1; 
fi 
 
mv si2srv.vmx.new si2srv.vmx 

echo "VM configurada con las siguientes MACs"
cat si2srv.vmx | grep "ethernet..address " | grep -v grep 
 
exit 0; 
