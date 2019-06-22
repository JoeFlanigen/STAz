#!/bin/bash -e
set -e

create_app_gateway_cli() {
    
    local app_gw_name="$PREFIX-agw"
    local public_ip_name="$PREFIX-agw-pip"
    local private_ip="10.2.3.5"
    
    create_public_ip $public_ip_name
    
    echo "CREATING GATEWAY"

    echo "az network application-gateway create"
    az network application-gateway create \
        --capacity 3 \
        --cert-file "./certs/appgw_1/AppGW1.pfx" \
        --cert-password "pass21$" \
        --connection-draining-timeout 20 \
        --frontend-port 443 \
        --http-settings-cookie-based-affinity Enabled \
        --http-settings-port 80 \
        --http-settings-protocol Http \
        --location $LOCATION \
        --name $app_gw_name \
        --private-ip-address $private_ip \
        --public-ip-address $public_ip_name \
        --public-ip-address-allocation Static \
        --resource-group $RESOURCE_GROUP_NAME \
        --routing-rule-type Basic \
        --servers "10.2.2.10" "10.2.2.11" "10.2.2.12" \
        --sku Standard_v2 \
        --vnet-name $VNET_NAME \
        --subnet $GATEWAY_SUBNET_NAME \
        || (echo "FAILED TO CREATE GATEWAY: $PREFIX-gw" && exit 1)

    echo "GATEWAY CREATED"
    
    #################################################
    # add the ports to the application gateway
    #################################################
    echo "az network application-gateway frontend-port create: port_80"
    az network application-gateway frontend-port create \
        --gateway-name $app_gw_name \
        --name port_80 \
        --port 80 \
        --resource-group $RESOURCE_GROUP_NAME
    
    #################################################
    # add the listeners to the gateway
    #################################################
    echo "az network application-gateway http-listener create: port_80_listener"
    az network application-gateway http-listener create \
        --frontend-ip $public_ip_name \
        --frontend-port port_80 \
        --gateway-name $app_gw_name \
        --name "$app_gw_name-listener-80" \
        --resource-group $RESOURCE_GROUP_NAME
    
    #################################################
    # Add the redirection
    #################################################
    echo "az network application-gateway redirect-config create: 80"
    az network application-gateway redirect-config create \
        --name "redirect_80_to_443" \
        --gateway-name $app_gw_name \
        --resource-group $RESOURCE_GROUP_NAME \
        --type Permanent \
        --target-listener "$app_gw_name-listener-80" \
        --include-path true \
        --include-query-string true
        
    #################################################
    # Add gateway rules
    #################################################
    echo "az network application-gateway rule create: 80"
    az network application-gateway rule create \
        --gateway-name $app_gw_name \
        --name "rule_80_to_443" \
        --resource-group $RESOURCE_GROUP_NAME \
        --http-listener "$app_gw_name-listener-80" \
        --rule-type Basic \
        --redirect-config "redirect_80_to_443"
 }

create_app_gateway_template() {

    local app_gw_name="$PREFIX-agw"
    local private_ip="10.2.3.5"
    local public_ip_name="$PREFIX-agw-pip"
    
    echo "CREATING GATEWAY PUBLIC IP"
    create_public_ip $public_ip_name

    local uuid=$(uuidgen)
    local deployment_name="deployment-$uuid"

    echo "DEPLOYMENT: $deployment_name"

    echo "Starting deployment..."
    (
        set -x
        az group deployment create \
            --name $deployment_name \
            --resource-group $RESOURCE_GROUP_NAME \
            --template-file "./templates/app-gw/template.json" \
            --parameters "./templates/app-gw/parameters.json" \
            --parameters \
                applicationGatewayName=$app_gw_name \
                location=$LOCATION \
                subnetName=$GATEWAY_SUBNET_NAME \
                publicIpAddressName=$public_ip_name \
                AppGW1_password="pass21$"
    )

    if [ $?  == 0 ];
    then
        echo "Template has been successfully deployed"
        echo "GATEWAY CREATED"
    else
        echo "Template was not successfully deployed"
        echo "GATEWAY NOT CREATED"
    fi
}



