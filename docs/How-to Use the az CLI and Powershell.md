# How-to: Login to Azure, set tenant, set subsciption and logout
| Command | az CLI | Powershell |
|:-------------|:--------:|--------------:|
| Login interactive | az login | Connect-AzAccount |
| Login non-interactive | az login --user <myAlias@myCompany.com> --password <myPassword> | Connect-AzAccount -Credential $Credentials |
| Login and set tenant | az login --tenant <myTenantID> | Connect-AzAccount -TenantId "<tenant-id>" |
| Set subscription | az account set --subscription "<subscription_id_or_name>" | Set-AzContext -SubscriptionId "<subscription_id>" |
| Logout | az logout | Clear-AzContext |


# How-to: View current login info and tenant list
| Command | az CLI | Powershell |
|:-------------|:--------:|--------------:|
| Show session details | az account show | Get-AzContext |
| List tenants   | az account tenant list | Get-AzTenant |

# How-to: View and create resource groups
| Command | az CLI | Powershell |
|:-------------|:--------:|--------------:|
| Show resource group | az group show --name <resource_group_name> | Get-AzResourceGroup -Name <resource_group_name> |
| Create resource group | az group create --name <resource_group_name> --location <azure_region> | New-AzResourceGroup -Name <resource_group_name> -Location "<azure_region>" |

# How-to: Validate and Deploy Bicep files
| Command | az CLI | Powershell |
|:-------------|:--------:|--------------:|
| Validate Bicep file and params | az deployment group what-if --parameters "<parameterfile_json_or_bicep>" --resource-group rg-assessment-dev-001 --template-file .azure/main-landingzone-appservice.bicep | Get-AzContext |
| Deploy Bicep file and params | az deployment group create --parameters "<parameterfile_json_or_bicep>" --resource-group rg-assessment-dev-001 --template-file .azure/main-landingzone-appservice.bicep | Get-AzContext |

## Example: az deployment group what-if
```
az deployment group what-if --parameters .azure-devops/variables/Dev.parameters.json --resource-group rg-myproduct-dev-001 --template-file .azure/main-landingzone-appservice.bicep
```

