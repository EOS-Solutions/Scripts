param(
    [Parameter(Mandatory = $false)]
    [string] $Folder,
    [Parameter(Mandatory = $true)]
    [string] $MajorVersion,
    [Parameter(Mandatory = $false)]
    [switch] $WithSwitch
)
$ErrorActionPreference = "Stop"

if (-not $Folder) { $Folder = $pwd }
if (![IO.Path]::IsPathRooted($Folder)) { Join-Path $pwd $Folder }
$WorktreeRoot = [System.IO.DirectoryInfo]::new($Folder)
$Repo = [System.IO.DirectoryInfo]::new((Join-Path $WorktreeRoot.FullName $WorktreeRoot.Name))
if (!$Repo.Exists) { 
    $RemoteUri = Read-Host -Prompt "Enter the remote URI"
    git clone $RemoteUri $Repo.FullName
    git -C $Repo.FullName checkout -B _root
}

$WorktreeBranchName = "master-$MajorVersion".ToLowerInvariant()
$WorktreeFolderName = "$($WorktreeRoot.Name)-$WorktreeBranchName".ToLowerInvariant()
$WorktreeFolder = [System.IO.DirectoryInfo]::new((Join-Path $WorktreeRoot.FullName $WorktreeFolderName))
if (!$WorktreeFolder.Exists) { 
    git -C $Repo.FullName fetch
    git -C $Repo.FullName worktree add $WorktreeFolder.FullName $WorktreeBranchName
}

Get-ChildItem "$PSScriptRoot\template\$MajorVersion" | Copy-Item -Destination $WorktreeFolder.FullName -Recurse -Force

$SettingsObject = (ConvertFrom-Json (Get-Content -Raw -Path "$PSScriptRoot\settings.json"))[$MajorVersion.ToLowerInvariant()]
if ($SettingsObject) {
    $LaunchFile = [System.IO.FileInfo]::new("$($WorktreeFolder.FullName)\.vscode\launch.json")
    if ($LaunchFile.Exists) {
        $LaunchObject = ConvertFrom-Json (Get-Content -Raw -Path $LaunchFile.FullName)
        $LaunchItem = $LaunchObject.configuration[0]
        foreach ($Setting in $SettingsObject) {
            $LaunchItem[$Setting.Name] = $Setting.Value
        }
    }
    Set-Content -Path $LaunchFile.FullName -Value ($LaunchObject | ConvertTo-Json -Depth 2) -Force -Encoding UTF8
}

if ($WithSwitch) {
    Set-Location $WorktreeFolder.FullName
}