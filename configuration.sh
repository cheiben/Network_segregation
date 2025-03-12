#!/bin/bash

# Azure Network Segregation & Monitoring Lab
# This script creates a proper network segregation environment with basic monitoring
# Save as deploy-secure-network.sh

# ---------- Variables ----------
resourceGroup="SecureNetwork-Lab-RG"
location="eastus"
vnetName="Secure-VNet"
vnetAddressSpace="10.0.0.0/16"

# Subnet configuration
webSubnetName="WebSubnet"
webSubnetAddress="10.0.1.0/24"
webNsgName="WebNSG"

appSubnetName="AppSubnet"
appSubnetAddress="10.0.2.0/24"
appNsgName="AppNSG"

dataSubnetName="DataSubnet"
dataSubnetAddress="10.0.3.0/24"
dataNsgName="DataNSG"

mgmtSubnetName="ManagementSubnet" 
mgmtSubnetAddress="10.0.4.0/24"
mgmtNsgName="ManagementNSG"

# Monitoring variables
workspaceName="SecurityMonitoring-Workspace"
storageAccountName="secnetstorage$(( RANDOM % 9000 + 1000 ))"

# ---------- Login and create resource group ----------
echo -e "Logging into Azure"
az login

echo -e "Creating resource group ${resourceGroup}."
az group create --name ${resourceGroup} --location ${location}

# ---------- Create Virtual Network with Subnets ----------
echo -e "Creating virtual network."
az network vnet create --resource-group ${resourceGroup} --name ${vnetName} --address-prefixes ${vnetAddressSpace} --location ${location}

# ---------- Create NSGs with proper rules ----------
# 1. Web Tier NSG - Allows HTTP/HTTPS from internet, restricts all other traffic
echo -e "Creating and configuring Web Tier NSG"
az network nsg create --resource-group ${resourceGroup} --name ${webNsgName}
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${webNsgName} --name "Allow-HTTP" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes Internet --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 80
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${webNsgName} --name "Allow-HTTPS" --priority 110 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes Internet --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 443
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${webNsgName} --name "Allow-To-App" --priority 100 --direction Outbound --access Allow --protocol Tcp --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes ${appSubnetAddress} --destination-port-ranges 8080
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${webNsgName} --name "Deny-Other-Outbound" --priority 200 --direction Outbound --access Deny --protocol '*' --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*'

# 2. App Tier NSG - Only allows traffic from Web tier, can only talk to Data tier
echo -e "Creating and configuring App Tier NSG."
az network nsg create --resource-group ${resourceGroup} --name ${appNsgName}
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${appNsgName} --name "Allow-From-Web" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes ${webSubnetAddress} --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 8080
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${appNsgName} --name "Allow-To-Data" --priority 100 --direction Outbound --access Allow --protocol Tcp --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes ${dataSubnetAddress} --destination-port-ranges 1433
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${appNsgName} --name "Deny-Other-Outbound" --priority 200 --direction Outbound --access Deny --protocol '*' --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges '*'

# 3. Data Tier NSG - Only allows traffic from App tier, no outbound internet access
echo -e "Creating and configuring Data Tier NSG."
az network nsg create --resource-group ${resourceGroup} --name ${dataNsgName}
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${dataNsgName} --name "Allow-From-App" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes ${appSubnetAddress} --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 1433
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${dataNsgName} --name "Deny-All-Outbound" --priority 100 --direction Outbound --access Deny --protocol '*' --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes Internet --destination-port-ranges '*'

# 4. Management NSG - Highly restricted, only allows RDP/SSH from authorized sources
echo -e "Creating and configuring Management Tier NSG."
az network nsg create --resource-group ${resourceGroup} --name ${mgmtNsgName}
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${mgmtNsgName} --name "Allow-RDP-From-Trusted" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "76.151.38.187/32" --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 3389
az network nsg rule create --resource-group ${resourceGroup} --nsg-name ${mgmtNsgName} --

