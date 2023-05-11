param msiName string
param location string = resourceGroup().location

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31'={
  name: msiName
  location: location
}

output resourceId string = msi.id
output clientId string = msi.properties.clientId
output objectId string = msi.properties.principalId
output name string = msi.name
