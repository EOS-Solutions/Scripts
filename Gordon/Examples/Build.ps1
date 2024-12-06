## This is a script that will build an AL project using Gordon without the need for any artifacts or compilers or extensions.
## Gordon will: 
## - download the correct ALC compiler
## - use NuGet or any other supported feed for downloading symbols
## - build the project

$ErrorActionPreference = "Stop"
#Import-Module Gordon

### define some variables
$AlcCacheFolder = "$env:temp\AlcCache"
$ProjectFolder = "path/to/project"
$SymbolCache = "$env:temp\.packges"
$ProjectFolder = $pwd

Write-Host "Loading project '$ProjectFolder'"
$Project = Gordon\Get-AlProject `
    -Path $ProjectFolder `
    -SkipSymbolLoading <# this speeds up project loading. the symbols will not be loaded, but we also do not really need them right now #>

Write-Host "Retrieving ALC compiler $($Project.RuntimeVersion)"
$Alc = Gordon\Get-AlCompiler `
    -ExactVersion $Project.RuntimeVersion <# use the projects runtime version to decide which compiler to use #> `
    -RootFolder $AlcCacheFolder <# where do we place and cache our ALC compilers? #>
$AlcFolder = $Alc.Folder
Write-Host "Using '$AlcFolder'"

Write-Host "Constructing package providers"
$Providers = @()

# Firstly, add any custom package feed
# The reason why it is added first is because the order in which you add the providers is the order in which they will be queried.
# Most probably you want to query your custom feed first, and then the official BC feed, because your feed will most probably contain less packages and will thus be faster.
$Providers += Gordon\New-NugetPackageProvider -FeedUri "https://some.nuget.feed.com"

# Then, add the official BC feed
# Note the multiple localizations. We want to first query a specific one, and then fallback to W1.
$Providers += Gordon\New-NugetPackageProvider `
    -OfficialBcFeed <# this is the feed to the BC official nuget packages #>`
    -LocaleId IT, W1 <# first use locale IT, then fallback to W1 #>

# Build the package manager.
# Note that you can specify multiple providers, and the order in which you specify them is the order in which they will be queried.
# For each package, the first one that yields a positive result will be used.
Write-Host "Building package manager"
$PackageManager = Gordon\New-PackageManager -Provider $Providers

# This is optional.
# You can use this to specify any additional / override apps that you want to download symbols for
# In this case we are downloading the symbols for the 25.0 version of "Application", regardless of what the project specifies
$OverrideApps = @(
    [Eos.Nav.Al.Packaging.SimpleAppPackage]::CreateApplication("25.0")
)

Write-Host "Downloading symbols to '$SymbolCache'"
Gordon\Download-Symbols `
    -PackageManager $PackageManager <# the package manager where to get packages from #> `
    -Source PackageManager <# make sure we only download from the package manager and not from any service #> `
    -Path $Project.Folder <# where does our project live? #> `
    -OutputFolder $SymbolCache <# where do we want to place our symbols? #> `
    -AdditionalPackages $OverrideApps <# this is a list of additional packages to download symbols. Anything you specify here overrides the project. #> `
| Out-Null

# the build configuration file allows for a lot of customization
# the full specificationof what properties are supported is available here:
# https://github.com/EOS-Solutions/Defaults/blob/master/Schemas/alc/v1/buildconfig.json
$BuildConfiguration = [Eos.Nav.Al.AlcBuildConfiguration] @{
    Metadata                = @{
        Version = "6.6.6.0" # this is the version number that will be built
    }
    Options                 = @{
        AlcFolder           = $AlcFolder # the path to the ALC compiler
        PackageCacheFolders = @(
            $SymbolCache # where to look for symbols
        )
    }
    ExcludePatterns         = @( # exclude this folder from compilation
        "Test"
    )
    IncludeTestDependencies = $false # remove test dependencies, should they be set
}

Write-Host "Now Building"
$PackagePath = Gordon\Invoke-Build `
    -Path $Project.Folder <# path to the project to build #> `
    -OutputFormat FilePath <# this will make the cmdlet return the path to built package instead of the package itself #> `
    -Configuration $BuildConfiguration <# The configuration to use when building #>

Write-Host "Package built at '$PackagePath'"