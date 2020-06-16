resource "azurerm_public_ip" "nginx_ingress_pip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg.location
  name                = local.prefix_kebab
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  sku                 = "Standard"
  domain_name_label   = "${local.prefix_kebab}-${local.hash_suffix}"
}

data "external" "converted_cert" {
  program = ["bash", "${path.root}/pfx_cert_conversion.sh"]

  query = {
    pfx_base64 = data.azurerm_key_vault_secret.external_kv_tls_cert.value
  }

  // output: data.external.certs.result.public_key_base64, data.external.certs.result.private_key_base64
}

// TODO: header filter in Nginx
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    annotations = {
      name = "nginx-ingress"
    }

    name = "nginx-ingress"
  }
}

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  chart     = "nginx-ingress"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  namespace = kubernetes_namespace.nginx_ingress.metadata[0].name

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = azurerm_public_ip.nginx_ingress_pip.resource_group_name
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.nginx_ingress_pip.ip_address
  }

  set {
    name  = "controller.extraArgs.default-ssl-certificate"
    value = "$(POD_NAMESPACE)/${kubernetes_secret.nginx_ingress_default_ssl_certificate.metadata[0].name}"
  }

  depends_on = [kubernetes_secret.nginx_ingress_default_ssl_certificate]
}

resource "kubernetes_secret" "nginx_ingress_default_ssl_certificate" {

  metadata {
    name      = "default-ssl-certificate"
    namespace = kubernetes_namespace.nginx_ingress.metadata[0].name
  }

  data = {
    // Decode to avoid double encoding as the 'kubernetes_secret' provider automatically encodes in base64
    "tls.crt" = base64decode(data.external.converted_cert.result.public_key_base64)
    "tls.key" = base64decode(data.external.converted_cert.result.private_key_base64)
  }

  type = "Opaque"
}
