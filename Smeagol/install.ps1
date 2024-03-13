$ErrorActionPreference = "Stop"
Import-Module BcContainerHelper
iex ". { $(irm https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/Smeagol/Install-RemoteServiceInSession.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
Install-RemoteServiceInSession