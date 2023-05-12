
clientId=$(cat ../minikube.bicep.json | jq .clientId)
tenantId=$(cat ../minikube.bicep.json | jq .tenantId)
username=$(cat ../minikube.bicep.json | jq .username)
minikube start \
--extra-config=apiserver.Authentication.OIDC.ClientID="spn:$clientId" \
--extra-config=apiserver.Authentication.OIDC.IssuerURL="https://sts.windows.net/$tenantId" \
--extra-config=apiserver.Authentication.OIDC.UsernameClaim="upn" \
--extra-config=apiserver.Authorization.Mode=RBAC

# add secret store csi
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system

# add file csi driver

# add azure workload identity

# add azure pod identity

kubectl create clusterrolebinding azure-ad-admin -clusterrole=cluster-admin --user=https://sts.windows.net/$tenantId/$userName