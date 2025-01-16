# BUSINESS_PROGRAM - PRODUCT - MAJOR_VERSION
**Azure Bicep Infrastucture Pipeline**

[![Build Status](https://dev.azure.com/AACN-DPS/Architecture/_apis/build/status%2Faacn-assessments-api-ci?branchName=main)](https://dev.azure.com/AACN-DPS/Architecture/_build/latest?definitionId=24&branchName=main)

**Product Pipelines**

[![Build Status](https://dev.azure.com/AACN-DPS/Architecture/_apis/build/status%2Faacn-assessments-api-cd?branchName=main)](https://dev.azure.com/AACN-DPS/Architecture/_build/latest?definitionId=26&branchName=main)

## Product Overview
| Product Info             | Description                      |
|--------------------------|----------------------------------|
| Business Program         |                                  |
| Product Name             |                                  |
| Product Version          |                                  |
| Purpose                  |                                  |
| Context Diagram          | ./docs/context-diagram.vsdx      |
| Systems Architecture     | ./docs/system-architecture.vsdx  |
| ERD (optional)           | ./docs/erd.vsdx                  |
| JSON Payloads (optional) | ./docs/payloads.vsdx             |


## Repository Overview

| Folder          | Description                                             |
|-----------------|---------------------------------------------------------|
| .azure          | Azure Bicep Infrastructure as code                      |
| .azure-devops   | Azure DevOps CI/CD pipelines                            |
| .nuget          | nuget.config file for feeds                             |
| docs            | Documentation and images                                |
| src             | Clean architecture core, presentation and infrastructure|
| test            | Unit and/or integration tests                           |


# Getting-Started with Development
To get started, follow the steps below:
1. [Install Prerequisites](# Install-Prerequisites)
2. Clone repository
3. Open solution in Visual Studio Community 2022 or above, or Visual Studio Code
4. Set Presentation project as startup

## Install Prerequisites
You will need the following tools:
### Visual Studio
[Visual Studio Workload IDs](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022&preserve-view=true)
```
winget install --id Microsoft.VisualStudio.2022.Community --override "--quiet --add Microsoft.Visualstudio.Workload.Azure --add Microsoft.VisualStudio.Workload.Data --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb"
```
### Or VS Code (code .)
```
winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
```

### .NET SDK
```
winget install Microsoft.DotNet.SDK.8 --silent
```

### dotnet ef cli
Install
```
dotnet tool install --global dotnet-ef
```
Update
```
dotnet tool update --global dotnet-ef
```
Remember to add the following package to appropriate project
```
dotnet add package Microsoft.EntityFrameworkCore.Design
```

### SQL Server
Visual Studio installs SQL Express. If you want full-featured SQL Server, install the SQL Server Developer Edition or above.

[SQL Server Developer Edition or above](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)

## Configure API Key and Connection String
Follow these steps to get your development environment set up:

### ASPNETCORE_ENVIRONMENT set to "Local" in launchsettings.json
1. This project uses the following ASPNETCORE_ENVIRONMENT to set configuration profile
- Debugging uses Properties/launchSettings.json
- launchSettings.json is set to Local, which relies on appsettings.Local.json
2. As a standard practice, set ASPNETCORE_ENVIRONMENT entry in your Enviornment Variables and restart Visual Studio
	```
	Set-Item -Path Env:ASPNETCORE_ENVIRONMENT -Value "Development"
	Get-Childitem env:
	```	
  
### Setup your SQL Server connection string
```
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "YOUR_SQL_CONNECTION_STRING"
```
## Create SQL Server Database
### dotnet ef migrate steps

1. Open Windows Terminal in Powershell or Cmd mode
2. cd to root of repository
3. (Optional) If you have an existing database, scaffold current entities into your project
	
	```
	dotnet ef dbcontext scaffold "Data Source=localhost;Initial Catalog=semantickernelmicroservice;Min Pool Size=3;MultipleActiveResultSets=True;Trusted_Connection=Yes;TrustServerCertificate=True;" Microsoft.EntityFrameworkCore.SqlServer -t WeatherForecastView -c WeatherChannelContext -f -o WebApi
	```

4. Create an initial migration
	```
	dotnet ef migrations add InitialCreate --project .\src\Infrastructure.SqlServer\Infrastructure.SqlServer.csproj --startup-project .\src\Presentation.WebApi\Presentation.WebApi.csproj --context SemanticKernelContext
	```

5. Develop new entities and configurations
6. When ready to deploy new entities and configurations
   
	```	
	dotnet ef database update --project .\src\Infrastructure.SqlServer\Infrastructure.SqlServer.csproj --startup-project .\src\Presentation.WebApi\Presentation.WebApi.csproj --context SemanticKernelContext --connection "Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=SemanticKernelMicroservice;Min Pool Size=3;MultipleActiveResultSets=True;Trusted_Connection=Yes;TrustServerCertificate=True;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30"
	```
7. When an entity changes, is created or deleted, create a new migration. Suggest doing this each new version.
	```
	dotnet ef migrations add v1.0.0.1 --project .\src\Infrastructure\SqlServer\Infrastructure.SqlServer.csproj --startup-project .\src\Presentation\WebApi\Presentation.WebApi.csproj --context SemanticKernelContext
	```
## Running the Application
### Launch the backend
Right-click Presentation.WebApi and select Set as Default Project
```
dotnet run Presentation.WebApi.csproj
```

### Open http://localhost:7777/swagger/index.html 
Open Microsoft Edge or modern browser
Navigate to: http://localhost:7777/swagger/index.html in your browser to the Swagger API Interface

# Technologies
* [ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/introduction-to-aspnet-core)
* [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/)
* [MediatR](https://github.com/jbogard/MediatR)
* [AutoMapper](https://automapper.org/)
* [Specflow](https://specflow.org/)
* [FluentValidation](https://fluentvalidation.net/)
* [FluentAssertions](https://fluentassertions.com/)
* [Moq](https://github.com/moq)

## Additional Technologies References
* AspNetCore.HealthChecks.UI
* Entity Framework Core
* FluentValidation.AspNetCore
* Microsoft.AspNetCore.App
* Microsoft.AspNetCore.Cors
* Swashbuckle.AspNetCore.SwaggerGen
* Swashbuckle.AspNetCore.SwaggerUI

# Governance and Process Assets
* [Sprint 0 Process]()
* [Event Storming Context Diagram Template]()
* [Coding Standards]()
* [PR Checklist]()

# Version History

| Version | Date | Release Notes |
|----------|----------|----------|
| 1.0.0 |  | Initial Release |
| 1.1.0 |  | First major feature |
