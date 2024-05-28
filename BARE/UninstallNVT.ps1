$ErrorActionPreference = "Stop"
Import-Module BcContainerHelper
Invoke-Expression ". { $(Invoke-RestMethod https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/BARE/Uninstall-NVTInSession.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
Uninstall-NVTInSession