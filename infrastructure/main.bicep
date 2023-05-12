param saName string
param kvName string
param clusterName string
param podIdentityMsiName string
param location string = resourceGroup().location
param tenantId string = tenant().tenantId
param podIdentityNamespace string ='default'
param podIdentityName string ='default'
param podIdentitySelector string = 'default'
param deployCluster bool =true

module podIdentity 'modules/identity.bicep' ={
  name: 'identity'
  params:{
    msiName: podIdentityMsiName
    location: location
  }
}

module cluster 'modules/cluster.bicep' = if(deployCluster) {
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

module podIdRbac 'modules/rbac.bicep'={
  name: 'pod-id-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId:podIdentity.outputs.resourceId
  }
  dependsOn:[
    vault
    storage
    podIdentity
  ]
}

module clusterRbac 'modules/rbac.bicep'= if(deployCluster){
  name: 'cluster-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: cluster.outputs.msiId
  }
  dependsOn:[
    vault
    storage
    cluster
  ]
}


output clusterId string = deployCluster ? cluster.outputs.aksName : ''
output clusterMsiId string = deployCluster ? cluster.outputs.msiId : ''
output clusterName string = deployCluster ? cluster.outputs.aksName : ''

output helmValues object = {
  keyVault:{
    vaultName: vault.outputs.name
    tenantId: vault.outputs.tenantId
    accountName: secrets.outputs.accountNameSecretName
    accountKey: secrets.outputs.accountKeySecretName
  }
  fileshare:{
    shareName: storage.outputs.shareName
    accountName: storage.outputs.saName
  }
  podIdentity:{
    resourceId: podIdentity.outputs.resourceId
    objectId: podIdentity.outputs.objectId
    clientId: podIdentity.outputs.clientId
    tenantId: podIdentity.outputs.tenantId
    name: podIdentity.outputs.name
  }
}
