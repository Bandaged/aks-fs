
param kvName string
param location string = resourceGroup().location
param tenantId string = tenant().tenantId
param skuName string = 'standard'
param skufamily string = 'A'
param enableSoftDelete bool = false
param softDeleteRetentionInDays int = 7
param deploy bool =true

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = if(deploy){
  name: kvName
  location: location
  properties:{
    enableSoftDelete: enableSoftDelete
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    sku: {
      family: skufamily
      name: skuName
    }
    tenantId: tenantId
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    accessPolicies:[]
  }
}

resource existingKv  'Microsoft.KeyVault/vaults@2023-02-01' existing = if(!deploy){
  name: kvName
}

output id string = deploy ? kv.id : existingKv.id
output name string = deploy ? kv.name : existingKv.name
output tenantId string = deploy ? kv.properties.tenantId : existingKv.properties.tenantId
