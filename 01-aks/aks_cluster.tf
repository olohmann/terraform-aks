resource "azurerm_kubernetes_cluster" "aks" {
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  name                = local.prefix_kebab
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  default_node_pool {
    name                = var.aks_default_node_pool.name
    node_count          = var.aks_default_node_pool.node_count
    vm_size             = var.aks_default_node_pool.vm_size
    availability_zones  = var.aks_default_node_pool.availability_zones
    node_labels         = var.aks_default_node_pool.node_labels
    node_taints         = var.aks_default_node_pool.node_taints
    enable_auto_scaling = var.aks_default_node_pool.cluster_auto_scaling
    max_count           = var.aks_default_node_pool.cluster_auto_scaling_max_count
    min_count           = var.aks_default_node_pool.cluster_auto_scaling_min_count

    enable_node_public_ip = false

    os_disk_size_gb = 128
    max_pods        = 250

    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  dns_prefix = "${local.prefix_kebab}-aks-${local.hash_suffix}"

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.la_monitor_containers.id
    }

    azure_policy {
      enabled = var.aks_enable_azure_policy_support
    }
  }

  api_server_authorized_ip_ranges = []

  # auto_scaler_profile

  enable_pod_security_policy = var.aks_enable_pod_security_policy

  # Use a Managed Identity
  identity {
    type = "SystemAssigned"
  }

  kubernetes_version = var.aks_kubernetes_version

  linux_profile {
    admin_username = "azureuser"

    ssh_key {
      key_data = file(var.public_ssh_key_path)
    }
  }


  network_profile {
    network_plugin     = "azure"
    service_cidr       = local.aks_service_cidr
    docker_bridge_cidr = local.docker_bridge_cidr
    dns_service_ip     = local.aks_dns_service_ip
  }

  node_resource_group     = "${local.prefix_snake}_aks_nodes_rg"
  private_cluster_enabled = var.aks_private_cluster_enabled

  role_based_access_control {
    azure_active_directory {
      managed                = true
      admin_group_object_ids = var.aks_admin_group_object_ids
    }
    enabled = true
  }

  sku_tier = var.aks_sku_tier
}

resource "azurerm_kubernetes_cluster_node_pool" "aks_node_pool" {
  lifecycle {
    ignore_changes = [
      node_count
    ]
  }

  for_each = var.aks_additional_node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = substr(each.key, 0, 12)
  node_count            = each.value.node_count
  vm_size               = each.value.vm_size
  availability_zones    = each.value.availability_zones
  max_pods              = 250
  os_disk_size_gb       = 128
  os_type               = "Linux"
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  node_taints           = each.value.node_taints
  node_labels           = each.value.node_labels
  enable_auto_scaling   = each.value.cluster_auto_scaling
  min_count             = each.value.cluster_auto_scaling_min_count
  max_count             = each.value.cluster_auto_scaling_max_count
}
