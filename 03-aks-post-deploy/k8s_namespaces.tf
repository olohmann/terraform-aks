resource "kubernetes_namespace" "ops" {
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
  metadata {
    annotations {
      name = "dev-namespace"
    }

    labels {
      purpose = "dev"
    }

    name = "dev"
  }
}

resource "kubernetes_namespace" "production" {
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
