####################################################################################
# To execute
#   1. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   2. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   3. In powershell, run script: 
#      .\Generate-NswagClientCode.ps1 -IPAddress 111.222.333.4444 -ServerId 12345 -ApiKey 00000000-0000-0000-0000-000000000000 -ApiId 12345
####################################################################################

param (
 	[string]$SwaggerJsonPath = 'swagger',
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$ApiAssembly = $(throw '-ApiAssembly is a required parameter.'),
	[string]$ApiVersion = 'v1',
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[string]$ClientPathFile = $(throw '-ClientPathFile is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[string]$ClientNamespace = $(throw '-ClientNamespace is a required parameter.')
)
####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'Continue'
####################################################################################

$swaggerJsonPathFile = "$SwaggerJsonPath/$ApiVersion/swagger.json"

# Setup tools
dotnet new tool-manifest --force

# Set environment vars necessary for WebApi to run
$env:ASPNETCORE_ENVIRONMENT = "Development"

# Generate swagger.json
dotnet tool install swashbuckle.aspnetcore.cli
dotnet swagger tofile --output $swaggerJsonPathFile $ApiAssembly $ApiVersion

# Generate class
dotnet tool install Nswag.ConsoleCore
nswag openapi2csclient `
    /input:$swaggerJsonPathFile `
    /output:$ClientPathFile `
    /namespace:$ClientNamespace

# If need to customize, use this command line with the json file
#nswag run Generate-NswagClientCode.json
