param environmentPrefix string = 'mabrtest'
param location string = resourceGroup().location

module fileShareModule 'fileShare.bicep' = {
  name: 'file-share-storage-account'
  params: {
    fileShareName: 'fileshare'
    storageAccountName: '${environmentPrefix}sa'
    location: location
  }
}

module functionAppModule 'functionApp.bicep' = {
  name: 'function-app'
  params: {
    functionAppName: '${environmentPrefix}-func'
    applicationInsightsName: '${environmentPrefix}-ai'
    location: location
    destinationFileShareName: 'fileshare'
    destinationStorageAccountName: destinationStorageAccount.name
  }
  dependsOn: [
    destinationStorageAccount
  ]
}

resource destinationStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: fileShareModule.outputs.storageAccountName
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: functionAppModule.outputs.functionAppName
}

@description('This is the built-in Storage Blob Data Contributor role. See https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles')
resource storageBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: destinationStorageAccount
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

module rbacKVApplicationInsightsConnectionString './role-assignment-func-app-storage-account.bicep' = {
  name: 'deployment-rbac-storage'
  params: {
    roleDefinitionId: storageBlobDataContributor.id
    functionAppName: functionApp.name
    roleAssignmentNameGuid: guid(functionApp.id, destinationStorageAccount.id, storageBlobDataContributor.id)
    storageAccountName: destinationStorageAccount.name
  }
  dependsOn: [
    functionApp
  ]
}
