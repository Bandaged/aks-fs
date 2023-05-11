param kvName string
param saName string
param accountKeySecretName string = 'cache-sa-key'
param accountNameSecretName string = 'cache-sa-name'
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
}

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: saName
}

resource key 'Microsoft.KeyVault/vaults/secrets@2023-02-01' ={
  parent: kv
  name: accountKeySecretName
  properties:{
    value: sa.listKeys().keys[0].value
  }
}

resource name 'Microsoft.KeyVault/vaults/secrets@2023-02-01' ={
  parent: kv
  name: accountNameSecretName
  properties:{
    value: sa.name
  }
}


output accountNameSecretName string = name.name
output accountNameSecretId string = name.id

output accountKeySecretName string = key.name
output accountKeySecretId string = key.id

output accountName string = sa.name
