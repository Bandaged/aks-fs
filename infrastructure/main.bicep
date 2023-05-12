param saName string
param kvName string
param clusterName string
param podIdentityMsiName string
param location string = resourceGroup().location
param tenantId string = tenant().tenantId
param deployCluster bool =true
param deployKeyVault bool = true
param deployIdentity bool =true
param deployStorage bool =true
param deployUserRbac bool = true
param currentUserId string = ''
param currentUserPrincipalType string = 'User'

module podIdentity 'modules/identity.bicep' ={
  name: 'identity'
  params:{
    msiName: podIdentityMsiName
    location: location
    deploy: deployIdentity
  }
}

module cluster 'modules/cluster.bicep' = if(deployCluster) {
  name: 'cluster'
  params:{
    clusterName: clusterName
    location: location
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
     deploy: deployStorage
  }
}

module vault 'modules/keyvault.bicep' ={
  name: 'vault'
  params:{
    kvName: kvName
    location: location
    tenantId: tenantId
    deploy: deployKeyVault
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
    msiId: podIdentity.outputs.objectId
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

module currentUserRbac 'modules/rbac.bicep' = if(length(currentUserId) > 0 && deployUserRbac){
  name: 'user-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: currentUserId
    principalType: currentUserPrincipalType
  }
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
