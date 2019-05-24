# End-to-End Azure Kubernetes Service (AKS) Deployment using Terraform

This is an end-to-end sample on how to deploy the [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/services/kubernetes-service/) using [Terraform](https://www.terraform.io/).

## Overview

This diagram provides a rough overview of the deployed infrastructure:
![Deployment Overview](./docs/Diagram.png)

Please note that the additional services like Azure Key Vault and Azure Storage depicted here and just example on PaaS components that can be integrated into the solution.

## Getting Started

The easiest way, to start get the whole environment setup and deployed is by running the `run_tf.sh` script. However, first you have to **ensure the following preconditions**:

1. Execute the helper script `check_tools.sh` from the project's root directory. It verifies the availability of all required tools in your path.
1. Create a client and server application registration in Azure Active Directory to support Kubernetes OIDC integration. In short, this allows you to use Azure AD as your identity provider to manage cluster access. Follow [these steps](https://docs.microsoft.com/en-us/azure/aks/aad-integration) and retrieve the required setting information. Hint: You do not need to create multiple of these registration in your environment, but you should hand out individual secrets.
1. Enable the AKS Audit Log **feature flag** in your subscription as described in the *Note* field in the [official documentation](https://docs.microsoft.com/en-us/azure/aks/view-master-logs). **Only register the flag, all actual diagnostic configuration is fully automated during the deployment.**

When all preconditions are met, you need to gather the required input variables in a file, e.g. `env.dev.sh`. The following variables are **mandatory** to provide:

```bash
export __TF_prefix="contoso"
export __TF_aad_server_app_id="00000000-0000-0000-0000-000000000000"
export __TF_aad_server_app_secret="PatVMovW........WXJyV5fw="
export __TF_aad_client_app_id="00000000-0000-0000-0000-000000000000"
export __TF_aad_tenant_id="00000000-0000-0000-0000-000000000000"
export __TF_aks_cluster_admins="[\\\"john@contoso.com\\\", \\\"jane@contoso.com\\\"]"
```

Source the `env.dev.sh` file via `source env.dev.sh` in your current session.

Finally you can execute the complete deployment process. `-e` denotes an environment like DEV, QA or PROD. If you don't provide anything, the environment will be called `default`.

```sh
./run_tf.sh -e dev
```

> If you would like to run the deployments individually instead of using the run_tf.sh script, feel free to look into the script file and take out the bits and pieces which are useful to you.

## Deployment Structure

The deployment structure is basically divided into two parts. The first part takes care of the Azure Resources, the second part takes care of the Kubernetes side.

- `00-tf-backend`

   Configures the terraform azure backend state provider and generates the backend-config output which is passed by the `run_tf.sh` script automatically to all subsequent deployment sections.

- `01-env` (optional)

    An optional preparation step that creates the required service principals for the AKS deployment. The required parameters are automatically extracted and forwarded to the `02-aks` step via environment variables.

    > Required rights for execution: Allowance to create Azure Service Principals in your Azure AD tenant, see [Azure Docs](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#required-permissions).

    If you like to skip this step and instead create a SP separately, just remove `01-env` from the `run_tf.sh` script and provide the required parameters via environment variables:

    ```sh
    export __TF_aks_cluster_sp_app_id="..."
    export __TF_aks_cluster_sp_object_id="..."
    export __TF_aks_cluster_sp_secret="..."
    ```

- `02-aks`

    The actual deployment of an AKS cluster, an Azure Firewall, and the baseline network infrastructure.

    > Requires that the executing entity has the Azure RBAC permission *Owner* on the target subscription.

-----------

- `03-aks-post-deploy`

    After completing the Azure resource deployment, the post deploy step configures the Kubernetes cluster role bindings and prepares the helm service account.

    > Requires cluster-admin rights on Kubernetes.

- `04-aks-post-deploy-ingress` (optional)

    This post deploy step configures the Kubernetes environment to support Azure Pod Identity and the Azure nginx Ingress option. Please note, that this step is completely optional. Feel free to setup a manual integration.

    > Requires cluster-admin rights on Kubernetes.

- `10-deployment-sample` (optional)

    An optional example to verify the deployment. It exposes an echo service.

    > Requires cluster-admin rights on Kubernetes.

-----------

- `99-externals` (ignore for the moment)

    Git sub-module which currently links to the aad-pod-identity GitHub repository. As soon as the aad-pod-identity project issues a proper remote Helm chart, the reference can be removed.

## Disclaimer

This sample deploys AKS in combination with Azure Firewall and nginx ingress. Please note, that Microsoft does not officially support an AKS setup in combination with Azure Firewall.

## Misc

### Getting AKS Admin credentials

```sh
az aks get-credentials --resource-group <TODO> --name <TODO> --admin --overwrite-existing
```

### Getting AKS User credentials

```sh
az aks get-credentials --resource-group <TODO> --name <TODO> --overwrite-existing
```

### Useful Links

- [Quick-Start Cert Manager with NGINX Ingress](http://docs.cert-manager.io/en/latest/tutorials/acme/quick-start/index.html)

## Acknowledgements

Big thanks to [Darius Tehrani](https://github.com/dariustehrani/) for lots of feedback and input!
