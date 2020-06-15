locals {
  frontdoor_backend_name            = "backend"
  frontdoor_default_hostname        = "${local.prefix_kebab}-${local.hash_suffix}.azurefd.net"
  frontend_endpoint_name_custom     = "frontend"
  frontend_endpoint_name_default    = "frontend-default"
  apply_frontdoor_hostname_bindings = "${var.custom_hostname_binding == "" ? false : true}"
  frontend_endpoint_names           = local.apply_frontdoor_hostname_bindings ? [local.frontend_endpoint_name_custom, local.frontend_endpoint_name_default] : [local.frontend_endpoint_name_default]
}

resource "azurerm_frontdoor" "fd" {
  name                                         = "${local.prefix_kebab}-${local.hash_suffix}"
  resource_group_name                          = azurerm_resource_group.rg.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "routing-rule-webapp"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = local.frontend_endpoint_names
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = local.frontdoor_backend_name
      cache_enabled       = true
    }
  }

  routing_rule {
    name               = "http-to-https-redirect"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = local.frontend_endpoint_names
    redirect_configuration {
      redirect_protocol = "HttpsOnly"
      custom_host       = local.apply_frontdoor_hostname_bindings ? var.custom_hostname_binding : local.frontdoor_default_hostname
      redirect_type     = "PermanentRedirect"
    }
  }

  backend_pool_load_balancing {
    name = "load-balancing"
  }

  /* Backend */
  backend_pool {
    name = local.frontdoor_backend_name
    backend {
      host_header = local.apply_frontdoor_hostname_bindings ? var.custom_hostname_binding : local.frontdoor_default_hostname
      address     = azurerm_public_ip.nginx_ingress_pip.fqdn
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "load-balancing"
    health_probe_name   = "health-probe"
  }

  backend_pool_health_probe {
    name     = "health-probe"
    path     = "/healthz"
    protocol = "Https"
  }

  frontend_endpoint {
    name                              = local.frontend_endpoint_name_default
    custom_https_provisioning_enabled = false
    host_name                         = local.frontdoor_default_hostname
  }

  dynamic "frontend_endpoint" {
    for_each = local.apply_frontdoor_hostname_bindings ? [true] : []

    content {
      name                                    = local.frontend_endpoint_name_custom
      host_name                               = var.custom_hostname_binding
      custom_https_provisioning_enabled       = true
      web_application_firewall_policy_link_id = azurerm_frontdoor_firewall_policy.waf.id

      custom_https_configuration {
        certificate_source                         = "AzureKeyVault"
        azure_key_vault_certificate_vault_id       = data.azurerm_key_vault.external_kv.id
        azure_key_vault_certificate_secret_name    = data.azurerm_key_vault_secret.external_kv_tls_cert.name
        azure_key_vault_certificate_secret_version = data.azurerm_key_vault_secret.external_kv_tls_cert.version
      }
    }
  }
}

resource "azurerm_frontdoor_firewall_policy" "waf" {
  name                = "waf${local.prefix_flat_short}"
  resource_group_name = azurerm_resource_group.rg.name
  enabled             = true
  mode                = var.waf_mode
  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
  }
}
