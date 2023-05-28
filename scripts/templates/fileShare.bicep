@description('Specifies the name of the Azure Storage account.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the file share to be created.')
param fileShareName string

@description('Specifies the location in which the Azure Storage resources should be deployed.')
param location string = resourceGroup().location

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }

  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${sa.name}/default/${fileShareName}'
  properties: {
    enabledProtocols: 'SMB'
  }
}

output storageAccountName string = sa.name
output fileShareName string = fileShare.name
