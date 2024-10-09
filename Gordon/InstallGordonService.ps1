param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $ContainerName
)

Write-Host "Loading gin"
$GinScriptUri = "https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/Installer/download-gin.ps1"
Invoke-Expression ". { $(Invoke-RestMethod $GinScriptUri -Headers @{"Cache-Control" = "no-cache"}) }"

gin.exe install bare.webapi --scope $ContainerName