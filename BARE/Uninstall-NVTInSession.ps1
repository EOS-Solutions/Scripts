<#
.SYNOPSIS
    Uninstall NVT service in the specified container.
#>
function Uninstall-NVTInSession {

    param(
        # Specifies the container name where to install the service.
        [Parameter(Mandatory = $true)]
        [String] $ContainerName
    )

    $Service = Invoke-ScriptInBcContainer -ContainerName $ContainerName -ScriptBlock {
        try {
            return Get-Service -Name "NvtRemoteService"
        }
        catch {
            return $null
        }
    }

    if (-not $Service) {
        Write-Host "Service NvtRemoteService does not exists. Exiting ..."
            return
    }

    if ($Service.Status -ieq "Running") {
        Write-Host "Service '$($Service.Name)' is running. Stopping"
        Invoke-ScriptInBcContainer -ContainerName $ContainerName -ScriptBlock {
            try {
                Stop-Service -Name "NvtRemoteService"
            }
            catch {}
        }
    }

    $Result = Invoke-ScriptInBcContainer -ContainerName $ContainerName -ScriptBlock {        
        $targetPath = (Get-CimInstance Win32_Service -Filter 'Name = "NvtRemoteService"').PathName
        & "$TargetPath" ("uninstall")        
    } 
    $Result | Format-List
}