## Required Inputs

The following input variables are required:

### aad\_client\_app\_id

Description: The client app ID for the AAD AKS auth integration.

Type: `string`

### aad\_server\_app\_id

Description: The server app ID for the AAD AKS auth integration.

Type: `string`

### aad\_server\_app\_secret

Description: The server secret for the AAD AKS auth integration.

Type: `string`

### aad\_tenant\_id

Description: The AAD tenant ID for the AAD AKS auth integration.

Type: `string`

### aks\_cluster\_sp\_app\_id

Description: The Application ID for the Service Principal to use for this Managed Kubernetes Cluster

Type: `string`

### aks\_cluster\_sp\_object\_id

Description: The Object ID for the Service Principal to use for this Managed Kubernetes Cluster

Type: `string`

### aks\_cluster\_sp\_secret

Description: The Client Secret for the Service Principal to use for this Managed Kubernetes Cluster

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### aks\_kubernetes\_version

Description: The Kubernetes Version of the AKS cluster.

Type: `string`

Default: `"1.12.5"`

### aks\_vm\_count

Description: Number of nodes in node pool.

Type: `string`

Default: `"3"`

### aks\_vm\_size

Description: VM Size of node pool.

Type: `string`

Default: `"Standard_DS2_v2"`

### azure\_container\_registry\_id

Description: If specified, gives the AKS cluster pull access rights to the provided ACR.

Type: `string`

Default: `""`

### create\_azure\_container\_registry

Description: Boolean flag, true: create new dedicated ACR, false: don't create dedicated ACR.

Type: `string`

Default: `"false"`

### external\_pip\_name

Description: If configured, the Azure Firewall resource will reference the externally create Puplic IP instead of creating a new one.

Type: `string`

Default: `""`

### external\_pip\_resource\_group

Description: If configured, the Azure Firewall resource will reference the externally create Puplic IP instead of creating a new one.

Type: `string`

Default: `""`

### location

Description: The Azure region in which all resources in this example should be provisioned.

Type: `string`

Default: `"West Europe"`

### location\_log\_analytics

Description: The Azure region for the Log Analytics Workspace.

Type: `string`

Default: `"West Europe"`

### prefix

Description: A prefix used for all resources in this example

Type: `string`

Default: `"contoso"`

### public\_ssh\_key\_path

Description: The Path at which your Public SSH Key is located. Defaults to ~/.ssh/id_rsa.pub

Type: `string`

Default: `"~/.ssh/id_rsa.pub"`

