Import-Module Gordon

$WorkFolder = "$pwd\.work"
$SymbolCache = "$WorkFolder\Symbols"
New-Item -Path $SymbolCache -ItemType Directory -Force | Out-Null
Write-Host "Using symbol cache at '$SymbolCache'"
$WorkspaceFile = Get-ChildItem -Path $pwd -Filter "*.code-workspace" | Select-Object -First 1 -ExpandProperty FullName
Write-Host "Building workspace '$WorkspaceFile'"

Write-Host "::group::Preparing package manager"
$Uris = ConvertFrom-Json -InputObject (Get-Content -Raw -Path $PSScriptRoot\feeds.json)
$Feeds = @()
foreach ($Uri in $Uris) { 
    Write-Host "Using: $Uri"
    $Feeds += New-NugetPackageProvider -FeedUri $Uri -AuthenticationType None
}
$Feeds += New-NugetPackageProvider -OfficialBcFeed -LocaleId IT, W1

$PackageManager = Gordon\New-PackageManager -Provider $Feeds
$PackageManager.Provider | Out-Host
Write-Host "::endgroup::"

Write-Host "::group::Downloading symbols"
$SymbolResult = Gordon\Download-Symbols `
    -PackageManager $PackageManager `
    -OutputFolder $SymbolCache `
    -Source PackageManager `
    -Path $WorkspaceFile `
    -IgnoreFailures
$SymbolResult | Out-Host
Write-Host "::endgroup::"

Write-Host "::group::Retrieving AL compiler"
$AlcFolder = "$WorkFolder\Alc"
$Alc = Gordon\Get-AlCompiler -RootFolder $AlcFolder
$Alc.Folder.FullName
Write-Host "::endgroup::"

$BuildConfiguration = [Eos.Nav.Al.AlcBuildConfiguration] @{
    Options = @{
        AlcFolder           = $Alc.Folder
        PackageCacheFolders = @(
            $SymbolCache
        )
    }
}

Write-Host "::group::Build Configuration"
$BuildConfiguration | ConvertTo-Json -Depth 3 | Out-Host
Write-Host "Counter API: $env:COUNTER_API_URI"
Write-Host "::endgroup::"

$Callback = {
    param($BuildConfiguration, [Eos.Nav.Al.AlProject] $Project)
    # set the version for each project
    $Major = $Project.Version.Major
    $Minor = $Project.Version.Minor
    $Patch = 0
    $BuildConfiguration.Metadata.Version = "$Major.$Minor.$Patch.0"
    Write-Host "Assigned version $($BuildConfiguration.Metadata.Version) to project $($Project.Name)"
}

$OutputFolder = "$WorkFolder\output"
Write-Host "Building into '$OutputFolder'"
$ResultList = Gordon\Invoke-Build `
    -Path $WorkspaceFile `
    -OutputFormat Full `
    -OutputFolder $OutputFolder `
    -Configuration $BuildConfiguration `
    -ProjectCallback $Callback

$FailedResultList = $ResultList | Where-Object { !$_.IsSuccess }
$FailedResultCount = $FailedResultList | Measure-Object | Select-Object -ExpandProperty Count -First 1
$ResultList | Out-Host
if ($FailedResultCount -gt 0) {
    throw "$FailedResultCount project(s) failed to build."
}