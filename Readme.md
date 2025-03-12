# Azure Network Segregation

## Overview
This project implements a secure network architecture in Azure following the defense-in-depth principle. It creates a properly segregated network environment with distinct tiers (Web, Application, Data, and Management) and configures appropriate security controls between them.

## Architecture
The implementation follows Zero Trust principles with a tiered architecture:

- **Web Tier**: Public-facing components with restricted outbound access
- **App Tier**: Middle-tier components with no public access
- **Data Tier**: Database components with highly restricted access
- **Management Tier**: Administrative access with strict controls

## Features
- Network segmentation with NSGs enforcing least-privilege access
- Proper subnet isolation following security best practices
- NSG flow logs for comprehensive traffic monitoring
- Log Analytics integration for security analysis

## Prerequisites
- Azure subscription
- Azure CLI installed
- Bash shell environment

## Deployment Instructions

### Step 1: Review and Modify Configuration
```bash
# Open the script and update variables if needed
nano configuration.sh

# Replace "Your.IP.Address.Here/32" with your actual IP address
```

### Step 2: Run the Deployment Script
```bash
# Make the script executable
chmod +x configuration.sh

# Run the script
./configuration.sh
```

### Step 3: Verify Deployment
1. Check that all NSGs are created with proper rules
2. Verify subnet associations
3. Confirm monitoring components are deployed

## Network Security Groups

### Web Tier NSG
- **Inbound**: Allows HTTP(80) and HTTPS(443) from the internet
- **Outbound**: Only allows traffic to App tier on port 8080

### App Tier NSG
- **Inbound**: Only accepts traffic from Web tier on port 8080
- **Outbound**: Only allows traffic to Data tier on port 1433

### Data Tier NSG
- **Inbound**: Only accepts traffic from App tier on port 1433
- **Outbound**: No internet access allowed

### Management Tier NSG
- **Inbound**: Only allows RDP/SSH from authorized IPs
- **Outbound**: Restricted internet access

## Monitoring
The lab includes comprehensive monitoring through:
- NSG flow logs stored in a storage account
- Log Analytics workspace for query and analysis
- Network Watcher for connectivity testing

## Sample Log Queries
Once logs are flowing, use these queries in Log Analytics:

```kql
// View denied traffic
AzureNetworkAnalytics_CL 
| where FlowType_s == "Deny" 
| project TimeGenerated, NSGRule_s, SrcIP_s, DestIP_s
```

## Clean Up Resources
When you're done with the lab, clean up resources to avoid unnecessary charges:

```bash
# Delete the entire resource group
az group delete --name SecureNetwork-Lab-RG --yes
```

## Security Benefits
This architecture demonstrates:
1. **Defense in Depth**: Multiple security layers
2. **Least Privilege**: Traffic only permitted where needed
3. **Network Segmentation**: Clear boundaries between application tiers
4. **Visibility**: Comprehensive logging for security analysis

## Troubleshooting
- If NSG rules aren't working, verify they're correctly associated with subnets
- Allow 15-30 minutes for flow logs to appear in Log Analytics
- Ensure your trusted IP is correctly set in Management NSG rules

## Next Steps
Consider enhancing this lab with:
- Azure Firewall implementation
- Azure Bastion for secure management access
- Private endpoints for PaaS services
- Just-In-Time VM access

By# Cheikh B