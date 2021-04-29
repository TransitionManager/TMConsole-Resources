
## TM Bundles
Function Get-TMBundle {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$ResetIDs,
		[Parameter(Mandatory = $false)][Switch]$Label

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

	# $instance = $Server.Replace('/tdstm', '')
	# $instance = $instance.Replace('https://', '')
	# $instance = $instance.Replace('http://', '')
	
	# $uri = "https://"
	# $uri += $instance
	# $uri += '/tdstm/moveBundle/retrieveBundleList'
	$uri = Get-TMEndpointUri -EndpointName 'GetBundle'
	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$Results = Invoke-ResponseHandling -HandlerName 'GetBundleList' -Server $TMVersion
		# $Result = $response.Content | ConvertFrom-Json
	} else {
		return "Unable to collect Bundles."
	}

	if ($ResetIDs) {
		for ($i = 0; $i -lt $Results.Count; $i++) {
			
			## Remove the asset qty value
			$Results[$i].assetqty = $null
			
			## Remove the ID Field
			if ($TMSessionConfig.TMVersion -like '4.7*') {
				#4.7+
				$Results[$i].id = $null
			} else {
				#4.6 and lower
				$Results[$i].bundleId = $null
			}
		}
	}

	## Return the requested Bundle
	if ($Name) {
		return ($Results | Where-Object { $_.name -eq $Name })
	} else {
		return $Results
	}
}

Function New-TMBundle {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Bundle,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL
	)
	if ($global:TMSessions[$TMSession].TMVersion -eq '4.7.2') {
		New-TMBundle472 @PSBoundParameters

	} elseif ($global:TMSessions[$TMSession].TMVersion -like '4.7*') {
		New-TMBundle474 @PSBoundParameters

	} else {
		New-TMBundle46 @PSBoundParameters
	}
}

Function New-TMBundle46 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Bundle,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL
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

	## Get existing Bundle
	$ExistingBundle = Get-TMBundle -Name $Bundle.name -TMSession $TMSession

	if ($ExistingBundle) {
		# Write-Host "Bundle Exists: "$Bundle.name
		if ($PassThru) { return $ExistingBundle } else { return }
	} 

	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/moveBundle/save'

	Set-TMHeaderContentType -ContentType 'Form' -TMSession $TMSession

	$Bundle | Add-Member -NotePropertyName 'workflowCode' -NotePropertyValue 'STD_Process'
	$Bundle.PSObject.properties.Remove('bundleId')
	
	$PostBody = @{
		name             = $Bundle.name
		description      = $Bundle.description
		sourceRoom       = ''
		targetRoom       = ''
		startTime        = $Bundle.startDate
		completionTime   = '' 
		projectManager   = ''
		moveManager      = ''
		operationalOrder = 1
		workflowCode     = 'STD_Process'
		project          = @{ id = $global:TMUserContent.project.id }
		projectid        = $global:TMUserContent.project.id
		useForPlanning   = $Bundle.planning
	}

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
		if ($response.StatusCode -eq 200 ) {
			if ($PassThru) { 
				return (Get-TMBundle -TMSession $TMSession | Where-Object { $_.name -eq $Bundle.name })
			} else { return }
		}
	} catch {
		throw $_
	}
}


Function New-TMBundle472 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Bundle,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL
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

	## Get existing Bundle
	$ExistingBundle = Get-TMBundle -TMSession $TMSession -Name $Bundle.name

	if ($ExistingBundle) {
		# Write-Host "Bundle Exists: "$Bundle.name
		return $ExistingBundle
	}
	#  else {
	# 	Write-Host "Creating Bundle:"$Bundle.name
	# }

	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/moveBundle'

	Set-TMHeaderContentType -ContentType 'JSON' -TMSession $TMSession
	$Bundle.id = ''

	$PostJson = $Bundle | ConvertTo-Json

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostJson @TMCertSettings
		if ($response.StatusCode -eq 200 ) {
			if ($PassThru) {
				return (Get-TMBundle -TMSession $TMSession | Where-Object { $_.name -eq $Bundle.name })
			} else { return }
		} else {
			throw 'Unable to Create Bundle'
		} elseif ($response.StatusCode -eq 204) {
			return
		}
	} catch {
		throw $_
	}
}
Function New-TMBundle474 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Bundle,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL
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

	## Get existing Bundle
	$ExistingBundle = Get-TMBundle -Name $Bundle.name -TMSession $TMSession

	if ($ExistingBundle) {
		# Write-Host "Bundle Exists: "$Bundle.name
		if ($PassThru) {
			return $ExistingBundle
		} else { return }
	} 
	# else {
	# 	Write-Host "Creating Bundle:"$Bundle.name
	# }

	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/moveBundle'

	Set-TMHeaderContentType -ContentType 'JSON' -TMSession $TMSession
	
	## Reset Bundle ID // Regardless of the Version of the import file
	if ($Bundle.PSOBject.Properties.Name -eq 'id') { $Bundle.id = '' } 
	if ($Bundle.PSOBject.Properties.Name -eq 'bundleId') { $Bundle.bundleId = '' } 

	$PostJson = $Bundle | ConvertTo-Json

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostJson @TMCertSettings
		if ($response.StatusCode -eq 200 ) {
			if ($PassThru) {
				return (Get-TMBundle -TMSession $TMSession | Where-Object { $_.name -eq $Bundle.name })
			} else { return }
		} elseif ($response.StatusCode -eq 204) {
			return
		} else {
			throw 'Unable to Create Bundle'
		}
	} catch {
		throw $_
	}
}
