# Deployment Guide

## Quick Start

### Prerequisites
1. Azure CLI or Azure PowerShell installed
2. Azure subscription with sufficient permissions
3. Existing App Service Plan (Premium or higher recommended)

### Step 1: Configure Parameters
Edit `deploy/azuredeploy.parameters.json`:

```json
{
  "logicAppName": {
    "value": "my-logicapp-workflow"
  },
  "existingAppServicePlanId": {
    "value": "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-RG/providers/Microsoft.Web/serverfarms/YOUR-PLAN-NAME"
  },
  "logAnalyticsWorkspaceName": {
    "value": "my-log-analytics-workspace"
  },
  "storageAccountName": {
    "value": "mystorageaccount001"
  }
}
```

### Step 2: Deploy Using PowerShell
```powershell
.\scripts\deploy.ps1 -ResourceGroupName "your-rg" -SubscriptionId "your-subscription-id"
```

### Step 3: Deploy Using Azure CLI
```bash
bash scripts/deploy.sh -g "your-rg" -s "your-subscription-id"
```

### Step 4: Configure RBAC (Run after main deployment)
```bash
# Get the Logic App principal ID from the deployment output
az deployment group create \
  --resource-group your-resource-group \
  --template-file deploy/rbac.json \
  --parameters logicAppPrincipalId="principal-id-from-main-deployment" \
               storageAccountName="your-storage-account" \
               logAnalyticsWorkspaceName="your-workspace-name"
```

## Manual Deployment Steps

If you prefer to deploy manually:

1. **Deploy Infrastructure**
   ```bash
   az deployment group create \
     --resource-group your-resource-group \
     --template-file deploy/azuredeploy.json \
     --parameters @deploy/azuredeploy.parameters.json
   ```

2. **Deploy RBAC Permissions**
   ```bash
   az deployment group create \
     --resource-group your-resource-group \
     --template-file deploy/rbac.json \
     --parameters logicAppPrincipalId="principal-id" \
                  storageAccountName="storage-name" \
                  logAnalyticsWorkspaceName="workspace-name"
   ```

3. **Upload Workflow Files**
   - Copy `workflow/workflows.json` to your Logic App
   - Copy `workflow/connections.json` to your Logic App
   - Update connection references with actual resource IDs

## Post-Deployment Configuration

1. **Update Connection References**
   Replace placeholders in `workflow/connections.json` with actual resource IDs:
   - `{subscription-id}` → Your Azure subscription ID
   - `{resource-group}` → Your resource group name
   - `{location}` → Your Azure region

2. **Customize KQL Query**
   Modify the query in `workflow/workflows.json` to match your Log Analytics data structure

3. **Test the Workflow**
   - Trigger the workflow manually in the Azure portal
   - Verify data is written to the storage container
   - Check logs for any errors

## Troubleshooting

- **Authentication Issues**: Ensure Managed Identity is enabled and RBAC roles are assigned
- **Query Failures**: Validate KQL syntax in Log Analytics workspace
- **Storage Errors**: Check container exists and permissions are correct