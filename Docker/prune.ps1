param (
    [switch]$RenameOrphanLayers
)

If ($RenameOrphanLayers) {
	Write-Warning "$($env:COMPUTERNAME) -RenameOrphanLayers option enabled, will rename all orphan layers"
}

# Get known layers on Docker images
[array]$ImageDetails += docker images -q | ForEach { docker inspect $_ | ConvertFrom-Json }
ForEach ($Image in $ImageDetails) {
	$ImageLayer = $Image.GraphDriver.Data.dir
	
	[array]$ImageLayers += $ImageLayer
	$LayerChain = Get-Content "$ImageLayer\layerchain.json"
	If ($LayerChainFileContent -ne "null") {
		[array]$ImageParentLayers += $LayerChain | ConvertFrom-Json
	}
}

# Get known layes on Docker containers
[array]$ContainerDetails = docker ps -a -q | ForEach { docker inspect $_ | ConvertFrom-Json}
ForEach ($Container in $ContainerDetails) {
	[array]$ContainerLayers += $Container.GraphDriver.Data.dir
}

# Get layers on disk
$LayersOnDisk = (Get-ChildItem -Path C:\ProgramData\Docker\windowsfilter -Directory).FullName
$ImageLayers += $ImageParentLayers
$UniqueImageLayers = $ImageLayers | Select-Object -Unique
[array]$KnownLayers = $UniqueImageLayers
$KnownLayers += $ContainerLayers

# Find orphan layers
$OrphanLayersTotal = 0
ForEach ($Layer in $LayersOnDisk) {
	If ($KnownLayers -notcontains $Layer) {
		[array]$OrphanLayer += $Layer
		$LayerSize = (Get-ChildItem -Path $Layer -Recurse -ErrorAction:SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum
		$OrphanLayersTotal += $LayerSize
		Write-Warning "$($env:COMPUTERNAME) - Found orphan layer: $($Layer -Replace '\r\n','') with size: $(($LayerSize -Replace '\r\n','') / 1MB) MB"
		
		If (($RenameOrphanLayers) -and ($Layer -notlike "*-removing")) {
			$LayerNewPath = $Layer + "-removing"
			Rename-Item -Path $Layer -NewName $LayerNewPath
		}
	}
}

Write-Host "$($env:COMPUTERNAME) - Layers on disk: $($LayersOnDisk.count)"
Write-Host "$($env:COMPUTERNAME) - Image layers: $($UniqueImageLayers.count)"
Write-Host "$($env:COMPUTERNAME) - Container layers: $($ContainerLayers.count)"
$OrphanLayersTotalMB = $OrphanLayersTotal / 1MB
Write-Warning "$($env:COMPUTERNAME) - Found $($OrphanLayer.count) orphan layers with total size $OrphanLayersTotalMB MB"