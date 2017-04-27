#!/usr/bin/env bash

set -eu

ssh si2@10.1.11.1 <<EOF
scp proxy_balancer.conf si2@10.1.11.1:/etc/apache2/mods-available/
EOF

ssh si2@10.1.11.1 <<'EOF'
scp 
EOF

export AS_ADMIN_USER=admin
export AS_ADMIN_PASSWORDFILE=/opt/SI2/passwordfile

asadmin start-domain

asadmin create-node-ssh --sshuser si2 --nodehost si2srv02 --nodedir /opt/glassfish4 Node01
asadmin create-node-ssh --sshuser si2 --nodehost si2srv03 --nodedir /opt/glassfish4 Node02
asadmin list-nodes

asadmin create-cluster SI2Cluster
asadmin list-clusters

asadmin create-instance --cluster SI2Cluster --node Node01 Instance01
asadmin create-instance --cluster SI2Cluster --node Node02 Instance02

asadmin list-instances -l
asadmin start-cluster SI2Cluster

asadmin delete-jvm-options --target SI2Cluster -server:-client:-Xmx512m:-XX\\:MaxPermSize=192m
asadmin create-jvm-options --target SI2Cluster -server:-Xms128m:-Xmx128m:-XX\\:MaxPermSize=96m
asadmin stop-domain
asadmin start-domain

EOF