#!/bin/bash

# Azure Logic App Deployment Script
# This script deploys the Logic App infrastructure and workflow

set -e

# Configuration
RESOURCE_GROUP=""
SUBSCRIPTION_ID=""
LOCATION="East US"
TEMPLATE_FILE="../deploy/azuredeploy.json"
PARAMETERS_FILE="../deploy/azuredeploy.parameters.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 -g <resource-group> -s <subscription-id> [-l <location>]"
            echo ""
            echo "Options:"
            echo "  -g, --resource-group    Azure resource group name"
            echo "  -s, --subscription      Azure subscription ID"
            echo "  -l, --location          Azure region (default: East US)"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$RESOURCE_GROUP" ]]; then
    print_error "Resource group is required. Use -g or --resource-group"
    exit 1
fi

if [[ -z "$SUBSCRIPTION_ID" ]]; then
    print_error "Subscription ID is required. Use -s or --subscription"
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Set subscription
print_info "Setting Azure subscription to $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# Check if resource group exists
print_info "Checking if resource group '$RESOURCE_GROUP' exists"
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_info "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    print_success "Resource group created successfully"
else
    print_info "Resource group '$RESOURCE_GROUP' already exists"
fi

# Validate ARM template
print_info "Validating ARM template"
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE"

if [[ $? -eq 0 ]]; then
    print_success "Template validation passed"
else
    print_error "Template validation failed"
    exit 1
fi

# Deploy ARM template
print_info "Deploying Logic App infrastructure"
DEPLOYMENT_NAME="logicapp-deployment-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --verbose

if [[ $? -eq 0 ]]; then
    print_success "Infrastructure deployment completed successfully"
else
    print_error "Infrastructure deployment failed"
    exit 1
fi

# Get deployment outputs
print_info "Retrieving deployment outputs"
LOGIC_APP_NAME=$(az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME" --query "properties.outputs.logicAppName.value" -o tsv)
STORAGE_ACCOUNT_NAME=$(az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME" --query "properties.outputs.storageAccountName.value" -o tsv)
LOG_ANALYTICS_WORKSPACE=$(az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME" --query "properties.outputs.logAnalyticsWorkspaceName.value" -o tsv)

print_success "Deployment completed successfully!"
echo ""
echo "=== Deployment Summary ==="
echo "Logic App Name: $LOGIC_APP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Log Analytics Workspace: $LOG_ANALYTICS_WORKSPACE"
echo "Resource Group: $RESOURCE_GROUP"
echo "Deployment Name: $DEPLOYMENT_NAME"
echo ""
print_warning "Next steps:"
echo "1. Upload workflow files to the Logic App"
echo "2. Update connection references with actual resource IDs"
echo "3. Customize the KQL query as needed"
echo "4. Test the workflow execution"