#!/bin/bash

create_admin_vm() {

    local private_ip_address=$1
    
    local vm_name="$PREFIX-admin-vm"

    echo ">>>>>>>> CREATING ADMIN MACHINE $vm_name <<<<<<<<<<<"

    az vm create \
        --admin-username $VM_ADMIN_UID \
        --authentication-type ssh \
        --data-disk-sizes-gb 32 100 \
        --image CentOS \
        --generate-ssh-keys \
        --name $vm_name \
        --nsg "$vm_name-nsg" \
        --nsg-rule SSH \
        --os-disk-name "$vm_name-os" \
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
        --nsg "$vm_name-nsg" \
        --nsg-rule SSH \
        --os-disk-name "$vm_name-os" \
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

    local os_disk_name="$vm_name-os"

    echo "CREATING VM: $vm_name"

    echo "IP: $vm_name-ip"

    az vm create \
        --admin-username $VM_ADMIN_UID \
        --authentication-type ssh \
        --data-disk-sizes-gb $app_disk_size $svr_disk_size \
        --image CentOS \
        --generate-ssh-keys \
        --name $vm_name \
        --nsg "$vm_name-nsg" \
        --nsg-rule SSH \
        --os-disk-name "$vm_name-os" \
        --os-disk-size-gb $os_disk_size \
        --output table \
        --public-ip-address "" \
        --private-ip-address $vm_ip \
        --resource-group $RESOURCE_GROUP_NAME \
        --size $1 \
        --subnet $WORKER_SUBNET_NAME \
        --vnet-name $VNET_NAME  \
        || (echo "FAILED TO CREATE VM: $vm_name" && exit 1)

    echo ">>>>>>>> CREATED WORKER MACHINE $vm_name <<<<<<<<<<<"
}

attach_disk() {

    local disk_sku=$1
    local disk_name=$2
    local vm_name=$3
    local disk_capacity=$4

    echo "ATTACHING DISK: $disk_name"

    az vm disk attach \
        --name $disk_name \
        --resource-group $RESOURCE_GROUP_NAME \
        --size-gb $disk_capacity \
        --sku $disk_sku \
        --vm-name $vm_name \
        --new  \
        || (echo "FAILED TO ATTACH DISK: $vm_name" && exit 1)

    echo "DISK ATTACHED: $disk_name"

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
            --name "open_$i" \
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
            --nsg-name "$vm_name-nsg" \
            --priority $priority \
            --resource-group $RESOURCE_GROUP_NAME \
            || (echo "FAILED TO CREATE VM RULE: $vm_name" && exit 1)
        
         ((priority++))
    done
}

# open_inbound_ports() {
    
#     local vm_name=$1
#     local ip_address=$2
    
#     local priority=350
#     local nsg_name="$vm_name-nsg"
        
#     for i in "${@:2}"
#     do

#         echo "CREATING INBOUND NSG: $nsg_name + "
#         az network nsg create --name $nsg_name --resource-group $RESOURCE_GROUP_NAME
        
#         echo "Opening NSG inbound port: $i"

#         az network nsg rule create \
#             --access Allow \
#             --destination-port-range $i \
#             --direction Inbound \
#             --name $vm_name \
#             --nsg-name $nsg_name \
#             --priority $priority \
#             --protocol tcp \
#             --resource-group $RESOURCE_GROUP_NAME \
#             || (echo "FAILED TO CREATE NSG Rule: $nsg_name" && exit 1)

#         ((priority++))

#         echo "OPENING INBOUND VM PORT: $i"
        
#         az vm open-port \
#             --name $vm_name \
#             --nsg-name $nsg_name \
#             --priority $priority \
#             --port $i \
#             --resource-group $RESOURCE_GROUP_NAME \
#             || (echo "FAILED TO CREATE VM RULE: $vm_name" && exit 1)

#         ((priority++))
#     done
# }

