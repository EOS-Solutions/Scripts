$ErrorActionPreference = "Stop"
Import-Module BcContainerHelper
Invoke-Expression ". { $(Invoke-RestMethod https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/BARE/Install-RemoteServiceInSession.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
Install-RemoteServiceInSession -SourceFeed "tools-internal"