# Azure Open Service Broker API (OSBA) Install

````bash
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install svc-cat/catalog --name catalog --namespace catalog \
   --set apiserver.storage.etcd.persistence.enabled=true \
   --set apiserver.healthcheck.enabled=false \
   --set controllerManager.healthcheck.enabled=false \
   --set apiserver.verbosity=2 \
   --set controllerManager.verbosity=2
````

````bash
helm repo add azure https://kubernetescharts.blob.core.windows.net/azure
helm install azure/open-service-broker-azure --name osba --namespace osba \
  --set azure.subscriptionId=$AZURE_SUBSCRIPTION_ID \
  --set azure.tenantId=$AZURE_TENANT_ID \
  --set azure.clientId=$AZURE_CLIENT_ID \
  --set azure.clientSecret=$AZURE_CLIENT_SECRET
````
