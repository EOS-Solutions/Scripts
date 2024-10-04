$ErrorActionPreference = "Stop"
$RemoteUri = "https://eospublictoolsstorage.blob.core.windows.net/installer/gin.exe"
$LocalPath = [IO.FileInfo]::new("$env:temp\gin\gin.exe")
if (-not $LocalPath.Directory.Exists) {
    $LocalPath.Directory.Create()
}
$RequiresDownload = -not $LocalPath.Exists
if (-not $RequiresDownload) {
    $RemoteDate = [DateTime]((Invoke-WebRequest -Method HEAD $RemoteUri).Headers["Last-Modified"][0])
    Write-Verbose $RemoteDate
    $LocalDate = $LocalPath.LastWriteTime
    Write-Verbose $LocalDate
    $RequiresDownload = $RemoteDate -gt $LocalDate
}
if ($RequiresDownload) {
    Invoke-WebRequest -Uri $RemoteUri -OutFile $LocalPath.FullName
}
Write-Host "gin is now available in $($LocalPath.FullName)"

$GinPath = $LocalPath.Directory.FullName
if (-not $env:Path.Contains($GinPath)) { $env:Path += ";$GinPath" }