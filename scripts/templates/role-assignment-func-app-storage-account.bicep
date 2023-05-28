param storageAccountName string
param roleAssignmentNameGuid string
param roleDefinitionId string
param functionAppName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = {
   name: functionAppName
}

resource keyVaultWebAppServiceReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentNameGuid
  scope: storageAccount
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
