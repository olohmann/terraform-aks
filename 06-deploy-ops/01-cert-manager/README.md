# Cert Manager
https://github.com/helm/charts/tree/master/stable/cert-manager

following steps are requred according to https://github.com/jetstack/cert-manager/issues/1255

````bash
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
````

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
