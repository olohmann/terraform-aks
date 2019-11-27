resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.prefix_snake}-aks"
  location            = "${azurerm_resource_group.rg.location}"
  dns_prefix          = "${local.prefix_snake}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  kubernetes_version  = "${var.aks_kubernetes_version}"

  linux_profile {
    admin_username = "azureuser"

    ssh_key {
      key_data = "${file(var.public_ssh_key_path)}"
    }
  }

  agent_pool_profile {
    name            = "agentpool"
    count           = "${var.aks_vm_count}"
    vm_size         = "${var.aks_vm_size}"
    os_type         = "Linux"
    os_disk_size_gb = 30

    vnet_subnet_id = "${azurerm_subnet.aks_subnet.id}"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      client_app_id = "${var.aad_client_app_id}"
      
      server_app_id     = "${var.aad_server_app_id}"
      server_app_secret = "${var.aad_server_app_secret}"

      tenant_id = "${var.aad_tenant_id}"
    }
  }

  service_principal {
    client_id     = "${var.aks_cluster_sp_app_id}"
    client_secret = "${var.aks_cluster_sp_secret}"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr = "${local.aks_service_cidr}"
    docker_bridge_cidr = "${local.docker_bridge_cidr}"
    dns_service_ip = "${local.aks_dns_service_ip}"
  }

  addon_profile {
    oms_agent {
      enabled = true
      log_analytics_workspace_id = "${azurerm_log_analytics_workspace.la_monitor_containers.id}"
    }

    azure_policy {
      enabled = true
    }
  }
}
