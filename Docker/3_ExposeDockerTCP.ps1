write-host "editing daemon.json"

$daemonPath = "$env:ProgramData\docker\config\daemon.json";
#$daemonPath = "C:\_myTmp\testsubfolder\aaa.json";
if ((Test-Path $daemonPath) -eq $false){
    write-host "daemon.json not present, creating a new one with defaults values"

    $daemon = @{
        "hosts" = @("tcp://127.0.0.1:2375","npipe://")
    }

    $daemon | ConvertTo-Json | Out-File (New-Item -Path $daemonPath -Force)
} else {
    write-host "daemon.json present, checking values"
    $daemon = Get-Content $daemonPath | ConvertFrom-Json

    if(($daemon.psobject.properties | where {$_.name -eq "hosts"}).Count -eq 1){        
        Write-host "Host Proerties found"
        if($daemon.hosts.Contains("tcp://127.0.0.1:2375") -eq $true){
            Write-Host "Config already up to date!!" -ForegroundColor Green
        }
        else {
            Write-Host "Adding tcp://127.0.0.1:2375  to config file" -ForegroundColor Green
            $daemon.hosts += "tcp://127.0.0.1:2375"
        }
    } else {
        Write-host "Host Proerties not found, creating new"

        $daemon | Add-Member -MemberType NoteProperty -Name "hosts" -Value @("tcp://127.0.0.1:2375","npipe://")
    }

    Write-Host "Saving Config" -ForegroundColor Green 

    $daemon | ConvertTo-Json | Out-File (New-Item -Path $daemonPath -Force)
}

write-host "Updating Envirorment variables"


$var = [System.Environment]::GetEnvironmentVariable("DOCKER_HOST", [EnvironmentVariableTarget]::Machine)
if (";$path;" -notlike "*;$($dockerDir)*") {
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$dockerDir", [EnvironmentVariableTarget]::Machine)
    $env:Path = $env:Path + ";$dockerDir"
}