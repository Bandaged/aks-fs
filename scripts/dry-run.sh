
mkdir ../build

cat <<EOF > ../build/values.test.yaml
fileshare:
  shareName: testshare2123
  accountName: testaccount312312
  accountKey: test-eqwe123123123
  keyVault:
    vaultName: test-vault-name-3123
    accountName: test-sa-name
    accountKey: test-sa-key
podIdentity:
  name: testuser
  resourceId: test
  clientId: test
  selector: test
EOF

cat <<EOF > ../build/secrets.test.yaml
fileshare:
  accountName: test-secret-key-value
EOF

az bicep build -f ../infrastructure/main.bicep --outfile ../build/main.json || exit 1

az deployment group validate -g ${rgName:-test} --template-file ../build/main.json -p ../infrastructure/main.parameters.json || exit 1


helm upgrade --install ../charts/test -f ../charts/test/values.yaml -f ../charts/test/secrets.yaml  -f ../charts/test/secrets.yaml  -f ../build/secrets.test.yaml --dry-run --debug