param msiId string

param kvName string
param saName string
param shareName string

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

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01'={
  name: guid(kv.id, msiId, keyVaultRole.id)
  scope: kv
  properties:{
    principalId: msiId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultRole.id
  }
}
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01'={
  name: guid(kv.id, msiId, keyVaultRole.id)
  scope: sa::fileServices::share
  properties:{
    principalId: msiId
    principalType: 'ServicePrincipal'
    roleDefinitionId: fileShareRole.id
  }
}


