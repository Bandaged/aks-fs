#!/bin/bash
rgName=$1
rgName=${rgName:="test"}
deploymentName=$2
deploymentName=${deploymentName:="test"}

# get helm values from deployment
az deployment group show -g ${rgName} -n ${deploymentName} --query properties.outputs.helmValues.value > ../build/values.bicep.json || exit 1

# get helm secrets from key vault
vaultName=$(cat ../build/values.bicep.json | jq .keyVault.vaultName | tr -d '"')
secretName=$(cat ../build/values.bicep.json | jq .keyVault.accountKey | tr -d '"')
clusterName=$(az deployment group show -g ${rgName} -n ${deploymentName} --query properties.outputs.cluster.value.name | tr -d '"')
cat <<EOF > ../build/secrets.bicep.yaml
fileshare:
   accountKey: $(az keyvault secret show -n=${secretName} --vault-name=${vaultName} | jq .value)
EOF
az aks get-credentials -g ${rgName} -n ${clusterName} -f ../build/aks.kubeconfig  || exit 1
