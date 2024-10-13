# Gordon Installer

The Gordon Installer is a set of tools to deploy and distribute tools from the Gordon suite. It comes in two flavours:

- A fancy UI for managing your various tools
- A CLI that allows you to manage your tools from automation and pipelines

## UI

The "EOS Gordon Installer" user interface can downloaded here:

[Downloaded EOS Gordon Installer](https://eospublictoolsstorage.blob.core.windows.net/installer/Eos.Installer.Downloader.exe)

You can also find the link and some more information on [https://eos-solutions.github.io/Gordon].

## CLI

Gordon Installer is available as single CLI called "gin" (G)ordon (In)staller.

You can download the latest version from [https://eospublictoolsstorage.blob.core.windows.net/installer/gin.exe]

You can also use the script below. This will download gin (if it isn't already present) to a local temporary folder and load it into your current shell's PATH variable.
````
Invoke-Expression ". { $(Invoke-RestMethod https://raw.githubusercontent.com/EOS-Solutions/Scripts/master/Installer/download-gin.ps1 -Headers @{"Cache-Control" = "no-cache"}) }"
````