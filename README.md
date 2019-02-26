# End-to-End Azure Kubernetes Service (AKS) Deployment using Terraform

This is an end-to-end sample on how to deploy the [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/services/kubernetes-service/) using [Terraform](https://www.terraform.io/).

## Overview

This diagram provides a rough overview of the deployed infrastructure:
![Deployment Overview](./docs/Diagram.png)

Please note that the additional services like Azure Key Vault and Azure Storage depicted here and just example on PaaS components that can be integrated into the solution.

## Source Code Structure

- `00-env` (optional)

    An optional preparation step that creates the required service principals for the deployment. It creates a local secret tfvars file in `01-aks`. The secret file is git-ignored and can be used to as a parameter input file for the actual AKS deployment in `01-aks`.

- `01-aks`

    The actual deployment of an AKS cluster, an Azure Firewall, an Azure Application Gateway and the baseline network infrastructure.

- `02-aks-post-deploy`

    After completing the Azure resource deployment, the post deploy step configures the Kubernetes cluster role bindings and prepares the helm service account.

- `03-aks-post-deploy-ingress` (optional)

    This post deploy step configures the Kubernetes environment to support Azure Pod Identity and the Azure Application Gateway Ingress option. Please note, that this step is completely optional. Feel free to setup a manual integration between Azure App GW and your application using Internal Load Balancers and custom rule management.

- `10-deployment-sample` (optional)

    An optional example to verify the deployment. It exposes the Guestbook sample application on port 80 of your Application Gateway IP.

- `99-externals`

    Git sub-module which currently links to the aad-pod-identity GitHub repository. As soon as the aad-pod-identity project issues a proper remote Helm chart, the reference can be removed.

## Disclaimer

This sample deploys AKS in combination with Azure Firewall and Azure Application Gateway. Please note, that Microsoft does not officially support an AKS setup in combination with Azure Firewall.

## Misc

### Getting AKS Admin credentials

```sh
az aks get-credentials --resource-group <TODO> --name <TODO> --admin --overwrite-existing
```

### Getting AKS User credentials

```sh
az aks get-credentials --resource-group <TODO> --name <TODO> --overwrite-existing
```
