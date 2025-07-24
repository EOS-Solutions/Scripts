param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $RootFolder,
    [Parameter(Mandatory = $true, Position = 1)]
    [string] $Major,
    [Parameter(Mandatory = $false)]
    [switch] $CheckOnly
)

$result = @()
$Total = 0
$PackageCacheFolders = Get-ChildItem -Path $RootFolder -Directory -Recurse -Filter ".alpackages"
foreach ($folder in $PackageCacheFolders) {
    $ParentName = $folder.Parent.Name
    $FolderMajor = [int]([Regex]::Match($ParentName, '-bc(?<ver>[0-9]+)$').Groups['ver'].Value)
    if (($FolderMajor -gt 0) -and ($FolderMajor -le $Major)) {
        $Size = Get-ChildItem $folder.FullName -Recurse | Measure-Object -Property Length -Sum
        $result += @{
            Folder = $folder.FullName
            Size   = $Size.Sum / 1MB
        }
        $Total += $Size.Sum
        if (-not $CheckOnly) {
            Get-ChildItem -Path $folder.FullName | Remove-Item -Recurse -Force
        }
    }
}

$result += @{
    Folder = "Total"
    Size   = $Total / 1MB
}


$result | ForEach-Object {
    [PSCustomObject]$_
} | Format-Table -AutoSize