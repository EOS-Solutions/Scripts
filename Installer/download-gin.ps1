$ErrorActionPreference = "Stop"
$RemoteUri = "https://eospublictoolsstorage.blob.core.windows.net/installer/gin.exe"
$LocalPath = [IO.FileInfo]::new("$env:temp\gin\gin.exe")
if (-not $LocalPath.Directory.Exists) {
    $LocalPath.Directory.Create()
}
$success = $false
$retryCount = 0
while (-not $success -and ($retryCount -le 3)) {
    try {
        $RemoteFile = Invoke-WebRequest -Method HEAD $RemoteUri
        $RemoteDate = [DateTime]$RemoteFile.Headers["Last-Modified"][0]
        $RemoteLength = [int64]$RemoteFile.Headers["Content-Length"][0]
        Write-Verbose $RemoteDate
        Write-Verbose $RemoteLength

        $LocalPath.Refresh()
        $RequiresDownload = -not (Test-Path -LiteralPath $LocalPath.FullName)
        if (-not $RequiresDownload) {
            $LocalFile = Get-Item -LiteralPath $LocalPath.FullName
            $LocalDate = $LocalFile.LastWriteTime
            $LocalLength = $LocalFile.Length
            Write-Verbose $LocalDate
            Write-Verbose $LocalLength

            $RequiresDownload = ($RemoteDate -gt $LocalDate) -or ($RemoteLength -ne $LocalLength)
        }
        
        if ($RequiresDownload) {
            $DownloadPath = "$($LocalPath.FullName).download"
            if (Test-Path -LiteralPath $DownloadPath) {
                Remove-Item -LiteralPath $DownloadPath -Force -ErrorAction SilentlyContinue
            }

            Invoke-WebRequest -Uri $RemoteUri -OutFile $DownloadPath

            $DownloadedFile = Get-Item -LiteralPath $DownloadPath
            if ($DownloadedFile.Length -ne $RemoteLength) {
                throw "gin.exe download size mismatch. Expected $RemoteLength bytes, got $($DownloadedFile.Length) bytes"
            }

            Move-Item -LiteralPath $DownloadPath -Destination $LocalPath.FullName -Force
        }
        Write-Verbose "gin.exe is present and matches remote size"
        
        $success = $true;
    }
    catch {
        Write-Host "Something went wrong: $($_.Exception)"
        if (Test-Path -LiteralPath "$($LocalPath.FullName).download") {
            Remove-Item -LiteralPath "$($LocalPath.FullName).download" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $LocalPath.FullName) {
            Remove-Item -LiteralPath $LocalPath.FullName -Force -ErrorAction SilentlyContinue
        }
        Write-Host "Retrying in 2 seconds"
        Start-Sleep -Seconds 2
        $success = $false;
        $retryCount++
    }
}

if ($success) {
    Write-Host "gin is available in $($LocalPath.FullName)"
    $GinPath = $LocalPath.Directory.FullName
    if (-not $env:Path.Contains($GinPath)) { $env:Path += ";$GinPath" }
}
else {
    Write-Host "There was a problem installing gin"
}
