# Installing the Gordon Service via CLI (gin) to a container

Install the Gordon service onto a container. This will ask you for the container to install to.

````
Invoke-Expression ". { $(Invoke-RestMethod https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/Gordon/InstallGordonService.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
````

You can also use this approach in your pipelines without user interaction asking for the container name:

````
$Contents = Invoke-RestMethod "https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/Installer/download-gin.ps1" -Headers @{"Cache-Control" = "no-cache" }
Invoke-Expression $Contents
gin.exe install bare.webapi --scope "my-container"

````