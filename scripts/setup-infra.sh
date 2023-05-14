#!/bin/bash
if [ -f ../.env ]; then
 echo "setting default values from .env file"
 source ../.env
fi

# set values from arguments, with defaults from .env if set, otherwise hard coded defaults
rgName=${1:-${rgName:-"test"}}
deploymentName=${2:-${deploymentName:-"test"}}
location=${2:-${location:-"uksouth"}}
podIdNs=${3:-${podIdNs:-"default"}}

echo "Resource group $rgName"
echo "Location $location"
echo "Deployment group $deploymentName"

# get current user id
userId="$(az ad signed-in-user show --query id -o tsv)"

# check output directory
if [ -f ../build ]; then
   >&2 echo "Build should be a directory, not a File"
   exit 1
elif [ ! -d ../build ]; then
    echo "Creating Build directory"
    dir ../build
fi

# setup resource group
if [ $(az group exists -n ${rgName}) = false ]; then
    echo "Creating Resource group"
    az group create -n ${rgName} --l ${location}
fi 

# check bicep
az bicep build -f ../infrastructure/main.bicep --outfile ../build/main.json || exit 1
az deployment group validate \
    -g ${rgName} \
    --template-file ../build/main.json \
    -p ../infrastructure/main.parameters.json \
    -p currentUserId=$userId || exit 1

# deploy with current user id so they can get secret afterwards
az deployment group create \
    -g ${rgName} \
    -n ${deploymentName} \
    --template-file ../build/main.json \
    -p ../infrastructure/main.parameters.json \
    -p currentUserId=$userId || exit 1

# add pod identiy, since it is an issue adding it a creation according to the internet
clusterName=$(az deployment group show --query properties.outputs.cluster.value.name | tr -d '"')
podIdName=$(az deployment group show --query properties.outputs.helmValues.value.podIdentity.name | tr -d '"')
podIdResourceId=$(az deployment group show --query properties.outputs.helmValues.value.podIdentity.resourceId | tr -d '"')
az aks pod-identity add \
    -g ${rgName} \
    --cluster-name ${clusterName} \
    --namespace ${podIdNs} \
    --name ${podIdName} \
    --identity-resource-id ${podIdResourceId}