param saName string
param kvName string
param clusterName string
param podIdentityMsiName string
param location string = resourceGroup().location
param tenantId string = tenant().tenantId
param podIdentityNamespace string ='default'
param podIdentityName string ='default'
param podIdentitySelector string = 'default'

module podIdentity 'modules/podIdentity.bicep' ={
  name: 'identity'
  params:{
    msiName: podIdentityMsiName
    location: location
  }
}

module cluster 'modules/cluster.bicep' ={
  name: 'cluster'
  params:{
    clusterName: clusterName
    location: location
    podIdentities: [
      {
        bindingSelector: podIdentitySelector
        identity:{
          clientId: podIdentity.outputs.clientId
          objectId: podIdentity.outputs.objectId
          resourceId: podIdentity.outputs.resourceId
        }
        name: podIdentityName
        namespace: podIdentityNamespace
      }
    ]
  }
  dependsOn:[
    podIdentity
  ]
}

module storage 'modules/storage.bicep' ={
  name: 'storage'
  params:{
     saName: saName
     location: location
  }
}

module vault 'modules/keyvault.bicep' ={
  name: 'vault'
  params:{
    kvName: kvName
    location: location
    tenantId: tenantId
  }
}


module secrets 'modules/secret.bicep' ={
  name: 'secrets'
  params: {
    kvName: vault.outputs.name
    saName: storage.outputs.saName
  }
  dependsOn:[
    storage
    vault
  ]
}

module rbac 'modules/rbac.bicep'={
  name: 'rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    podIdentityId:podIdentity.outputs.resourceId
    clusterMsiId: cluster.outputs.msiId
  }
  dependsOn:[
    vault
    storage
    podIdentity
    cluster
  ]
}

output fileshare object ={
  shareName: storage.outputs.shareName
  accountName: storage.outputs.saName
  keyVault:{
    vaultName: vault.outputs.name
    tenantId: vault.outputs.tenantId
    accountName: secrets.outputs.accountNameSecretName
    accountKey: secrets.outputs.accountKeySecretName
  }
}

output podIdentity object = {
  id: podIdentity.outputs.resourceId
  name: podIdentity.outputs.name
}
