# Grafana

* customise `grafana-values.yaml`  
 `helm install --namespace ops --name grafana stable/grafana -f grafana-values.yaml`

# set grafana root url
````yaml
server:
 root_url: 
````
# Azure Monitor Integration

https://grafana.com/plugins/grafana-azure-monitor-datasource

## requires sp for azure monitor & log analytics

az ad sp create-for-rbac -n 

# SSO with Azure AD

modify this section in values yaml
````yaml
auth.generic_oauth:
  name: Azure AD
  enabled: true
  allow_sign_up: true
  client_id: <application id>
  client_secret: <key value>
  scopes: openid email name
  auth_url: https://login.microsoftonline.com/<directory id>/oauth2/authorize
  token_url: https://login.microsoftonline.com/<directory id>/oauth2/token
  api_url:
  team_ids:
  allowed_organizations:
````