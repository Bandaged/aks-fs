
param clusterName string
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string ='aks'

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'standard_d2s_v3'

param deploy bool = true
param useWorkloadIdentity bool = false
param usePodIdentity bool = true

resource aks 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = if(deploy) {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    dnsPrefix: dnsPrefix
    podIdentityProfile:{
      enabled: usePodIdentity
    }
    networkProfile:{
      networkPlugin:'azure'
    }
    publicNetworkAccess: 'Enabled'
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
    securityProfile:{
      workloadIdentity: {
        enabled: useWorkloadIdentity
      }
    }
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

resource existingCluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' existing = if(!deploy) {
  name: clusterName
}

output aksName string = deploy ? aks.name : existingCluster.name
output aksId string = deploy ? aks.id : existingCluster.id
output msiTenantId string = deploy ? aks.identity.tenantId : existingCluster.identity.tenantId
output msiId string = deploy ? aks.identity.principalId : existingCluster.identity.principalId
output kubeletMsiObjectId string = deploy ? aks.properties.identityProfile.kubeletIdentity.objectId : existingCluster.properties.identityProfile.kubeletIdentity.objectId
output kubeletMsiClientId string = deploy ? aks.properties.identityProfile.kubeletIdentity.clientId : existingCluster.properties.identityProfile.kubeletIdentity.clientId
output kubeletMsiResourceId string = deploy ? aks.properties.identityProfile.kubeletIdentity.resourceId : existingCluster.properties.identityProfile.kubeletIdentity.resourceId
