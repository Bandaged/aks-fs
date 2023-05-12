#!/bin/bash
rgName=$1
rgName=${rgName:="test"}
deploymentName=$2
deploymentName=${deploymentName:="test"}

# get helm values from deployment
az deployment group show -g ${rgName} -n ${deploymentName} --query properties.outputs.helmValues.value > ../build/values.bicep.json || exit 1

# get helm secrets from key vault
vaultName=$(cat ../build/values.bicep.json | jq .fileshare.keyVault.vaultName)
secretName=$(cat ../build/values.bicep.json | jq .fileshare.keyVault.accountKey)
clusterName=$(az deployment group show -g ${rgName} -n ${deploymentName} --query properties.outputs.clusterName.value | tr -d '"')
cat <<EOF > ../build/secrets.bicep.yaml
fileshare:
   accountKey: "$(az keyvault secret show -n=${secretName} --vault-name=${vaultName})"
EOF
az aks get-credentials -g ${rgName} -n ${clusterName} -f ../build/aks.kubeconfig  || exit 1
