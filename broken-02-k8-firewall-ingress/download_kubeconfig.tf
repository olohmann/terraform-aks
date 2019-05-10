# Always recreate this resource.
resource "null_resource" "get_kubeconfig" {
  triggers = {
    input = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --admin --overwrite-existing"
  }
}
