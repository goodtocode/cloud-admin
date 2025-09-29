####################################################################################
# To execute
#   1. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   2. Change directory to the script folder:
#      CD src (wherever your script is)
#   3. In powershell, run script: 
#      .\Get-CodeCoverage.ps1 -TestProjectFilter 'MyTests.*.csproj' -ProdPackagesOnly -ProductionAssemblies 'MyApp.Core','MyApp.Web'
# This script is for local use to analyze code coverage in more detail using HTML report.
####################################################################################

Param(
    [string]$TestProjectFilter = '*Specs*.csproj',    
    [switch]$ProdPackagesOnly = $false,    
    [string[]]$ProductionAssemblies = @(
        "*.Core.Application",
        "*.Presentation.WebApi",
        "*.Presentation.Blazor"
    )
)
####################################################################################
if ($IsWindows) {Set-ExecutionPolicy Unrestricted -Scope Process -Force}
$VerbosePreference = 'SilentlyContinue' # 'Continue'
####################################################################################

& dotnet tool install -g coverlet.console
& dotnet tool install -g dotnet-reportgenerator-globaltool

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$scriptPath = Get-Item -Path $PSScriptRoot
$coverageOutputPath = Join-Path $scriptPath "TestResults\Coverage\$timestamp"
$reportOutputPath = Join-Path $scriptPath "TestResults\Reports\$timestamp"

New-Item -ItemType Directory -Force -Path $coverageOutputPath
New-Item -ItemType Directory -Force -Path $reportOutputPath 

$testProjects = Get-ChildItem $scriptPath -Filter $TestProjectFilter -Recurse
Write-Host "Found $($testProjects.Count) test projects in $scriptPath that match $TestProjectFilter."
if($testProjects.Count -eq 0)
{
    stop
}

foreach ($project in $testProjects) {
    $testProjectPath = $project.FullName
    Write-Host "Running tests for project: $($testProjectPath)"

    $frameworkDir = Get-ChildItem -Path (Join-Path $project.Directory.FullName "bin\Debug") -Directory | Where-Object { $_.Name -like "net*" } | Sort-Object Name -Descending | Select-Object -First 1
    $buildOutput = Join-Path -Path $frameworkDir.FullName -ChildPath "$($project.BaseName).dll"
    $coverageFile = Join-Path $coverageOutputPath "coverage.cobertura.xml"
    Write-Host "Analyzing code coverage for: $buildOutput"
    coverlet $buildOutput --target "dotnet" --targetargs "test $($project.FullName) --no-build" --format cobertura --output $coverageFile

}

# Generate HTML report
if ($ProdPackagesOnly) {
    $assemblyFilters = ($ProductionAssemblies | ForEach-Object { "+$_" }) -join ";"
    $assemblyFilters = ($ProductionAssemblies | ForEach-Object { "+$_" }) -join ";"
    & reportgenerator -reports:"$coverageOutputPath/**/coverage.cobertura.xml" -targetdir:$reportOutputPath -reporttypes:Html -assemblyfilters:$assemblyFilters
}
else {
    & reportgenerator -reports:"$coverageOutputPath/**/coverage.cobertura.xml" -targetdir:$reportOutputPath -reporttypes:Html
}

Write-Host "Code coverage report generated at: $reportOutputPath"

$reportIndexHtml = Join-Path $reportOutputPath "index.html"
Invoke-Item -Path $reportIndexHtml