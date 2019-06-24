#!/bin/bash -e

create_subnet() {
    
    local subnet_name=$1
    local address_prefix=$2

    echo "CREATING SUBNET $subnet_name"

    az network vnet subnet create \
        --name $subnet_name \
        --resource-group $RESOURCE_GROUP_NAME \
        --address-prefixes $address_prefix \
        --vnet-name $VNET_NAME \
        || (echo "FAILED TO CREATE SUBNET: $subnet_name" && exit 1)

    

    echo "CREATED SUBNET $subnet_name"
}

create_vnet () {

    echo "CREATING VNET $VNET_NAME"

    az network vnet create \
        --name $VNET_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --address-prefixes $VNET_IP \
        --location $LOCATION \
         || (echo "FAILED TO CREATE $vnet_name" && exit 1)

    echo "CREATED VNET $VNET_NAME"
}

create_public_ip() {

    local pip_name=$1
    
    echo "CREATING PUBLIC IP"

    az network public-ip create \
        --name $pip_name \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --allocation-method Static \
        --sku Standard

    az network public-ip show -g $RESOURCE_GROUP_NAME -n $pip_name

    echo "CREATED PUBLIC IP: ${public_ip_name}"
}
