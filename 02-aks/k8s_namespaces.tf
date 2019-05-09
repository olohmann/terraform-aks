resource "kubernetes_namespace" "ops" {
    depends_on = ["azurerm_kubernetes_cluster.aks"]
  metadata {
    annotations {
      name = "ops-namespace"
    }

    labels {
      purpose = "operations"
    }

    name = "ops"
  }
}

resource "kubernetes_namespace" "dev" {
    depends_on = ["azurerm_kubernetes_cluster.aks"]
  metadata {
    annotations {
      name = "dev-namespace"
    }

    labels {
      purpose = "operations"
    }

    name = "dev"
  }
}

resource "kubernetes_namespace" "production" {
    depends_on = ["azurerm_kubernetes_cluster.aks"]
  metadata {
    annotations {
      name = "production-namespace"
    }

    labels {
      purpose = "production"
    }

    name = "production"
  }
}