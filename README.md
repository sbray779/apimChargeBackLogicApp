# Deploy Azure Logic App with Log Analytics and Storage

This repository contains the ARM templates and Logic App workflows to deploy a solution that:
- Connects to a Log Analytics workspace
- Stores results in a General Purpose v2 Storage Account
- Uses an existing App Service Plan
- Implements security best practices with Managed Identity

## Architecture

The solution includes:
- **Logic App (Standard)**: Workflow engine hosted on an existing App Service Plan
- **Log Analytics Workspace**: For querying and analyzing log data
- **Storage Account (GPv2)**: For storing workflow results as CSV files
- **API Connections**: Secure connections using Managed Identity
- **Blob Container**: Dedicated container for workflow data

## Prerequisites

- Azure subscription with appropriate permissions
- Existing App Service Plan (Premium or higher recommended for Logic Apps Standard)
- Resource group for deployment

## Deployment

### 1. Update Parameters

Edit `deploy/azuredeploy.parameters.json` with your values:

```json
{
  "logicAppName": {
    "value": "your-logicapp-name"
  },
  "existingAppServicePlanId": {
    "value": "/subscriptions/{your-subscription-id}/resourceGroups/{your-rg}/providers/Microsoft.Web/serverfarms/{your-plan-name}"
  },
  "logAnalyticsWorkspaceName": {
    "value": "your-workspace-name"
  },
  "storageAccountName": {
    "value": "yourstorageaccount001"
  }
}
```

### 2. Deploy Infrastructure

Using Azure CLI:
```bash
az deployment group create \
  --resource-group your-resource-group \
  --template-file deploy/azuredeploy.json \
  --parameters @deploy/azuredeploy.parameters.json
```

Using PowerShell:
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "your-resource-group" `
  -TemplateFile "deploy/azuredeploy.json" `
  -TemplateParameterFile "deploy/azuredeploy.parameters.json"
```

### 3. Deploy Workflow

After infrastructure deployment, deploy the workflow files:

1. Copy the `workflow` folder contents to your Logic App
2. Update connection references in `connections.json` with actual resource IDs
3. Customize the KQL query in `workflows.json` as needed

## Configuration

### Environment Variables

The following app settings are configured automatically:
- `AzureBlob_blobStorageEndpoint`: Storage account blob endpoint
- `LogAnalytics_WorkspaceName`: Log Analytics workspace name
- `LogAnalytics_WorkspaceId`: Log Analytics workspace ID

### Security

- All connections use Managed Identity authentication
- Storage accounts enforce HTTPS-only traffic
- Blob public access is disabled
- TLS 1.2 minimum encryption

### Customization

#### Modify the KQL Query

Edit the query in `workflow/workflows.json` under the `Run_query_and_list_results` action:

```json
"body": "YourCustomKQLQuery\n| where TimeGenerated >= ago(24h)\n| project Column1, Column2, Column3"
```

#### Change Schedule

Modify the recurrence trigger in `workflows.json`:

```json
"recurrence": {
  "interval": 6,
  "frequency": "Hour",
  "timeZone": "UTC"
}
```

## Monitoring

- Monitor workflow runs in the Azure portal
- Check Log Analytics workspace for query performance
- Review storage account metrics for blob operations
- Use Application Insights for detailed diagnostics

## Cost Optimization

- Configure appropriate Log Analytics retention period
- Use cool storage tier for archival data
- Monitor Logic App execution frequency
- Consider using consumption-based App Service Plan for lower workloads

## Security Considerations

- Managed Identity eliminates need for stored credentials
- RBAC permissions are minimal and scoped appropriately
- All traffic uses encrypted connections
- Storage account blocks public access

## Troubleshooting

### Common Issues

1. **Connection Authentication Errors**
   - Verify Managed Identity is enabled on Logic App
   - Check RBAC permissions on Log Analytics and Storage
   
2. **Query Failures**
   - Validate KQL syntax in Log Analytics workspace
   - Ensure workspace has data for the query time range
   
3. **Blob Creation Errors**
   - Verify storage container exists
   - Check storage account access permissions

### Logs and Diagnostics

- Logic App run history in Azure portal
- Application Insights for detailed telemetry
- Azure Monitor for resource health
- Storage account logs for blob operations

## License

This project is licensed under the MIT License.