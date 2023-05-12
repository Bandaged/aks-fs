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

helm upgrade --kubeconfig ../build/aks.kubeconfig --install test ../charts/test -f ../charts/test/values.yaml -f ../charts/test/secrets.yaml  -f ../charts/test/secrets.yaml  -f ../build/secrets.test.yaml --dry-run --debug
