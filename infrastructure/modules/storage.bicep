param saName string
param shareName string = 'cache'
param location string = resourceGroup().location
param deploy bool =true

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01'= if(deploy){
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

resource existingSas  'Microsoft.Storage/storageAccounts@2022-09-01'existing = if(!deploy){
  name: saName
  resource existingFileServices 'fileServices' existing ={
    name: 'default'
    resource existingFs 'shares' existing ={
      name: shareName
    }
  }
}

output saName string = deploy ? sa.name : existingSas.name
output saId string =  deploy ? sa.id :existingSas.id

output shareName string =deploy ? sa::fileServices::fs.name : existingSas::existingFileServices::existingFs.name
output shareId string =deploy ? sa::fileServices::fs.id: existingSas::existingFileServices::existingFs.id
