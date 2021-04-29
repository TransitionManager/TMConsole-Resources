
Function Get-TMDependency {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",	
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][String]$DependencyType,
		[Parameter(Mandatory = $false)][int]$AssetId,
		[Parameter(Mandatory = $false)][String]$AssetName,
		[Parameter(Mandatory = $false)][int]$DependentId,
		[Parameter(Mandatory = $false)][String]$DependentName,
		[Parameter(Mandatory = $false)][String]$Status,
		[Parameter(Mandatory = $false)][String]$Comment
	)
	## Get Session Configuration
	$TMSessionConfig = $global:TMSessions[$TMSession]
	if (-not $TMSessionConfig) {
		Write-Host 'TMSession: [' -NoNewline
		Write-Host $TMSession -ForegroundColor Cyan
		Write-Host '] was not Found. Please use the New-TMSession command.'
		Throw "TM Session Not Found.  Use New-TMSession command before using features."
	}

	#Honor SSL Settings
	if ($TMSessionConfig.AllowInsecureSSL) {
		$TMCertSettings = @{SkipCertificateCheck = $true }
	} else { 
		$TMCertSettings = @{SkipCertificateCheck = $false }
	}
	
	## 4.7.1 Query format
	# Reference JSON: 

	$Query = @{
		rows = 1000
		page = 1
		sdix = 'assetName'
		sord = 'asc'
	}
	
	## IDs are not supported in lookup.  They are filtered after the results come back
	# if ( $AssetId ) { Add-Member -InputObject $Query -NotePropertyName 'assetId' -NotePropertyValue ($AssetId -as [System.Int64]) }
	# if ( $DependentId ) { Add-Member -InputObject $Query -NotePropertyName 'dependentId' -NotePropertyValue ($DependentId -as [System.Int64]) }
	
	## Add Filtering for the Dependencies we aer looking for
	if ( $AssetName ) { Add-Member -InputObject $Query -NotePropertyName 'assetName' -NotePropertyValue ($AssetName) }
	if ( $DependentName ) { Add-Member -InputObject $Query -NotePropertyName 'dependentName' -NotePropertyValue ($DependentName) }
	if ( $DependencyType ) { Add-Member -InputObject $Query -NotePropertyName 'type' -NotePropertyValue $DependencyType }
	if ( $Status ) { Add-Member -InputObject $Query -NotePropertyName 'status' -NotePropertyValue $Status }
	if ( $Comment ) { Add-Member -InputObject $Query -NotePropertyName 'comment' -NotePropertyValue $Comment }
	
	## Get the URL for lookup
	$uri = Get-TMEndpointUri -EndpointName 'GetDependency'
	
	try {
		$JsonQuery = $Query | ConvertTo-Json
		Set-TMHeaderContentType 'JSON' -TMSession $TMSession
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings -Body $JsonQuery
		
		if ($response.StatusCode -eq 200) {
			. Invoke-ResponseHandling -HandlerName 'GetDependency'
		} else {
			return "Unable to get Dependency."
		}
	} catch {
		return $_
	}
}