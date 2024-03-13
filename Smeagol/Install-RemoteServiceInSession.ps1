<#
.SYNOPSIS
    Installs the remote service in the specified container.
#>
function Install-RemoteServiceInSession {

    param(
        # Specifies the container name where to install the service.
        [Parameter(Mandatory = $true)]
        [String] $ContainerName,

        # Specifies the target path inside the opened session where to put the service.
        # If this is not specified, a default path is used.
        [Parameter(Mandatory = $false)]
        [String] $TargetPath,

        [Parameter(Mandatory = $false)]
        [string] $SourceFeed = "tools-labs",

        # Specifies the credentials to use to download the package.
        [Parameter(Mandatory = $false)]
        [pscredential] $Credentials,

        # If specified, the service is started, should it be already installed but stopped
        [Parameter(Mandatory = $false)]
        [switch] $EnsureRunning
    )

    $PackageName = "Bare.WebApi"

    if (-not $TargetPath) {
        $TargetPath = "C:\Run"
    }
    $SourceUri = "https://nuget.eos-solutions.it/upack/$SourceFeed/download/$($PackageName)?contentOnly=zip&latest"

    if (-not $Credentials) { 
        $Credentials = Get-Credential -Message "Enter domain credentials for $(([uri]$SourceUri).Authority)"
    }

    $Service = Invoke-ScriptInBcContainer -ContainerName $ContainerName -ScriptBlock {
        try {
            return Get-Service -Name "Bare.WebApi"
        }
        catch {
            return $null
        }
    }

    if (-not $Service) {
        $InstallRequired = $true
    }
    else {
        if (-not $EnsureRunning) {
            Write-Host "Service '$($Service.Name)' already exists. Exiting ..."
            return
        }
    }

    if ($Service.Status -ieq "Running") {
        Write-Host "Service '$($Service.Name)' is already running."
        return
    }

    $Result = Invoke-ScriptInBcContainer -ContainerName $ContainerName -ScriptBlock {
        param(
            $SourceUri, 
            $TargetPath,
            $InstallRequired, 
            [pscredential] $Credentials
        )
        if ($InstallRequired) {
            [IO.Directory]::CreateDirectory($TargetPath) | Out-Null
            if ([io.file]::Exists("$TargetPath\Package.zip")) { remove-item -path "$TargetPath\Package.zip" -Force }
            Write-Host "Downloading package from $SourceUri to $TargetPath"
            Invoke-WebRequest -Uri $SourceUri -OutFile "$TargetPath\Package.zip" -Credential $Credentials
            Write-Host "Extracting package to '$TargetPath\Bare.WebApi'"
            if ([io.Directory]::Exists("$TargetPath\Bare.WebApi")) {
                remove-item -path $TargetPath\Bare.WebApi -Recurse -Force 
            }
            Expand-Archive -Path "$TargetPath\Package.zip" -DestinationPath "$TargetPath\Bare.WebApi" -Force
            Write-Host "Installing and starting service"
        }
        if ($InstallRequired) {
            & "$TargetPath\Bare.WebApi\Bare.WebApi.exe" ("install")
        }
        Start-Service "Bare.WebApi"
        Invoke-RestMethod -Method Get -Uri "http://localhost:9462/api/v2/status" | Write-Output -NoEnumerate
    } -ArgumentList (
        $SourceUri,
        $TargetPath,
        $InstallRequired,
        $Credentials
    )

    $Result | Format-List

}