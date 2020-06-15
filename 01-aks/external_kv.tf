data "azurerm_key_vault" "external_kv" {
  name                = var.external_kv_name
  resource_group_name = var.external_kv_resource_group_name
}

data "azurerm_key_vault_secret" "external_kv_tls_cert" {
  name         = var.external_kv_cert_name
  key_vault_id = data.azurerm_key_vault.external_kv.id
}

