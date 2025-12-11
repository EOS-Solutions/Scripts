$ErrorActionPreference = "Stop"
$RemoteUri = "https://eospublictoolsstorage.blob.core.windows.net/installer/gin.exe"
$LocalPath = [IO.FileInfo]::new("$env:temp\gin\gin.exe")
if (-not $LocalPath.Directory.Exists) {
    $LocalPath.Directory.Create()
}
$success = $false
$retryCount = 0
while(-not $success -and ($retryCount -le 3)){
    try{
        $RequiresDownload = -not $LocalPath.Exists
        if (-not $RequiresDownload) {
            $RemoteFile = (Invoke-WebRequest -Method HEAD $RemoteUri)
            $RemoteDate = [DateTime]($RemoteFile.Headers["Last-Modified"][0])
            Write-Verbose $RemoteDate
            $LocalDate = $LocalPath.LastWriteTime
            Write-Verbose $LocalDate
            $rawMD5 = (Get-FileHash -Path $LocalPath.FullName -Algorithm MD5).Hash
            $hashBytes = @()
            for ($i = 0; $i -lt $rawMD5.Length; $i += 2) {
                $byte = [Convert]::ToByte($rawMD5.Substring($i, 2), 16)
                $hashBytes += $byte
            }

            $RequiresDownload = ($RemoteDate -gt $LocalDate) -or ([system.convert]::ToBase64String($hashBytes) -ne $RemoteFile.Headers["Content-MD5"])
        }
        
        if ($RequiresDownload) {
            Invoke-WebRequest -Uri $RemoteUri -OutFile $LocalPath.FullName
        }
        Write-Verbose "Checking file integrity"


        & $LocalPath.FullName | out-null
        $success = $true;
    } catch{
        Write-Host "Something went wrong: $($_.Exception)"
        Write-Host "Retrying in 2 seconds"
        Start-Sleep -Seconds 2
        $success = $false;
        $retryCount++
    }
}

if($success){
    Write-Host "gin is available in $($LocalPath.FullName)"
    $GinPath = $LocalPath.Directory.FullName
    if (-not $env:Path.Contains($GinPath)) { $env:Path += ";$GinPath" }
}else{
    Write-Host "There was a problem installing gin"
}