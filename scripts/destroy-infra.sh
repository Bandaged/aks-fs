#!/bin/bash
rgName=${1:="test"}

echo "Resource group $rgName"
# delete resouce group
az group delete -g ${rgName} || exit 1

# delete bicep files
rm ../build/values.bicep.json
rm ../build/secrets.bicep.yaml
rm ../build/aks.kubeconfig