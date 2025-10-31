# Deploy Azure Logic App for API Management Token Usage Reporting

This repository contains the ARM templates and Logic App workflows to deploy a solution that:
- Connects to a Log Analytics workspace to query API Management gateway logs
- Extracts token usage data from API Management LLM gateway logs
- Stores chargeback reports in a General Purpose v2 Storage Account
- Uses an existing App Service Plan for the Logic App deployment
- Implements security best practices with Managed Identity

## Architecture

The solution includes:
- **Logic App (Standard)**: Workflow engine hosted on an existing App Service Plan
- **Log Analytics Workspace**: For querying and analyzing API Management gateway logs
- **Storage Account (GPv2)**: For storing token usage reports as CSV files
- **API Connections**: Secure connections using Managed Identity
- **Blob Container**: Dedicated container for chargeback report data

## Prerequisites

### Azure Resources
- Azure subscription with appropriate permissions
- **Existing App Service Plan** (Premium or higher recommended for Logic Apps Standard)
- Resource group for deployment

### API Management Requirements
The deployment is designed to work with an existing API Management instance that has been configured for AI services token tracking:

1. **API Management Instance**: Must be integrated with AI services (OpenAI, Azure OpenAI, etc.)
2. **Gateway Logging**: API Gateway logging must be enabled on the API Management service
3. **LLM Gateway Logging**: LLM Gateway logging must be enabled to capture token usage data
4. **Diagnostic Settings**: A diagnostic setting must be configured on the API Management instance to send the following logs to the Log Analytics workspace tables created by this deployment:
   - `ApiManagementGatewayLogs`
   - `ApiManagementGatewayLlmLog`

### Required API Management Configuration

Before deploying this solution, ensure your API Management instance is configured as follows:

#### 1. Enable Gateway Logging
In your API Management instance:
- Navigate to **Monitoring** > **Diagnostic settings**
- Enable logging for gateway operations

#### 2. Enable LLM Gateway Logging
- Ensure LLM gateway logging is enabled to capture token usage
- This captures prompt tokens, completion tokens, and total tokens per request

#### 3. Configure Diagnostic Settings
Create a diagnostic setting that sends logs to your Log Analytics workspace:
- Log categories to enable:
  - `ApiManagementGatewayLogs`
  - `ApiManagementGatewayLlmLog`
- Destination: Send to Log Analytics workspace (created by this deployment)

#### 4. Enable logging of requests and responses for LLM API
    https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-llm-logs

#### 5. Verify Log Data
Ensure your API Management instance is generating the required log data with fields:
- `CorrelationId`
- `SequenceNumber`
- `IsRequestSuccess`
- `TraceRecords` (containing client ID information)
- `PromptTokens`, `CompletionTokens`, `TotalTokens`
- `ModelName`, `Region`, `CallerIpAddress`, etc.

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

The default query extracts token usage data from API Management logs. Edit the query in `workflow/workflows.json` under the `Run_query_and_list_results` action:

```kql
ApiManagementGatewayLogs 
| join ApiManagementGatewayLlmLog on CorrelationId
| where SequenceNumber == 0 and IsRequestSuccess == true
| mv-expand TraceRecords
| extend messageRaw = tostring(TraceRecords["message"])
| extend clientID = trim("ClientID:", messageRaw)
| project TimeGenerated, clientID, Region, CallerIpAddress, Cache, ProductId, BackendId, PromptTokens, CompletionTokens, TotalTokens, ModelName
```

You can customize this query to:
- Filter by specific time ranges
- Add additional fields for reporting
- Modify client ID extraction logic
- Include/exclude specific products or backends

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