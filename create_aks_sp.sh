#!/usr/bin/env bash
# see https://docs.microsoft.com/de-de/azure/aks/azure-ad-integration-cli

set -o errexit
set -o nounset
set -o pipefail

read -p "Enter your AKS cluster name: " aksname

echo "Creating the Azure AD application"
serverApplicationId=$(az ad app create \
    --display-name "${aksname}Server" \
    --identifier-uris "https://${aksname}Server" \
    --query appId -o tsv)

sleep 10s

echo "Updating the application group memebership claims"
az ad app update --id $serverApplicationId --set groupMembershipClaims=All

sleep 10s

echo "Create a service principal for the Azure AD application"
az ad sp create --id $serverApplicationId

# Get the service principal secret
serverApplicationSecret=$(az ad sp credential reset \
    --name $serverApplicationId \
    --credential-description "AKSPassword" \
    --query password -o tsv)

sleep 5s

az ad app permission add \
    --id $serverApplicationId \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

sleep 5s

# Due to current AAD permission issue disabled
# az ad app permission grant --id $serverApplicationId --api 00000003-0000-0000-c000-000000000000
# az ad app permission admin-consent --id  $serverApplicationId

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
