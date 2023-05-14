param saName string
param kvName string
param vmName string
param clusterName string
param podIdentityMsiName string
param workloadIdentityMsiName string
param location string = resourceGroup().location
param tenantId string = tenant().tenantId
param includeVm bool = true
param includeCluster bool = true
param includePodIdentity bool = true
param includeWorkloadIdentity bool = true
param includeSpn bool = true

param deployVm bool = true
param deployCluster bool =true
param deployKeyVault bool = true
param deployPodIdentity bool =true
param deployWorkloadIdentity bool =true
param deployStorage bool =true
param deployUserRbac bool = true
param podIdentityEnabled bool =true
param workloadIdentityEnabled bool = true
param spnIdentityEnabled bool = true
param vmIdentityEnabled bool = true
param currentUserId string = ''
param currentUserPrincipalType string = 'User'

module podMsi 'modules/identity.bicep' =if(includePodIdentity) {
  name: 'pod-id'
  params:{
    msiName: podIdentityMsiName
    location: location
    deploy: deployPodIdentity
  }
}

module workloadMsi 'modules/identity.bicep' = if(includeWorkloadIdentity){
  name: 'workload-id'
  params:{
    msiName: workloadIdentityMsiName
    location: location
    deploy: deployWorkloadIdentity
  }
}

module vm 'modules/vm.bicep' = if(includeVm) {
  name: 'vm'
  params:{
    vmName: vmName
    deploy: deployVm
  }
}

module cluster 'modules/cluster.bicep' = if(includeCluster) {
  name: 'cluster'
  params:{
    clusterName: clusterName
    location: location
    deploy: deployCluster
    usePodIdentity: podIdentityEnabled
    useWorkloadIdentity: workloadIdentityEnabled
  }
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

module podIdRbac 'modules/rbac.bicep'= if(includePodIdentity){
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

module workloadIdRbac 'modules/rbac.bicep'= if(includeWorkloadIdentity){
  name: 'workload-id-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: workloadMsi.outputs.objectId
  }
  dependsOn:[
    vault
    storage
    workloadMsi
  ]
}

module clusterMsiRbac 'modules/rbac.bicep'= if(includeCluster){
  name: 'cluster-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: cluster.outputs.aksMsiPrincipalId
  }
  dependsOn:[
    vault
    storage
    cluster
  ]
}

module clusterSpnRbac 'modules/rbac.bicep' = if(includeCluster) {
  name: 'cluster-spn-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: cluster.outputs.spnClientId
  }
  dependsOn:[
    vault
    storage
    cluster
  ]
}

module vmRbac 'modules/rbac.bicep' = if(includeVm) {
  name: 'vm-rbac'
  params:{
    kvName: vault.outputs.name
    saName: storage.outputs.saName
    shareName: storage.outputs.shareName
    msiId: vm.outputs.spnClientId
  }
  dependsOn:[
    vault
    storage
    vm
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
  dependsOn:[
    vault
    storage
  ]
}
// cluster details
output cluster object = includeCluster ?{
  name: cluster.outputs.aksName
  identities:{
    controlPlane: {
      clientId: cluster.outputs.aksMsiPrincipalId
      tenantId: cluster.outputs.aksMsiTenantId
    }
    kubelet:{
      clientId: cluster.outputs.kubeletMsiClientId
      objectId: cluster.outputs.kubeletMsiObjectId
    }
  }
} :{}

// virtual machine details
output vm object = includeVm ? {
  name: vm.outputs.name
  ip: vm.outputs.ip
  identity:{
    clientId: vm.outputs.spnClientId
    tenantId: vm.outputs.spnTenantId
  }
} : {}

// helm values.json
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
  
  podIdentity: (includePodIdentity ? {
    resourceId: podMsi.outputs.resourceId
    objectId: podMsi.outputs.objectId
    clientId: podMsi.outputs.clientId
    tenantId: podMsi.outputs.tenantId
    name: podMsi.outputs.name
    enabled: podIdentityEnabled
  } : {
    enabled: false
  })

  vmIdentity:(includeVm ?{
    clientId: vm.outputs.spnClientId
    tenantId: vm.outputs.spnTenantId
    enabled: vmIdentityEnabled
  } :{ enabled: false })
  
  spnIdentity:(includeCluster && includeSpn ?{
    clientId: cluster.outputs.spnClientId
    secret: cluster.outputs.spnClientsecret
    enabled: spnIdentityEnabled
  } :{ enabled: false})

  workloadIdentity: (includeWorkloadIdentity ?{
    resourceId: workloadMsi.outputs.resourceId
    objectId: workloadMsi.outputs.objectId
    clientId: workloadMsi.outputs.clientId
    tenantId: workloadMsi.outputs.tenantId
    name: workloadMsi.outputs.name
    enabled: workloadIdentityEnabled
  } :{ enabled:false })

  vanilla: {
    accountName: storage.outputs.saName
  }
}
