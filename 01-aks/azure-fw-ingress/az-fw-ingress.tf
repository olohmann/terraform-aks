resource "helm_release" "nginx_ingress_release" {
  name       = "nginx-ingress"
  chart      = "stable/nginx-ingress"
  namespace  = "${var.ingress_namespace}" 

  values = [
    "${file("${path.module}/ingress_values.yaml")}"
  ]

  set {
    name  = "controller.replicaCount"
    value = "3"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }
}

# TODO: Replace once the Terraform Firewall Resource for DNAT is available.
resource "null_resource" "azure_firewall_ingress_dnat_http" {
  provisioner "local-exec" {
    when    = "destroy"
    command = "$(pwd)/az-firewall-delete-dnat-rule.sh"

    environment {
      __VERBOSE             ="6"
      RESOURCE_GROUP_NAME   ="${var.resource_group}"
      FIREWALL_NAME         ="${var.azure_firewall_name}"
      COLLECTION_NAME       ="Ingress_HTTP"
    }
  }

  provisioner "local-exec" {
    command = "export TRANSLATED_ADDRESS=$(kubectl get svc --selector app=nginx-ingress --selector component=controller -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}') && $(pwd)/azure-fw-ingress/az-firewall-create-dnat-rule.sh"

    environment {
      __VERBOSE                 ="6"
      RESOURCE_GROUP_NAME       ="${var.resource_group}"
      FIREWALL_NAME             ="${var.azure_firewall_name}"
      COLLECTION_NAME           ="Ingress_HTTP"
      PRIORITY                  ="200"
      RULE_NAME                 ="Ingress_HTTP"
      DESTINATION_ADDRESSES     ="${var.azure_firewall_pip}"
      DESTINATION_PORT          ="80"
      SOURCE_ADDRESSES          ="${var.allowed_ingress_source_addresses}"
      TRANSLATED_PORT           ="80"
    }
  }
  
  depends_on = ["helm_release.nginx_ingress_release"]
}

resource "null_resource" "azure_firewall_ingress_dnat_https" {
    provisioner "local-exec" {
    when    = "destroy"
    command = "$(pwd)/azure-fw-ingress/az-firewall-delete-dnat-rule.sh"

    environment {
      __VERBOSE             ="6"
      RESOURCE_GROUP_NAME   ="${var.resource_group}"
      FIREWALL_NAME         ="${var.azure_firewall_name}"
      COLLECTION_NAME       ="Ingress_HTTPS"
    }
  }

  provisioner "local-exec" {
    command = "export TRANSLATED_ADDRESS=$(kubectl get svc --selector app=nginx-ingress --selector component=controller -o=jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}') && $(pwd)/azure-fw-ingress/az-firewall-create-dnat-rule.sh"

    environment {
      __VERBOSE                 ="6"
      RESOURCE_GROUP_NAME       ="${var.resource_group}"
      FIREWALL_NAME             ="${var.azure_firewall_name}"
      COLLECTION_NAME           ="Ingress_HTTPS"
      PRIORITY                  ="210"
      RULE_NAME                 ="Ingress_HTTPS"
      DESTINATION_ADDRESSES     ="${var.azure_firewall_pip}"
      DESTINATION_PORT          ="443"
      SOURCE_ADDRESSES          ="${var.allowed_ingress_source_addresses}"
      TRANSLATED_PORT           ="443"
    }
  }
  
  depends_on = ["helm_release.nginx_ingress_release", "null_resource.azure_firewall_ingress_dnat_http"]
}
