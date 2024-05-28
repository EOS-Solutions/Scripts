# First Step
If you have already NVT Remote Service installed, before installing Bare you need to uninstall NVT.

Execute this script:
````
iex ". { $(irm https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/BARE/UninstallNVT.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
````

# Install

Use the following script to install BARE into a container from any powershell session (as administrator, if your docker setup requires it).

This script requires you to have access to the "tools-internal" feed and will install the latest available version on that feed.
````
iex ". { $(irm https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/BARE/install.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
````

If you have access to the WIP "tools-labs" feed, you can use the following script instead.
````
iex ". { $(irm https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/BARE/install-labs.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
````