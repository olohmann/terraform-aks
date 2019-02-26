data "azurerm_subscription" "current" {}
resource "local_file" "app_gw_helm_config" {
  content = <<EOF
appgw:
    subscriptionId: ${data.azurerm_subscription.current.id}
    resourceGroup: ${azurerm_resource_group.rg.name}
    name: ${azurerm_application_gateway.ingress_app_gw.name}

kubernetes:
  watchNamespace: default

armAuth:
    type: aadPodIdentity
    identityResourceID: ${azurerm_user_assigned_identity.app_gw_identity.id}
    identityClientID: ${azurerm_user_assigned_identity.app_gw_identity.client_id}

rbac:
    enabled: true

aksClusterConfiguration:
    apiServerAddress: ${azurerm_kubernetes_cluster.aks.fqdn}

applicationGatewayKubernetesIngress:
    serviceaccountname: ingress-sa
EOF

  filename = "${path.module}/../03-aks-post-deploy-ingress/app_gw_ingress_helm_config.generated.yaml"
}
