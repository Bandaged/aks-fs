
clientId=$(cat ../minikube.bicep.json | jq .clientId)
tenantId=$(cat ../minikube.bicep.json | jq .tenantId)
username=$(cat ../minikube.bicep.json | jq .username)

# start with workload identity setup
minikube start \
--extra-config=apiserver.Authentication.OIDC.ClientID="spn:$clientId" \
--extra-config=apiserver.Authentication.OIDC.IssuerURL="https://sts.windows.net/$tenantId" \
--extra-config=apiserver.Authentication.OIDC.UsernameClaim="upn" \
--extra-config=apiserver.Authorization.Mode=RBAC

# add secret store csi
helm upgrade \
    csi-secrets-store \
    secrets-store-csi-driver/secrets-store-csi-driver \
    --namespace kube-system \
    --install \
    --set=secrets-store-csi-driver.syncSecret.enabled=true \
    --set=syncSecret.enabled=true \
    --debug

# add file csi driver
helm upgrade \
    azurefile-csi-driver \
    azurefile-csi-driver/azurefile-csi-driver \
    --namespace kube-system \
    --install \
    --debug

# add azure pod identity
helm upgrade \
    aad-pod-identity \
    aad-pod-identity/aad-pod-identity \
    --install \
    --debug

# add azure ad admin
kubectl create clusterrolebinding \
    azure-ad-admin \
    --clusterrole=cluster-admin \
    --user=https://sts.windows.net/$tenantId/$userName