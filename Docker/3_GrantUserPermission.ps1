$account = Read-Host 'Dimmi il tuo nome utente, usando EOS\Nome'
# Add group and domain user to Windows Groups
New-LocalGroup -Name 'docker-users' -Description 'docker Users Group'
Add-LocalGroupMember -Group 'docker-users' -Member ($account,'Administrators') –Verbose

write-host "editing daemon.json"

$daemonPath = "$env:ProgramData\docker\config\daemon.json";
if ((Test-Path $daemonPath) -eq $false){
    write-host "daemon.json not present, creating a new one with defaults values"

    $daemon = @{
		"group" = "docker-users"
    }

    $daemon | ConvertTo-Json | Out-File (New-Item -Path $daemonPath -Force)
} else {
    write-host "daemon.json present, checking values"
    $daemon = Get-Content $daemonPath | ConvertFrom-Json

    if(($daemon.psobject.properties | where {$_.name -eq "group"}).Count -eq 1){        
        Write-host "Host Proerties found"
        if($daemon.group.Contains("docker-users") -eq $true){
            Write-Host "Config already up to date!!" -ForegroundColor Green
        }
        else {
            Write-Host "Adding docker-users  to config file" -ForegroundColor Green
            $daemon.group = "docker-users"
        }
    } else {
        Write-host "Host Proerties not found, creating new"

        $daemon | Add-Member -MemberType NoteProperty -Name "group" -Value "docker-users"
    }

    Write-Host "Saving Config" -ForegroundColor Green 

    $daemon | ConvertTo-Json | Out-File (New-Item -Path $daemonPath -Force)
}