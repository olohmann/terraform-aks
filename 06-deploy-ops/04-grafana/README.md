# Grafana
 ````´
 # customize the letsencrypt certificate settings in grafana-cert.yaml
 # create the certificate
 kubectl create -f grafana-cert.yaml

 # customize grafana-values.yaml with your domain etc
 # run the helm install
 helm install --namespace ops --name grafana stable/grafana -f grafana-values.yaml

