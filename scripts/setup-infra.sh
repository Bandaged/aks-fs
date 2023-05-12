#!/bin/bash
rgName=$1
rgName=${rgName:="test"}
deploymentName=$2
deploymentName=${deploymentName:="test"}
location=$3
location=${location:="uksouth"}
userId="$(az ad signed-in-user show --query id -o tsv)"
echo "Resource group $rgName"
echo "Location $location"
echo "Deployment group $deploymentName"

mkdir ../build
az group create -n ${rgName} --l ${location}
# setup infrastructure
az bicep build -f ../infrastructure/main.bicep --outfile ../build/main.json || exit 1
az deployment group validate -g ${rgName} --template-file ../build/main.json -p ../infrastructure/main.parameters.json -p currentUserId=$userId || exit 1
az deployment group create -g ${rgName} -n ${deploymentName} --template-file ../build/main.json -p ../infrastructure/main.parameters.json -p currentUserId=$userId || exit 1

userId=az ad signed-in-user show --query id -o tsv