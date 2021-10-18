$ErrorActionPreference = "Stop"

function Register-ProGetPsGallery {

    [CmdletBinding(DefaultParameterSetName = "Credentials")]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Credentials")]
        [pscredential] $Credentials,

        [Parameter(Mandatory = $true, ParameterSetName = "UserPassword")]
        [string] $Username,

        [Parameter(Mandatory = $true, ParameterSetName = "UserPassword")]
        [securestring] $Password,

        [Parameter(Mandatory = $true)]
        [String] $SourceName,

        [Parameter(Mandatory = $true)]
        [String] $SourceLocation
    )

    if ($Username) {
        $Credentials = [pscredential]::new($Username, $Password)
    }
    Write-Host "Loading prerequisites ..."
    Install-Module PackageManagement -MinimumVersion 1.4.5
    Import-Module PackageManagement
    Install-Module PowerShellGet -MinimumVersion 2.2.1
    Import-Module PowerShellGet

    if ($ExistingSource) {
        Write-Host "Unregistering existing package source ..."
        Unregister-PackageSource -Name $SourceName -ProviderName NuGet -ErrorAction Ignore
        Unregister-PSRepository -Name $SourceName
    }

    Write-Host "Registering new package source ..."
    Register-PackageSource -Name EosProGet -Location $SourceLocation -Force -ProviderName NuGet -SkipValidate -Credential $creds | Out-Null
    Register-PSRepository -Name EosProGet -SourceLocation $SourceLocation -PublishLocation $SourceLocation -ScriptSourceLocation $SourceLocation -ScriptPublishLocation $SourceLocation -InstallationPolicy Trusted -Credential $Credentials

    Write-Host -ForegroundColor Green "The package source '$SourceName' has been registered."

}

$Params = @{
    SourceName     = "EosProGet"
    SourceLocation = "https://nuget.eos-solutions.it/nuget/PS"
}
if ($env:EOS_PROGET_USERNAME) {
    $Params.Add("Username", $env:EOS_PROGET_USERNAME)
    $Params.Add("Password", (ConvertTo-SecureString -AsPlainText $env:EOS_PROGET_PASSWORD -Force))
}
else {
    $creds = Get-Credential -Message "Enter your ProGet credentials"
    if (-not $creds) { throw "Credentials not provided." }
    $Params.Add("Credentials", $creds)
}
Register-ProGetPsGallery @Params