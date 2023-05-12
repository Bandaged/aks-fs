param saName string
param kvName string
param clusterName string
param podIdentityMsiName string
param clusterMsiName string
param location string = resourceGroup().location
param tenantId string = tenant().tenantId
param deployCluster bool =true
param deployKeyVault bool = true
param deployIdentity bool =true
param deployStorage bool =true
param deployUserRbac bool = true
param currentUserId string = ''
param currentUserPrincipalType string = 'User'

module clusterMsi 'modules/identity.bicep' ={
  name: 'cluster-id'
  params:{
    msiName: clusterMsiName
    location: location
    deploy: deployIdentity
  }
}

module podMsi 'modules/identity.bicep' ={
  name: 'pod-id'
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
    msiName: clusterMsi.outputs.name
  }
  dependsOn:[
    clusterMsi
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
    msiId: podMsi.outputs.objectId
  }
  dependsOn:[
    vault
    storage
    podMsi
  ]
}

module clusterMsiRbac 'modules/rbac.bicep'= if(deployCluster){
  name: 'cluster-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: clusterMsi.outputs.objectId
  }
  dependsOn:[
    vault
    storage
    clusterMsi
  ]
}
module kubeletRbac 'modules/rbac.bicep'= if(deployCluster){
  name: 'kubelet-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: cluster.outputs.kubeletMsiObjectId
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
output cluster object ={
  name: cluster.outputs.aksName
  identities:{
    controlPlane: {
      clientId: clusterMsi.outputs.clientId
      objectId: clusterMsi.outputs.objectId
      tenantId: clusterMsi.outputs.tenantId
    }
    kubelet:{
      clientId: cluster.outputs.kubeletMsiClientId
      objectId: cluster.outputs.kubeletMsiObjectId
    }
  }
}

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
  clusterIdentity: {
    resourceId: clusterMsi.outputs.resourceId
    objectId: clusterMsi.outputs.objectId
    clientId: clusterMsi.outputs.clientId
    tenantId: clusterMsi.outputs.tenantId
    name: clusterMsi.outputs.name
  }
  kubeletIdentity: {
    resourceId: cluster.outputs.kubeletMsiResourceId
    objectId: cluster.outputs.kubeletMsiObjectId
    clientId: cluster.outputs.kubeletMsiClientId
  }
  podIdentity:{
    resourceId: podMsi.outputs.resourceId
    objectId: podMsi.outputs.objectId
    clientId: podMsi.outputs.clientId
    tenantId: podMsi.outputs.tenantId
    name: podMsi.outputs.name
  }
}
