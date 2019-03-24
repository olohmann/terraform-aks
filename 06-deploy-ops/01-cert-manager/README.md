# Cert Manager
https://github.com/helm/charts/tree/master/stable/cert-manager

````bash
helm install --name cert-manager --namespace cert-manager --set rbac.create=true stable/cert-manager --set ingressShim.extraArgs='{--default-issuer-name=letsencrypt-prod,--default-issuer-kind=ClusterIssuer}'
````

````bash
kubectl create -f
00-prod-issuer.yaml  
01-staging-issuer.yaml
````

helpful for troubelshooting:
kubectl describe clusterissuers
