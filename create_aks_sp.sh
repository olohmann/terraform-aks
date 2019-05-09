#!/usr/bin/env bash
# see https://docs.microsoft.com/de-de/azure/aks/azure-ad-integration-cli

set -o errexit
set -o nounset
set -o pipefail

read -p "Enter your AKS cluster name: " aksname

echo "Creating Azure AD client component"
clientApplicationId=$(az ad app create \
    --display-name "${aksname}Client" \
    --native-app \
    --reply-urls "https://${aksname}Client" \
    --query appId -o tsv)

az ad sp create --id $clientApplicationId
oAuthPermissionId=$(az ad app show --id $serverApplicationId --query "oauth2Permissions[0].id" -o tsv)

#az ad app permission add --id $clientApplicationId --api $serverApplicationId --api-permissions $oAuthPermissionId=Scope
#az ad app permission grant --id $clientApplicationId --api $serverApplicationId
echo "Done."
