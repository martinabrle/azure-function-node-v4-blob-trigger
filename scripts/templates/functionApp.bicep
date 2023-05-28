//https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.web/function-app-linux-consumption/README.md
@description('The name of the Azure Function app.')
param functionAppName string

@description('The name of the AppInsights.')
param applicationInsightsName string

@description('The name of the destination storage account.')
param destinationStorageAccountName string

@description('The name of the destination file share.')
param destinationFileShareName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The zip content url.')
param packageUri string = '1'

var hostingPlanName = '${functionAppName}-plan'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${substring(replace(replace(functionAppName, '-', ''), '_', ''), 0, 4)}${uniqueString(resourceGroup().id)}sa'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource destinationStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: destinationStorageAccountName
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'linux'
  properties: {
    maximumElasticWorkerCount: 1
    reserved: true
  }
}

resource applicationInsight 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', functionAppName)}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    reserved: true
    serverFarmId: hostingPlan.id
 
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'Node|18'
      acrUseManagedIdentityCreds: false
      //alwaysOn: true - can only be set for dedicated hosting plans
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0

      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsight.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsight.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsDashboard'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'AzureWebJobsFeatureFlags'
          value: 'EnableWorkerIndexing'
        }
        {
          name: 'DESTINATION_STORAGE_ACCOUNT_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${destinationStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${destinationStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'DESTINATION_FILE_SHARE_NAME'
          value: destinationFileShareName
        }        
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: packageUri
        }
      ]
    }
  }
  dependsOn: [
    destinationStorageAccount
  ]
}

output functionAppName string = functionApp.name
