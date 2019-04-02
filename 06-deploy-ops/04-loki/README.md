# Deploy Loki to Kubernetes with Helm

## Prerequisites

Make sure you have the helm configure on your cluster:

```bash
$ helm init
```

Clone `grafana/loki` repository and navigate to `production helm` directory:

```bash
$ git clone https://github.com/grafana/loki.git
$ cd loki/production/helm
```

## Deploy Loki and Promtail to your cluster

```bash
$ helm install . -n loki --namespace <YOUR-NAMESPACE>
```

# Add the loki datasource in grafana
Point the grafana datasource to loki.ops.svc.cluster.local