# ---------- Create subnets and associate NSGs ----------
echo -e "Creating subnets and associating NSGs..." -ForegroundColor Green
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $webSubnetName --address-prefixes $webSubnetAddress --network-security-group $webNsgName
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $appSubnetName --address-prefixes $appSubnetAddress --network-security-group $appNsgName
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $dataSubnetName --address-prefixes $dataSubnetAddress --network-security-group $dataNsgName
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $mgmtSubnetName --address-prefixes $mgmtSubnetAddress --network-security-group $mgmtNsgName

# ---------- Set up monitoring ----------
# Create Log Analytics workspace for monitoring
echo -e "Setting up monitoring components..." -ForegroundColor Green
az monitor log-analytics workspace create --resource-group $resourceGroup --workspace-name $workspaceName --location $location

# Create storage account for NSG flow logs
az storage account create --name $storageAccountName --resource-group $resourceGroup --location $location --sku Standard_LRS --kind StorageV2

# Enable Network Watcher
az network watcher configure --locations $location --enabled true --resource-group $resourceGroup

# Enable NSG Flow Logs for each NSG
# Note: "enable" below should be updated to true once you've verified the command works

workspaceId=$(az monitor log-analytics workspace show --resource-group SecureNetwork-Lab-RG --workspace-name SecurityMonitoring-Workspace --query id -o tsv)
az network watcher flow-log create --location $location --name flow-log-web --resource-group $resourceGroup --nsg $webNsgName \
    --storage-account $storageAccountName --workspace "$workspaceId" \
    --enabled true --retention 7

az network watcher flow-log create --location $location --name flow-log-app --resource-group $resourceGroup --nsg $appNsgName \
    --storage-account $storageAccountName --workspace "$workspaceId" \
    --enabled true --retention 7

az network watcher flow-log create --location $location --name flow-log-data --resource-group $resourceGroup --nsg $dataNsgName \
    --storage-account $storageAccountName --workspace "$workspaceId" \
    --enabled true --retention 7

az network watcher flow-log create --location $location --name flow-log-mgmt --resource-group $resourceGroup --nsg $mgmtNsgName \
    --storage-account $storageAccountName --workspace "$workspaceId" \
    --enabled true --retention 7

# ---------- Deploy VMs for Demo (Optional) ----------

# Web VM
az vm create --resource-group $resourceGroup --name WebVM --image Ubuntu2204 --admin-username azureuser --generate-ssh-keys \
    --vnet-name $vnetName --subnet $webSubnetName --public-ip-address WebVM-pip --nsg ""

# App VM
az vm create --resource-group $resourceGroup --name AppVM --image RHELRaw8LVMGen2 --admin-username azureuser --generate-ssh-keys \
    --vnet-name $vnetName --subnet $appSubnetName --public-ip-address "" --nsg ""

# Data VM (SQL Server)
az vm create --resource-group $resourceGroup --name DataVM --image MicrosoftSQLServer:sql2019-ws2019:sqldev-gen2:latest --admin-username azureuser \
    --admin-password "ComplexP@ssw0rd123!" --vnet-name $vnetName --subnet $dataSubnetName --public-ip-address "" --nsg ""

# Management VM
az vm create --resource-group $resourceGroup --name MgmtVM --image Win2019Datacenter --admin-username azureuser \
    --admin-password "ComplexP@ssw0rd123!" --vnet-name $vnetName --subnet $mgmtSubnetName --public-ip-address MgmtVM-pip --nsg ""


# ---------- Create basic monitoring dashboard ----------
echo -e "Network segregation lab successfully deployed with monitoring enabled!" -ForegroundColor Green
echo -e "Next steps:" -ForegroundColor Yellow
echo -e "1. Update IP addresses in Management NSG to your actual trusted IPs" -ForegroundColor Yellow
echo -e "2. Run Network Watcher tests between subnets to verify security rules" -ForegroundColor Yellow
echo -e "3. Set up Azure Monitor alerts for suspicious activities" -ForegroundColor Yellow
echo -e "4. Deploy sample VMs if desired by uncommenting the VM creation section" -ForegroundColor Yellow

# Sample queries for Log Analytics
echo -e "Sample KQL query for denied connections:" -ForegroundColor Cyan
echo -e "AzureNetworkAnalytics_CL | where FlowType_s == 'Deny' | project TimeGenerated, NSGRule_s, FlowDirection_s, SrcIP_s, DestIP_s" -ForegroundColor Cyan