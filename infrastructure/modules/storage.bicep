param saName string
param shareName string = 'cache'
param location string = resourceGroup().location

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01'={
  name: saName
  location: location
  kind: 'StorageV2'
  sku:{
    name: 'Standard_ZRS'
  }
  resource fileServices 'fileServices'={
    name: 'default'
    resource fs 'shares' ={
      name: shareName
    }
  }
}

output saName string = sa.name
output saId string = sa.id

output shareName string = sa::fileServices::fs.name
output shareId string = sa::fileServices::fs.id
