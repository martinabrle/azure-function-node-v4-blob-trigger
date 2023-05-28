create a new resource group using
```
az group create -n GGGGGG_rg -l BBBB --tags "delete_nightly=true"
```
where "GGGGGG_rg" is the resource groups's name (for example ```msfunc_v4_rg```) and "BBB"" is the deployment location (for example ```eastus```).

deploy the bicep template using
```
az deployment group create -g  GGGGGG-rg --template-file ../scripts/templates/main.bicep --parameter environmentPrefix=AAAA --location=BBBB
```

where "AAAA" is the prefix of all deployed artifacts (example: ```msfuncnew```) and "BBB"" is the deployment location (for example ```eastus```). Location can be safely omitted as it will be initialised from the resource group

use
```
func azure functionapp publish mabrtest-func --settings AzureWebJobsFeatureFlags=EnableWorkerIndexing
```
to deploy the Azure Function with JavaScript programming model 4 triggers.