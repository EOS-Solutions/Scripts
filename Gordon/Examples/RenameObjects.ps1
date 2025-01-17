param(
    [Parameter(Mandatory = $false)]
    [string] $Folder = $pwd
)

Import-Module Gordon
$Objects = Get-NavAlObject -Folder $Folder
foreach ($Obj in $Objects) {
    $File = [IO.FileInfo] $Obj.Filename
    $Folder = $File.Directory

    $ObjectId = $Obj.Id
    $ObjectName = $Obj.Name
    if ($Obj.Type.IsExtension) { 
        $ObjectId = $Obj.BaseObjectId 
        $ObjectName = $Obj.BaseObjectName
    }
    if ($ObjectId -gt 0) {
        $IdStr = $ObjectId
    }
    else {
        $IdStr = ""
    }

    $NewName = "$($Obj.Type)".ToLowerInvariant()
    if ($IdStr -ne "") {
        $NewName += " $IdStr"
    }
    $NewName += " $ObjectName"
    $NewName = $NewName.Replace("/", "_").Replace("\", "_");
    $NewName = "$NewName.al"
    
    if ($NewName -ne $File.Name) {
        Write-Host "$($File.Name) -> $NewName"
        Rename-Item -Path $File.FullName -NewName "$($Folder.FullName)/$NewName"
    }

}