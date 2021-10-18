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
        [String] $Location
    )

    if ($Username) {
        $Credentials = [pscredential]::new($Username, $Password)
    }

    Write-Host "Loading prerequisites ..."
    Install-Module PackageManagement -MinimumVersion 1.4.5
    Import-Module PackageManagement
    Install-Module PowerShellGet -MinimumVersion 2.2.1
    Import-Module PowerShellGet

    $ExistingSource = Get-PSRepository -Name $SourceName -ErrorAction Ignore
    if ($ExistingSource) {
        Write-Host "Unregistering existing package source ..."
        Unregister-PackageSource -Name $SourceName -ProviderName NuGet -ErrorAction Ignore
        Unregister-PSRepository -Name $SourceName
    }

    Write-Host "Registering new package source ..."
    Register-PackageSource -Name EosProGet -Location $Location -Force -ProviderName NuGet -SkipValidate -Credential $creds | Out-Null
    Register-PSRepository -Name EosProGet -SourceLocation $Location -PublishLocation $Location -ScriptSourceLocation $Location -ScriptPublishLocation $Location -InstallationPolicy Trusted -Credential $Credentials

    Write-Host -ForegroundColor Green "The package source '$SourceName' has been registered."

}