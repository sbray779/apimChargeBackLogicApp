# Project Structure

## Overview
```
azure-logicapp-workflow/
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions CI/CD pipeline
├── deploy/
│   ├── azuredeploy.json           # Main ARM template
│   ├── azuredeploy.parameters.json # Template parameters
│   └── rbac.json                  # RBAC role assignments template
├── scripts/
│   ├── deploy.sh                  # Bash deployment script
│   └── deploy.ps1                 # PowerShell deployment script
├── workflow/
│   ├── workflows.json             # Logic App workflow definition
│   ├── connections.json           # API connections configuration
│   ├── host.json                  # Logic App host configuration
│   └── local.settings.json        # Local development settings
├── .gitignore                     # Git ignore file
├── DEPLOYMENT.md                  # Deployment instructions
├── README.md                      # Project documentation
└── package.json                   # Node.js package configuration
```

## File Descriptions

### ARM Templates (`deploy/`)
- **azuredeploy.json**: Main infrastructure template that creates:
  - Logic App (Standard) on existing App Service Plan
  - Log Analytics workspace
  - General Purpose v2 Storage Account
  - API connections for Azure Blob and Azure Monitor Logs
  - Managed Identity configuration

- **azuredeploy.parameters.json**: Parameter values for the ARM template
- **rbac.json**: RBAC role assignments for Managed Identity access

### Workflow Files (`workflow/`)
- **workflows.json**: Logic App workflow definition with:
  - Scheduled trigger (daily recurrence)
  - Log Analytics query action
  - CSV table creation
  - Blob storage upload
  - Error handling and monitoring

- **connections.json**: API connection configurations using Managed Identity
- **host.json**: Logic App runtime configuration
- **local.settings.json**: Local development environment variables

### Deployment Scripts (`scripts/`)
- **deploy.sh**: Bash script for Linux/macOS deployment
- **deploy.ps1**: PowerShell script for Windows deployment

### CI/CD (`.github/workflows/`)
- **deploy.yml**: GitHub Actions workflow for automated deployment

## Key Features

### Security
- ✅ Managed Identity authentication (no stored credentials)
- ✅ HTTPS-only traffic enforcement
- ✅ Storage account public access disabled
- ✅ TLS 1.2 minimum encryption
- ✅ RBAC with least privilege principles

### Scalability
- ✅ Uses existing App Service Plan (configurable scaling)
- ✅ General Purpose v2 Storage for performance
- ✅ Log Analytics workspace for large-scale log processing
- ✅ Chunked transfer for large CSV files

### Monitoring
- ✅ Logic App run history and diagnostics
- ✅ Application Insights integration
- ✅ Azure Monitor integration
- ✅ Storage account metrics

### Automation
- ✅ Scheduled daily execution
- ✅ Parameterized configuration
- ✅ CI/CD pipeline ready
- ✅ Error handling and retry logic

## Customization Points

1. **KQL Query**: Modify the Log Analytics query in `workflow/workflows.json`
2. **Schedule**: Change recurrence settings in the trigger
3. **Storage Location**: Update container and blob naming patterns
4. **Parameters**: Adjust ARM template parameters for your environment
5. **Monitoring**: Add additional actions for notifications or alerts