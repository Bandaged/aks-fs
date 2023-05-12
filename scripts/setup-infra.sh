
local rgName=${1:-test}
local deploymentName=${2:-test}

mkdir ../build
# setup infrastructure
az bicep build -f ../infrastructure/main.bicep --outfile ../build/main.json
az deployment group validate -g ${rgName} --template-file ../build/main.json -p ../infrastructure/main.parameters.json || exit 1
az deployment group create -g ${rgName} -n ${deploymentName} --template-file ../build/main.json -p ../infrastructure/main.parameters.json  || exit 1

# get helm values from deployment
az deployment group show -g ${rgName} -n ${deploymentName} --query properties.outputs.helmValues > ../build/values.bicep.json || exit 1

# get helm secrets from key vault
local vaultName=$(cat ../build/values.bicep.json | jq .fileshare.keyVault.vaultName)
local secretName=$(cat ../build/values.bicep.json | jq .fileshare.keyVault.accountKey)
local clusterName=$(az deployment group show -g ${rgName} -n ${deploymentName} --query properties.outputs.clusterName)
cat <<EOF > ../build/secrets.bicep.yaml
fileshare:
   accountKey:"$(az keyvault secret show -n ${secretName} --vault-name ${vaultName})"
EOF
az aks get-credentials -n ${clusterName} -f ../build/aks.kubeconfig  || exit 1
