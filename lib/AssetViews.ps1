

## TM AssetViewConfigurations
# Function New-TMAssetViewConfiguration {
# 	param(
# 		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
# 		[Parameter(Mandatory = $true)][PSObject]$AssetViewConfiguration,
# 		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
# 		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
# 		[Parameter(Mandatory = $false)][Switch]$PassThru
# 	)
# 	## Get Session Configuration
# 	$TMSessionConfig = $global:TMSessions[$TMSession]
# 	if (-not $TMSessionConfig) {
# 		Write-Host 'TMSession: [' -NoNewline
# 		Write-Host $TMSession -ForegroundColor Cyan
# 		Write-Host '] was not Found. Please use the New-TMSession command.'
# 		Throw "TM Session Not Found.  Use New-TMSession command before using features."
# 	}

# 	#Honor SSL Settings
# 	if ($TMSessionConfig.AllowInsecureSSL) {
# 		$TMCertSettings = @{SkipCertificateCheck = $true }
# 	} else { 
# 		$TMCertSettings = @{SkipCertificateCheck = $false }
# 	}

	
# 	# Write-Host "Creating AssetViewConfiguration: "$AssetViewConfiguration.name
	
# 	## Action 1, Confirm the name is unique
# 	$instance = $Server.Replace('/tdstm', '')
# 	$instance = $instance.Replace('https://', '')
# 	$instance = $instance.Replace('http://', '')
	
# 	$uri = "https://"
# 	$uri += $instance
# 	$uri += "/tdstm/ws/assetExplorer/views"
	
# 	$PostBody = @{ name = $AssetViewConfiguration.name }

# 	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
# 	$PostBodyJSON = $PostBody | ConvertTo-Json -Depth 100

# 	try {
# 		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
# 		if ($response.StatusCode -eq 200) {
# 			$responseContent = $response.Content | ConvertFrom-Json
# 			if ($responseContent.status -eq "success") {
# 				$isUnique = $responseContent.data.isUnique
# 				if ($isUnique -ne $true) {
# 					$ExistingAssetViewConfiguration = Get-TMAssetViewConfiguration -Name $AssetViewConfiguration.name -TMSession $TMSession
# 					if ($PassThru) { return $ExistingAssetViewConfiguration } else { return }
# 				}
# 			}	
# 		}
# 	} catch {
# 		Write-Host "Unable to determine if AssetViewConfiguration is unique."
# 		return $_
# 	}

# 	# Step 2, Create the AssetViewConfiguration
# 	$uri = "https://"
# 	$uri += $instance
# 	$uri += '/tdstm/ws/dataingestion/AssetViewConfiguration/'

# 	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
# 	$AssetViewConfigurationJson = $AssetViewConfiguration | ConvertTo-Json -Depth 100

# 	try {
# 		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $AssetViewConfigurationJson @TMCertSettings
# 		if ($response.StatusCode -eq 200) {
# 			$responseContent = $response.Content | ConvertFrom-Json
# 			if ($responseContent.status -eq "success") {
# 				if ($PassThru) { return $responseContent.data.AssetViewConfiguration } else { return }
# 			}	
# 		}
# 	} catch {
# 		Write-Host "Unable to create AssetViewConfiguration."
# 		return $_
# 	}
	
# }
Function Get-TMAssetView {
	param(
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$Id,
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Int]$Limit = 0,
		[Parameter(Mandatory = $false)][Int]$Offset = 0

	)
	# Get Session Configuration
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

	## Make sure we have a view to use
	if (-not $Id -and $Name) {
		$AssetViewId = (Get-TMAssetViewConfiguration -Name $Name).id
	} else {
		$AssetViewId = $Id
	}


	## Get the Field Schema for the AssetView
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/assetExplorer/view/'
	$uri += $AssetViewId

	## Request the data
	$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings

	## Ensure Success
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
				
			## Assign the results to a Variable
			$AssetView = $responseContent.data.dataView
				
		}	
	}

	## Return an error if there is no AssetView
	if (-not $AssetView) {
		throw 'Unable to Get Asset View, check name and try again'
	}

	## Construct a query of the view endpoint using the schema from the Provided Asset View
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/assetExplorer/query/'
	$uri += $AssetView.id

	## Create a Query Post
	$PostBody = @{
		filters      = @{
			columns = $AssetView.schema.columns
			domains = $AssetView.schema.domains
		}
		limit        = $Limit
		offset       = $Offset
		sortDomain   = $AssetView.schema.sort.domain
		sortOrder    = $AssetView.schema.sort.order
		sortProperty = $AssetView.schema.sort.property
	} | ConvertTo-Json -Depth 10 -Compress

	## Request the data
	$response = Invoke-WebRequest -Method Post -Uri $uri -Body $PostBody -WebSession $TMSessionConfig.TMWebSession @TMCertSettings

	## Ensure Success
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
				
			## Assign the results to a Variable
			$Assets = $responseContent.data.assets
				
		}	
	} elseif ($response.StatusCode -eq 204) {
		return
	}

	## Return located assets
	if ($Assets) { return $Assets }

}
Function Get-TMAssetViewConfiguration {
	param(
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$ResetIDs,
		[Parameter(Mandatory = $false)][Switch]$PassThru

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

	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/assetExplorer/views'
	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$Result = ($response.Content | ConvertFrom-Json).data
	} else {
		return "Unable to get Asset Views."
	}

	if ($ResetIDs) {
		for ($i = 0; $i -lt $Result.Count; $i++) {
			$Result[$i].id = $null
		}
	}

	if ($Name) {
		return ($Result | Where-Object { $_.name -eq $Name })
	} else {
		return $Result
	}
}
