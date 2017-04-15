#!/bin/bash
#set -o errexit -o pipefail


RESOURCE_GROUP=linux-group
LOCATION=centralus
AV=WebAVSet
NSG=AppsNSG
VNET=WebVNET
ADDRESS_RANGE=10.10.0.0/16
SUBNET=Apps
SUBNET_RANGE=10.10.0.0/24
LB=WebLB
PROBE=WebLB-Probe
IMG=UbuntuLTS
SIZE=Standard_DS1_v2


if [[ ! $1 ]]; then
    echo "\$1 Argument required for Virtual Machine Name"
	exit 1
fi

VM=$1
NIC=$VM-NIC
IP=$VM-IP


###############################
#### RESOURCE GROUP SETUP #####
###############################

tput setaf 6; echo 'RESOURCE GROUP SETUP: ' ${RESOURCE_GROUP}; tput sgr0	
az group create -n ${RESOURCE_GROUP} \
	--location ${LOCATION}

################################################################################



########################
#### NETWORK SETUP #####
########################

tput setaf 6; echo 'NETWORK SETUP: ' ${VNET}; tput sgr0	
az network vnet create -g ${RESOURCE_GROUP} -n ${VNET} \
	--address-prefix ${ADDRESS_RANGE}	\
	--subnet-name ${SUBNET} \
	--subnet-prefix ${SUBNET_RANGE}
tput setaf 3; echo 'CREATE: *** PUBLIC IP ***'; tput sgr0	
az network public-ip create -g ${RESOURCE_GROUP} -n ${IP}


# OPTIONAL -->  Secondary SUBNET
SUBNET2=Data
SUBNET2_RANGE=10.10.1.0/24

tput setaf 4; echo 'CREATE:  *** Data SubNet ***' ${VNET}; tput sgr0
az network vnet subnet create -g ${RESOURCE_GROUP} -n ${SUBNET2} \
	--vnet-name ${VNET} \
	--address-prefix ${SUBNET2_RANGE} \
	--network-security-group ${NSG}

################################################################################




##############################
#### LOAD BALANCER SETUP #####
##############################


#tput setaf 6; echo 'LOAD BALANCER SETUP: ' ${NSG}; tput sgr0
#az network public-ip create -g ${RESOURCE_GROUP} -n ${LB}-VIP
#az network lb create -g ${RESOURCE_GROUP} -n ${LB} \
#	--location ${LOCATION} \
#	--public-ip-address ${LB}-VIP --frontend-ip-name ${LB}-FE
#tput setaf 3; echo 'CREATE: *** HEALTH PROBE ***'; tput sgr0	
#az network lb probe create -g ${RESOURCE_GROUP} -n ${PROBE} \
#	--lb-name ${LB} \
#	--protocol http \
#	--port 80 \
#	--path / \
#	--interval 15 \
#	--threshold 4

################################################################################




#########################
#### FIREWALL SETUP #####
#########################

tput setaf 6; echo 'NETWORK SECURITY GROUP SETUP: ' ${NSG}; tput sgr0	
az network nsg create -g ${RESOURCE_GROUP} -n ${NSG}
tput setaf 3; echo 'CREATE: *** HTTP RULE ***'; tput sgr0	
az network nsg rule create -g ${RESOURCE_GROUP} \
    --nsg-name ${NSG} --name HTTP \
    --protocol tcp --direction inbound --priority 1000 \
    --source-address-prefix '*' --source-port-range '*' \
    --destination-address-prefix '*' --destination-port-range 80 --access allow
tput setaf 3; echo 'CREATE: *** HTTPS RULE ***'; tput sgr0	
az network nsg rule create -g ${RESOURCE_GROUP} \
    --nsg-name ${NSG} --name HTTPS \
    --protocol tcp --direction inbound --priority 1010 \
    --source-address-prefix '*' --source-port-range '*' \
    --destination-address-prefix '*' --destination-port-range 443 --access allow

################################################################################




#############################
#### NETWORK CARD SETUP #####
#############################

tput setaf 6; echo 'NETWORK CARD SETUP: ' ${NIC}; tput sgr0	
az network nic create -g ${RESOURCE_GROUP} -n ${NIC} \
	--vnet-name ${VNET} \
	--subnet ${SUBNET} \
	--network-security-group ${NSG} \
	--public-ip-address ${IP}

################################################################################




#############################
#### AVAILABILITY SETUP #####
#############################

tput setaf 6; echo 'AVAILABILITY SET SETUP: ' ${RESOURCE_GROUP}; tput sgr0	
az vm availability-set create -g ${RESOURCE_GROUP} -n ${AV} \
	--location ${LOCATION} \
	--platform-update-domain-count 5 \
	--platform-fault-domain-count 2

################################################################################




################################
#### VIRTUAL MACHINE SETUP #####
################################

tput setaf 6; echo 'VIRTUAL MACHINE SETUP: ' ${VM}; tput sgr0	
az vm create -g ${RESOURCE_GROUP} -n ${VM} --generate-ssh-keys \
	--location ${LOCATION} \
	--image ${IMG} \
	--size ${SIZE} \
	--nics ${NIC} \
	--availability-set ${AV}
tput setaf 3; echo 'INSTALL: *** Docker Extension ***'; tput sgr0	
az vm extension set \
	--resource-group ${RESOURCE_GROUP} \
	--vm-name ${VM} \
	--name DockerExtension \
	--publisher Microsoft.Azure.Extensions \
	--version 1.1 \
	--settings '{"docker": {"port": "2375"}}'
tput setaf 3; echo 'OPEN:  *** PORT 22 ***'; tput sgr0
az vm open-port --port 22 -g ${RESOURCE_GROUP} \
	--name ${VM}

################################################################################

tput setaf 5;echo 'run ./connect.sh' ${VM} 'to ssh into your machine'; tput sgr0
