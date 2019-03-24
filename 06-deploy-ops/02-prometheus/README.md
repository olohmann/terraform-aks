# Prometheus Helm installation
````sh
helm install stable/prometheus
````
Review the values.yaml to customize the deployment to your needs.
helm install --namespace ops --name prometheus stable/prometheus --name prometheus -f values.yaml

Further information:
https://github.com/helm/charts/tree/master/stable/prometheus
