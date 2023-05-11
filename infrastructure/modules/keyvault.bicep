
param kvName string
param location string = resourceGroup().location
param tenantId string = tenant().tenantId
param skuName string = 'standard'
param skufamily string = 'A'
param properties object ={
  enableSoftDelete: false
  softDeleteRetentionInDays: 0
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' ={
  name: kvName
  location: location
  properties:{
    enableSoftDelete: properties.enableSoftDelete
    softDeleteRetentionInDays: properties.softDeleteRetentionInDays
    sku: {
      family: skufamily
      name: skuName
    }
    tenantId: tenantId
  }
}

output id string = kv.id
output name string = kv.name
output tenantId string = kv.properties.tenantId
