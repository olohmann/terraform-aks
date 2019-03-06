## Required Inputs

The following input variables are required:

### azure\_firewall\_name

Description: Name of the Azure Firewall. Required to configure the DNat settings for the ingress controller.

Type: `string`

### azure\_firewall\_pip

Description: Public IP Address of the Azure Firewall. Required to configure the DNat settings for the ingress controller.

Type: `string`

### azure\_firewall\_resource\_group\_name

Description: Name of the Azure Firewall Resource Group. Required to configure the DNat settings for the ingress controller.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### allowed\_ingress\_source\_addresses

Description: Allowed source addresses for ingress. Format either '*' for all or a space separated list '1.1.1.1 1.1.1.1/20'

Type: `string`

Default: `"*"`

### ingress\_namespace

Description:

Type: `string`

Default: `"default"`

