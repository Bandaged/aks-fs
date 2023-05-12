param msiName string
param location string = resourceGroup().location
param deploy bool =true

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31'= if(deploy){
  name: msiName
  location: location
}

resource existingMsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing= if(!deploy){
  name: msiName
}
output resourceId string = deploy ? msi.id : existingMsi.id
output clientId string =  deploy ? msi.properties.clientId :  existingMsi.properties.clientId
output objectId string = deploy ?  msi.properties.principalId : existingMsi.properties.principalId
output name string =  deploy ? msi.name : existingMsi.name
output tenantId string = deploy ? msi.properties.tenantId : existingMsi.properties.tenantId
