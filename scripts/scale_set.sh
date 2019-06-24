function create_scale_set() {

    local ss_name=$1
    local subnet_name=$2

    echo "CREATING SCALE SET"

    az vmss create \
        --backend-pool-name $ss_name \
        --custom-data ./declarative_files/cloud-init.yaml
        --data-disk-sizes-gb 32 100 \
        --generate-ssh-keys \
        --image OpenLogic:CentOS:7.5:7.5.20180815 \
        --lb-sku Standard \
        --load-balancer "${PREFIX}Gw" \
        --location $LOCATION \
        --name $ss_name \
        --priority Regular \
        --public-ip-address "" \
        --resource-group $RESOURCE_GROUP_NAME \
        --subnet $subnet_name \
        --upgrade-policy-mode automatic \
        --vm-sku Standard_D4s_v3 

    az vmss list-instances \
        --resource-group $RESOURCE_GROUP_NAME \
        --output table

    az vmss list-instance-connection-info \
        --resource-group $RESOURCE_GROUP_NAME

    echo "CREATED SCALE SET"

    az network lb rule create \
        --admin-username $VM_ADMIN_UID
        --resource-group $RESOURCE_GROUP_NAME \
        --name "${PREFIX}Rule01" \
        --lb-name "${PREFIX}Lb" \
        --backend-pool-name $ss_name \
        --backend-port 0 \
        --frontend-ip-name "${PREFIX}SsFrontendIp" \
        --frontend-port 0 \
        --protocol tcp
}