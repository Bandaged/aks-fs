
param clusterName string
param location string = resourceGroup().location

param podIdentities array
@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string =''

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 3

@description('The size of the Virtual Machine.')
param agentVMSize string = 'standard_d2s_v3'


resource aks 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    dnsPrefix: dnsPrefix
    podIdentityProfile:{
      enabled: true
      userAssignedIdentities: podIdentities
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
    storageProfile:{
      blobCSIDriver:{
        enabled: true
      }
      diskCSIDriver:{
        enabled: true
      }
      fileCSIDriver:{
        enabled: true
      }
    }
  }
}


output aksName string = aks.name
output aksId string = aks.id
output msiId string = aks.identity.principalId
