param podIdentityId string
param clusterMsiId string

param kvName string
param saName string
param shareName string

param clusterKeyVaultRoleName string ='aks-kv-access'
param podIdentityKeyVaultRoleName string ='pod-id-kv-access'
param clusterStorageRoleName string ='aks-sa-access'
param podIdentityStorageRoleName string ='pod-id-sa-access'

var kvUserRoleId ='4633458b-17de-408a-b874-0445c86b69e6'

var fsRoleId ='0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing ={
  name: kvName
}

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01' existing ={
  name: saName
  resource fileServices 'fileServices' existing ={
    name: 'default'
    resource share 'shares' existing ={
      name: shareName
    }
  }
}

resource keyVaultRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing={
  name: kvUserRoleId
}

resource fileShareRole  'Microsoft.Authorization/roleDefinitions@2022-04-01' existing={
  name: fsRoleId
}

resource clusterKeyVaultRoles 'Microsoft.Authorization/roleAssignments@2022-04-01'={
  name: clusterKeyVaultRoleName
  scope: kv
  properties:{
    principalId: clusterMsiId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultRole.id
  }
}
resource podIdentityKeyVaultRoles 'Microsoft.Authorization/roleAssignments@2022-04-01'={
  name: podIdentityKeyVaultRoleName
  scope: kv
  properties:{
    principalId: podIdentityId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultRole.id
  }
}

resource clusterStorageRoles 'Microsoft.Authorization/roleAssignments@2022-04-01'={
  name: clusterStorageRoleName
  scope: sa::fileServices::share
  properties:{
    principalId: clusterMsiId
    principalType: 'ServicePrincipal'
    roleDefinitionId: fileShareRole.id
  }
}

resource podIdentityStorageRoles 'Microsoft.Authorization/roleAssignments@2022-04-01'={
  name: podIdentityStorageRoleName
  scope: sa::fileServices::share
  properties:{
    principalId: podIdentityId
    principalType: 'ServicePrincipal'
    roleDefinitionId: fileShareRole.id
  }
}


