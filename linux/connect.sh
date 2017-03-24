#!/bin/bash
#set -o errexit -o pipefail

if [[ ! $1 ]]; then
    echo "no hostname argument passed"
	exit 1
fi

if [[ $2 ]]; then
	USER=$2
fi

HOST=$1

#////////////////////////////////
echo 'Retrieving IP Address for' $HOST

IP=$(az vm list-ip-addresses -n $HOST | jq -r ".[] | .virtualMachine.network.publicIpAddresses[].ipAddress")

echo 'Connecting to' $USER@$IP

ssh -i ~/.ssh/id_rsa $USER@$IP -A
