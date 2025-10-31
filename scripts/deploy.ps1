# Azure Logic App Deployment Script
# This script deploys the Logic App infrastructure and workflow

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "deploy/azuredeploy.json",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "deploy/azuredeploy.parameters.json"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput Cyan "[INFO] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput Green "[SUCCESS] $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput Yellow "[WARNING] $Message"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput Red "[ERROR] $Message"
}

try {
    # Auto-detect template paths based on current directory
    $currentPath = Get-Location
    Write-Info "Current directory: $currentPath"
    
    # Check if we're in the scripts directory or root directory
    if (Test-Path "azuredeploy.json") {
        # We're in the deploy directory
        $TemplateFile = "azuredeploy.json"
        $ParametersFile = "azuredeploy.parameters.json"
    } elseif (Test-Path "deploy/azuredeploy.json") {
        # We're in the root directory
        $TemplateFile = "deploy/azuredeploy.json"
        $ParametersFile = "deploy/azuredeploy.parameters.json"
    } elseif (Test-Path "../deploy/azuredeploy.json") {
        # We're in the scripts directory
        $TemplateFile = "../deploy/azuredeploy.json"
        $ParametersFile = "../deploy/azuredeploy.parameters.json"
    } else {
        Write-Error "Cannot find ARM template files. Please run from project root, scripts directory, or deploy directory."
        exit 1
    }
    
    Write-Info "Using template file: $TemplateFile"
    Write-Info "Using parameters file: $ParametersFile"

    # Check if logged in to Azure
    $context = Get-AzContext
    if (-not $context) {
        Write-Error "Not logged in to Azure. Please run 'Connect-AzAccount' first."
        exit 1
    }

    # Set subscription
    Write-Info "Setting Azure subscription to $SubscriptionId"
    Set-AzContext -SubscriptionId $SubscriptionId

    # Check if resource group exists
    Write-Info "Checking if resource group '$ResourceGroupName' exists"
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    
    if (-not $resourceGroup) {
        Write-Info "Creating resource group '$ResourceGroupName' in '$Location'"
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Success "Resource group created successfully"
    } else {
        Write-Info "Resource group '$ResourceGroupName' already exists"
        Write-Info "Using existing resource group in location: $($resourceGroup.Location)"
    }

    # Validate ARM template
    Write-Info "Validating ARM template"
    $validationResult = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $ParametersFile

    if ($validationResult) {
        Write-Error "Template validation failed:"
        $validationResult | ForEach-Object { Write-Error $_.Message }
        exit 1
    } else {
        Write-Success "Template validation passed"
    }

    # Deploy ARM template
    Write-Info "Deploying Logic App infrastructure"
    $deploymentName = "logicapp-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $ParametersFile `
        -Name $deploymentName `
        -Verbose

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Success "Infrastructure deployment completed successfully"
    } else {
        Write-Error "Infrastructure deployment failed"
        exit 1
    }

    # Get deployment outputs
    Write-Info "Retrieving deployment outputs"
    $logicAppName = $deployment.Outputs.logicAppName.Value
    $storageAccountName = $deployment.Outputs.storageAccountName.Value
    $logAnalyticsWorkspace = $deployment.Outputs.logAnalyticsWorkspaceName.Value

    Write-Success "Deployment completed successfully!"
    Write-Output ""
    Write-Output "=== Deployment Summary ==="
    Write-Output "Logic App Name: $logicAppName"
    Write-Output "Storage Account: $storageAccountName"
    Write-Output "Log Analytics Workspace: $logAnalyticsWorkspace"
    Write-Output "Resource Group: $ResourceGroupName"
    Write-Output "Deployment Name: $deploymentName"
    Write-Output ""
    Write-Warning "Next steps:"
    Write-Output "1. Upload workflow files to the Logic App"
    Write-Output "2. Update connection references with actual resource IDs"
    Write-Output "3. Customize the KQL query as needed"
    Write-Output "4. Test the workflow execution"

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}