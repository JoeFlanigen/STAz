#!/bin/bash

create_admin_vm() {

    local private_ip_address=$1
    
    local vm_name="${PREFIX}AdminVm"

    echo ">>>>>>>> CREATING ADMIN MACHINE $vm_name <<<<<<<<<<<"

    az vm create \
        --admin-username $VM_ADMIN_UID \
        --authentication-type ssh \
        --data-disk-sizes-gb 32 100 \
        --image CentOS \
        --generate-ssh-keys \
        --name $vm_name \
        --nsg "${vm_name}Nsg" \
        --nsg-rule SSH \
        --os-disk-name "${vm_name}Os" \
        --os-disk-size-gb 32 \
        --output table \
        --private-ip-address $private_ip_address \
        --public-ip-address-allocation static \
        --public-ip-sku Standard \
        --resource-group $RESOURCE_GROUP_NAME \
        --subnet $ADMIN_SUBNET_NAME \
        --vnet-name $VNET_NAME \
        || (echo "FAILED TO CREATE VM: $vm_name" && exit 1)

    echo ">>>>>>>> CREATED ADMIN VM: $vm_name <<<<<<<<<<<"
}

create_test_worker_vm() {

    echo ">>>>>>>> CREATING TEST WORKER MACHINE <<<<<<<<<<<"

    local private_ip_address=$1
    local vm_name=$2

    az vm create \
        --admin-username $VM_ADMIN_UID \
        --authentication-type ssh \
        --data-disk-sizes-gb 40 100 \
        --image CentOS \
        --name $vm_name \
        --nsg "${vm_name}Nsg" \
        --nsg-rule SSH \
        --os-disk-name "${vm_name}Os" \
        --os-disk-size-gb 80 \
        --output table \
        --public-ip-address "" \
        --private-ip-address $private_ip_address \
        --resource-group $RESOURCE_GROUP_NAME \
        --size Standard_DS2_v2 \
        --subnet $WORKER_SUBNET_NAME \
        --vnet-name $VNET_NAME  \
        || (echo "FAILED TO CREATE VM: $vm_name" && exit 1)

    echo ">>>>>>>> CREATED TEST WORKER MACHINE $vm_name <<<<<<<<<<<"
}

create_worker_vm() {

    echo ">>>>>>>> CREATING WORKER MACHINE <<<<<<<<<<<"

    local vm_size=$1
    local vm_name=$2
    local vm_ip=$3
    local os_disk_size=$4
    local app_disk_size=$5
    local svr_disk_size=$6

    local os_disk_name="${vm_name}Os"

    echo "CREATING VM: $vm_name"

    echo "IP: $vm_name-ip"

    az vm create \
        --admin-username $VM_ADMIN_UID \
        --authentication-type ssh \
        --data-disk-sizes-gb $app_disk_size $svr_disk_size \
        --image CentOS \
        --name $vm_name \
        --nsg "${vm_name}Nsg" \
        --nsg-rule SSH \
        --os-disk-name "${vm_name}Os" \
        --os-disk-size-gb $os_disk_size \
        --output table \
        --public-ip-address "" \
        --private-ip-address $vm_ip \
        --resource-group $RESOURCE_GROUP_NAME \
        --size $vm_size \
        --subnet $WORKER_SUBNET_NAME \
        --vnet-name $VNET_NAME  \
        || (echo "FAILED TO CREATE VM: $vm_name" && exit 1)

    echo ">>>>>>>> CREATED WORKER MACHINE $vm_name <<<<<<<<<<<"
}

open_nsg_inbound_ports() {
    
    local nsg_name=$1
    local priority=$2
    
    echo "OPENING INBOUND NSG PORTS: $nsg_name"

    for i in "${@:3}"
    do
        echo "Opening inbound port: $i"

        az network nsg rule create \
            --access Allow \
            --destination-port-range $i \
            --direction Inbound \
            --name "open${i}" \
            --nsg-name $nsg_name \
            --priority $priority \
            --protocol tcp \
            --resource-group $RESOURCE_GROUP_NAME \
            || (echo "FAILED TO CREATE NSG Rule: $nsg_name" && exit 1)
        
         ((priority++))
    done
}

open_vm_inbound_ports() {
    
    local vm_name=$1
    local priority=$2
    
    echo "OPENING INBOUND VM PORTS: $vm_name"

    for i in "${@:3}"
    do
        echo "Opening inbound port: $i"

        az vm open-port \
            --port $i \
            --name $vm_name \
            --nsg-name "${vm_name}Nsg" \
            --priority $priority \
            --resource-group $RESOURCE_GROUP_NAME \
            || (echo "FAILED TO CREATE VM RULE: $vm_name" && exit 1)
        
         ((priority++))
    done
}

