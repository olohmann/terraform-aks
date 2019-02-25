# End-to-End Azure Kubernetes Service (AKS) Deployment using Terraform

This is an end-to-end sample on how to deploy the [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/services/kubernetes-service/) using [Terraform](https://www.terraform.io/).


# Misc

## Getting AKS Admin credentials

```sh
az aks get-credentials --resource-group <TODO> --name <TODO> --admin --overwrite-existing
```

## Getting AKS User credentials

```sh
az aks get-credentials --resource-group <TODO> --name <TODO> --overwrite-existing
```