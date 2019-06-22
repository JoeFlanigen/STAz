#!/bin/bash -e
set -e

. ./config/config_eng.sh
. ./scripts/app_gateway.sh
. ./scripts/network.sh
. ./scripts/resource_group.sh
. ./scripts/scale_set.sh
. ./scripts/vms.sh

# Sign in on the command line with this command or uncomment this line
# az login

create_resource_group

echo "CREATING NETWORK"

create_vnet $VNET_NAME $VNET_IP

create_subnet $ADMIN_SUBNET_NAME $ADMIN_SUBNET_IP
create_subnet $GATEWAY_SUBNET_NAME $GATEWAY_SUBNET_IP
create_subnet $WORKER_SUBNET_NAME $WORKER_SUBNET_IP

echo "CREATING JUMPBOX"
create_admin_vm "10.2.1.5"

echo "CREATING WORKER VMs"
create_worker_vm Standard_D4s_v3 "$PREFIX-eng-01-vm" "10.2.2.10" 80 40 100 # FRONT END - zk, Solr, Tomcat
create_worker_vm Standard_D4s_v3 "$PREFIX-eng-02-vm" "10.2.2.11" 80 40 100 # FRONT END - zk, Solr, Tomcat
create_worker_vm Standard_D4s_v3 "$PREFIX-eng-03-vm" "10.2.2.12" 80 40 100 # FRONT END - zk, Solr, Tomcat
# create_worker_vm Standard_D4s_v3 "$PREFIX-eng-04-vm" "10.2.2.13" 80 40 100 # ActiveMQ
# # create_worker_vm Standard_D4s_v3 "$PREFIX-eng-05-vm" "10.2.2.14" 80 40 400 # Solr, MongoDB
# # create_worker_vm Standard_D4s_v3 "$PREFIX-eng-06-vm" "10.2.2.15" 80 40 100 # seed, Solr, Tomcat
# # create_worker_vm Standard_D4s_v3 "$PREFIX-eng-07-vm" "10.2.2.16" 80 40 100 # Solr, Tomcat
# # create_worker_vm Standard_D8s_v3 "$PREFIX-eng-08-vm" "10.2.2.17" 32 40 400 # Nuance
# # create_worker_vm Standard_DS1_v2 "$PREFIX-eng-09-vm" "10.2.2.18" 32 40 # nagios, nrpe

echo "OPENING VM PORTS"
open_vm_inbound_ports "$PREFIX-eng-01-vm" 350 80 8080 8009 8005 2181 8983 7983 2888 3888
open_vm_inbound_ports "$PREFIX-eng-02-vm" 350 80 8080 8009 8005 2181 8983 7983 2888 3888
open_vm_inbound_ports "$PREFIX-eng-03-vm" 350 80 8080 8009 8005 2181 8983 7983 2888 3888
# open_vm_inbound_ports "$PREFIX-eng-04-vm" 350 1802 1801 1099 2099 8161
# # open_vm_inbound_ports "$PREFIX-eng-05-vm" 350 8983 7983 27017
# # open_vm_inbound_ports "$PREFIX-eng-06-vm" 350 8983 7983 8080 8009 8005
# # open_vm_inbound_ports "$PREFIX-eng-07-vm" 350 8983 7983 8080 8009 8005
# # open_vm_inbound_ports "$PREFIX-eng-09-vm" 350 5666

echo "OPENING NSG PORTS"
open_nsg_inbound_ports "$PREFIX-eng-01-vm-nsg" 300 80 8080 8009 8005 2181 8983 7983 2888 3888 # FRONT END - zk, Solr, Tomcat
open_nsg_inbound_ports "$PREFIX-eng-02-vm-nsg" 300 80 8080 8009 8005 2181 8983 7983 2888 3888 # FRONT END - zk, Solr, Tomcat
open_nsg_inbound_ports "$PREFIX-eng-03-vm-nsg" 300 80 8080 8009 8005 2181 8983 7983 2888 3888 # FRONT END - zk, Solr, Tomcat
# open_nsg_inbound_ports "$PREFIX-eng-04-vm-nsg" 300 1802 1801 1099 2099 8161 # ActiveMQ
# # open_nsg_inbound_ports "$PREFIX-eng-05-vm-nsg" 300 8983 7983 27017 # Solr, MongoDB
# # open_nsg_inbound_ports "$PREFIX-eng-06-vm-nsg" 300 8983 7983 8080 8009 8005 # seed, Solr, Tomcat
# # open_nsg_inbound_ports "$PREFIX-eng-07-vm-nsg" 300 8983 7983 8080 8009 8005 # Solr, Tomcat
# # # open_nsg_inbound_ports "$PREFIX-eng-08-vm-nsg" # don't know
# # open_nsg_inbound_ports "$PREFIX-eng-09-vm-nsg" 300 5666 # nagios, nrpe

create_app_gateway_cli
# create_app_gateway_template