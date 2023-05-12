
local clientId=$(cat ../minikube.bicep.json | jq .clientId)
local tenantId=$(cat ../minikube.bicep.json | jq .tenantId)
local username=$(cat ../minikube.bicep.json | jq .username)
minikube start \
--extra-config=apiserver.Authentication.OIDC.ClientID="spn:$clientId" \
--extra-config=apiserver.Authentication.OIDC.IssuerURL="https://sts.windows.net/$tenantId" \
--extra-config=apiserver.Authentication.OIDC.UsernameClaim="upn" \
--extra-config=apiserver.Authorization.Mode=RBAC \
--extra-config=kubeconfig=../build/mk.kubeconfig

minikube 

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system

kubectl create clusterrolebinding azure-ad-admin -clusterrole=cluster-admin --user=https://sts.windows.net/$tenantId/$userName