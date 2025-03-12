#!/bin/bash

# Script to destroy all resources created by the network segregation lab

# Variables
resourceGroup="SecureNetwork-Lab-RG"

# Login to Azure
echo "Logging into Azure..."
az login

# Confirm before deletion
echo "WARNING: This will delete ALL resources in the resource group: $resourceGroup"
echo "This action cannot be undone!"
read -p "Are you sure you want to continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Operation cancelled."
    exit 1
fi

# Delete the entire resource group
echo "Deleting resource group $resourceGroup..."
az group delete --name $resourceGroup --yes --no-wait

echo "Resource deletion initiated. This may take several minutes to complete."
echo "You can check the status in the Azure portal."

# Optional: Wait for the deletion to complete
echo "Do you want to wait for the deletion to complete? (This might take a while)"
read -p "(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Waiting for resource group deletion to complete..."
    az group wait --name $resourceGroup --deleted
    echo "All resources have been successfully deleted."
fi