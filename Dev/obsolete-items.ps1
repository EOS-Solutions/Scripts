param(
    [Parameter(Mandatory = $true)]
    [string] $MinVersion,
    [Parameter]
    [switch] $IncludeRemoved
)

Import-Module Gordon
Get-ObsoleteCodeItems | `
    Where-Object { $_.TagAsVersion -le [Version] $MinVersion } | `
    Where-Object { $IncludeRemoved -or ($_.State -ne "Removed") }