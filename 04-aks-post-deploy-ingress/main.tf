data "template_file" "helm_values" {
  template = "${file("${path.module}/ingress_values.template.yaml")}"
  vars = {
    replicaCount = "2"
    hasInternalLoadBalancer = "${var.deploy_azure_firewall}"
    loadBalancerIP = "${data.azurerm_public_ip.firewall_data_pip.ip_address}"
    publicIpResourceGroupName = "${var.external_pip_resource_group != "" ? var.external_pip_resource_group : data.azurerm_public_ip.firewall_data_pip.resource_group_name}"
  }
}

resource "helm_release" "nginx_ingress_release" {
  name      = "nginx-ingress"
  chart     = "stable/nginx-ingress"
  namespace = "${var.ingress_namespace}"

  values = ["${data.template_file.helm_values.rendered}"]
}

data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name = "nginx-ingress-controller"
  }

  depends_on = ["helm_release.nginx_ingress_release"]
}

# TODO: Replace once the Terraform Firewall Resource for DNAT is available.
resource "null_resource" "azure_firewall_ingress_dnat_http" {
  count = "${var.deploy_azure_firewall == "true" ? 1 : 0}"
  provisioner "local-exec" {
    when    = "destroy"
    command = "$(pwd)/az-firewall-delete-dnat-rule.sh"

    environment = {
      __VERBOSE           = "6"
      RESOURCE_GROUP_NAME = "${local.firewall_resource_group_name}"
      FIREWALL_NAME       = "${local.firewall_name}"
      COLLECTION_NAME     = "Ingress_HTTP"
    }
  }

  provisioner "local-exec" {
    command = "export TRANSLATED_ADDRESS=${data.kubernetes_service.nginx_ingress_controller.load_balancer_ingress.0.ip} && $(pwd)/az-firewall-create-dnat-rule.sh"

    environment = {
      __VERBOSE             = "6"
      RESOURCE_GROUP_NAME   = "${local.firewall_resource_group_name}"
      FIREWALL_NAME         = "${local.firewall_name}"
      COLLECTION_NAME       = "Ingress_HTTP"
      PRIORITY              = "200"
      RULE_NAME             = "Ingress_HTTP"
      DESTINATION_ADDRESSES = "${local.firewall_pip}"
      DESTINATION_PORT      = "80"
      SOURCE_ADDRESSES      = "${var.allowed_ingress_source_addresses}"
      TRANSLATED_PORT       = "80"
    }
  }

  depends_on = ["helm_release.nginx_ingress_release"]
}

resource "null_resource" "azure_firewall_ingress_dnat_https" {
  count = "${var.deploy_azure_firewall == "true" ? 1 : 0}"
  provisioner "local-exec" {
    when    = "destroy"
    command = "$(pwd)/az-firewall-delete-dnat-rule.sh"

    environment = {
      __VERBOSE           = "6"
      RESOURCE_GROUP_NAME = "${local.firewall_resource_group_name}"
      FIREWALL_NAME       = "${local.firewall_name}"
      COLLECTION_NAME     = "Ingress_HTTPS"
    }
  }

  provisioner "local-exec" {
    command = "export TRANSLATED_ADDRESS=${data.kubernetes_service.nginx_ingress_controller.load_balancer_ingress.0.ip} && $(pwd)/az-firewall-create-dnat-rule.sh"

    environment = {
      __VERBOSE             = "6"
      RESOURCE_GROUP_NAME   = "${local.firewall_resource_group_name}"
      FIREWALL_NAME         = "${local.firewall_name}"
      COLLECTION_NAME       = "Ingress_HTTPS"
      PRIORITY              = "210"
      RULE_NAME             = "Ingress_HTTPS"
      DESTINATION_ADDRESSES = "${local.firewall_pip}"
      DESTINATION_PORT      = "443"
      SOURCE_ADDRESSES      = "${var.allowed_ingress_source_addresses}"
      TRANSLATED_PORT       = "443"
    }
  }

  depends_on = ["helm_release.nginx_ingress_release", "null_resource.azure_firewall_ingress_dnat_http"]
}
