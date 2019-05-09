#!/usr/bin/env bash
# see https://docs.microsoft.com/de-de/azure/aks/azure-ad-integration-cli

set -o errexit
set -o nounset
set -o pipefail

read -p "Enter your AKS cluster name: " aksname

# Create the Azure AD application
serverApplicationId=$(az ad app create \
    --display-name "${aksname}Server" \
    --identifier-uris "https://${aksname}Server" \
    --query appId -o tsv)

wait 10

# Update the application group memebership claims
az ad app update --id $serverApplicationId --set groupMembershipClaims=All

wait 5

# Create a service principal for the Azure AD application
az ad sp create --id $serverApplicationId

# Get the service principal secret
serverApplicationSecret=$(az ad sp credential reset \
    --name $serverApplicationId \
    --credential-description "AKSPassword" \
    --query password -o tsv)




