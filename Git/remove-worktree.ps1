param(
    [Parameter(Mandatory = $false)]
    [string] $Folder,
    [Parameter(Mandatory = $true)]
    [string] $MajorVersion,
    [Parameter(Mandatory = $false)]
    [switch] $Force
)
$ErrorActionPreference = "Stop"

if (-not $Folder) { $Folder = $pwd }
if (![IO.Path]::IsPathRooted($Folder)) { Join-Path $pwd $Folder }
$WorktreeRoot = [System.IO.DirectoryInfo]::new($Folder)
$Repo = [System.IO.DirectoryInfo]::new((Join-Path $WorktreeRoot.FullName $WorktreeRoot.Name))
if (!$Repo.Exists) { return }

$WorktreeBranchName = "master-$MajorVersion".ToLowerInvariant()
$WorktreeFolderName = "$($WorktreeRoot.Name)-$WorktreeBranchName".ToLowerInvariant()
$WorktreeFolder = [System.IO.DirectoryInfo]::new((Join-Path $WorktreeRoot.FullName $WorktreeFolderName))
if ($WorktreeFolder.Exists) {
    $gitArgs = @(
        "-C", $Repo.FullName
        "worktree", "remove", $WorktreeFolder.FullName
    )
    if ($Force) { $gitArgs += "--force" }
    & git @gitArgs
}