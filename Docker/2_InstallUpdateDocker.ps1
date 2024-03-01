function GetDockerDir() {
    return "$env:ProgramFiles\docker\"
}

function CheckRequirement($ForceRestart) {
    $needRestart = $false
    if ( (Get-WindowsOptionalFeature -FeatureName containers -Online).State -eq "Disabled") {
        $needRestart = $true
        Enable-WindowsOptionalFeature -Online -FeatureName containers –All -NoRestart
    }
    if ( (Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V -Online).State -eq "Disabled") {
        $needRestart = $true
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V –All -NoRestart
    }

    if ($needRestart -and $ForceRestart) {
        Restart-Computer -Force
    }
}

function CheckDockerExists() {
    $dockerExists = $false    
    try {
        & docker -v | Out-Null
        $dockerExists = $true
    }
    catch {
        $dockerExists = $false        
    }

    return $dockerExists
}

function CheckDockerDesktopInstalled() {
    return ((Get-ChildItem $(GetDockerDir) -Recurse -ErrorAction Continue -Filter "Docker Desktop.exe").Exists -eq $true)
}

function DownloadDocker($url) {
    Write-Host "Downloading Docker"
    $dockerDir = GetDockerDir
    New-Item -Type Directory -Path "$dockerDir" -Force
    if(Test-Path "$dockerDir\docker.zip" ){ Remove-Item "$dockerDir\docker.zip" -Force}
    Invoke-WebRequest $url -OutFile $dockerDir\docker.zip 
    Expand-Archive "$dockerDir\docker.zip" -DestinationPath (Resolve-Path($dockerDir + "\..")) -Force

    Write-Host "Docker Downloaded"
}

function SetEnvPath() {
    $dockerDir = GetDockerDir
    $path = [System.Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if (";$path;" -notlike "*;$($dockerDir)*") {
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$dockerDir", [EnvironmentVariableTarget]::Machine)
        $env:Path = $env:Path + ";$dockerDir"
    }
}

function CreateService() {
    Write-Host "Registering docker service"
    #Create service
    dockerd --register-service  
# if not listening on TCP use this
#dockerd --register-service -H tcp://127.0.0.1:2375
    Write-Host "Starting docker service"
    Start-Service Docker
}

function GetDockerDownloadUrl($GetUpdate) {
    $url = "";
    $baseURL = "https://download.docker.com/win/static/stable/x86_64/"

    $files = ((Invoke-WebRequest –Uri $baseURL).Links).href | Where-Object { !($_.contains("ce")) }

    if ($GetUpdate) {
        $dockerVersion = [version][regex]::Match($(docker -v), "(\d+(\.\d+){1,3})").Value
        # UNCOMMENT FOR TEST $dockerVersion = [version]"20.10.8"


        Write-Verbose "Current Docker Version: $dockerVersion"
        #([version][regex]::Match($(docker -v), "(\d+(\.\d+){1,3})").Value) -gt [version]"20.10.09"
        $files | Where-Object {
            if ($_ -ne "../") {
                $grepVers = [version][regex]::Match($_, "(\d+(\.\d+){1,3})").Value
                if ($grepVers -gt $dockerVersion) {
                    $url = ($baseURL + $_)
                }
            }
        }
    }
    else {
        $Latest = ""
        $files.ForEach({
                if ($_ -ne "../") {
                    $grepVers = [version][regex]::Match($_, "(\d+(\.\d+){1,3})").Value
                    if ($Latest -eq "") {
                        $Latest = $_
                    }
                    elseif ($grepVers -gt [version][regex]::Match($Latest, "(\d+(\.\d+){1,3})").Value) {
                        $Latest = $_
                    }
                }
            })
        $url = ($baseURL + $Latest)
    }

    return $url
}

function GerVersionFromUrl($url)
{
    return [version][regex]::Match($url, "(\d+(\.\d+){1,3})").Value
}

function StopDocker() {
    Write-Host "Stopping Service"
    Stop-Service docker
}

function UnRegisterDocker() {
    Write-Host "unregistering service"
    dockerd --unregister-service
}

CheckRequirement($true)

$DockerDownloadurl = ""
$Continue = $true
if (CheckDockerExists) {
    Write-Host "Docker Seems installed"
    if (!(CheckDockerDesktopInstalled)) {
        Write-Host "Checking for updates"
        $DockerDownloadurl = GetDockerDownloadUrl($true)
        if ($DockerDownloadurl -eq "") {
            Write-Host "No Update needed"
            $Continue = $false
        }
        else {
            Write-Host "New version found! $(GerVersionFromUrl($DockerDownloadurl))"
            if ((Read-Host "Do you want to install the new version (y/n)?") -eq "n") { $Continue = $false }            
        }
        if ($Continue) {            
            StopDocker
            UnRegisterDocker
        }

    }
    else {
    
        throw "Docker Desktop seems installed, Uninstall it first!!"
    }
}
else {
    $DockerDownloadurl = GetDockerDownloadUrl($false)
}


if ($Continue) {
    DownloadDocker($DockerDownloadurl)

    SetEnvPath

    CreateService
}
else {
    Write-Host "Goodbye"
}