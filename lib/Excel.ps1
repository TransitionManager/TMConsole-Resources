
# TM Excel File
Function Read-TMAssetFile {
	param(
		[Parameter(Mandatory = $true)][String]$filePath
	)
	if (Get-FileTypeFromPath($filePath) -eq "xlsx") {
		$tmAssets = @{ }
		$data = Import-Excel $filePath -WorksheetName "Applications"
		Add-Member -InputObject $tmAssets -MemberType "NoteProperty" -Name "Applications" -Value $data -Force
		
		$data = Import-Excel $filePath -WorksheetName "Devices"
		Add-Member -InputObject $tmAssets -MemberType "NoteProperty" -Name "Devices" -Value $data -Force
		
		$data = Import-Excel $filePath -WorksheetName "Databases"
		Add-Member -InputObject $tmAssets -MemberType "NoteProperty" -Name "Databases" -Value $data -Force
	
		$data = Import-Excel $filePath -WorksheetName "Storage"
		Add-Member -InputObject $tmAssets -MemberType "NoteProperty" -Name "Storage" -Value $data -Force
	
		$data = Import-Excel $filePath -WorksheetName "Dependencies"
		Add-Member -InputObject $tmAssets -MemberType "NoteProperty" -Name "Dependencies" -Value $data -Force
	
		$data = Import-Excel $filePath -WorksheetName "Room"
		Add-Member -InputObject $tmAssets -MemberType "NoteProperty" -Name "Room" -Value $data -Force
	
		$data = Import-Excel $filePath -WorksheetName "Rack"
		Add-Member -InputObject $tmAssets -MemberType "NoteProperty" -Name "Rack" -Value $data -Force
	
		$tmAssets
	
	}		
}