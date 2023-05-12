#!/bin/bash
rgName=$1
rgName=${rgName:="test"}
mkdir ../build

cat <<EOF > ../build/values.test.yaml
keyVault:
  vaultName: test-vault-name-3123
  accountName: test-sa-name
  accountKey: test-sa-key
  tenantId: test
fileshare:
  shareName: testshare2123
  accountName: testaccount312312
  accountKey: test-eqwe123123123
podIdentity:
  name: testuser
  resourceId: test
  clientId: test
  selector: test
  tenantId: test
  workloadIdentity: false
EOF

cat <<EOF > ../build/secrets.test.yaml
fileshare:
  accountName: test-secret-key-value
EOF

az bicep build -f ../infrastructure/main.bicep --outfile ../build/main.json

az deployment group validate -g ${rgName:-test} --template-file ../build/main.json -p ../infrastructure/main.parameters.json

helm upgrade --install ../charts/test -f ../charts/test/values.yaml -f ../charts/test/secrets.yaml  -f ../charts/test/secrets.yaml  -f ../build/secrets.test.yaml --dry-run --debug