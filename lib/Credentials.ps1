
## TM Credentials
Function Get-TMCredential {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)][Switch]$ResetIDs

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
	$uri += '/tdstm/ws/credential'

	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$Result = ($response.Content | ConvertFrom-Json).data
	} else {
		return "Unable to collect Credentials."
	}

	
	## Reset IDs
	if ($ResetIDs) {
		for ($i = 0; $i -lt $Result.Count; $i++) {
			$Result[$i].id = $null
			$Result[$i].project.id = $null
			$Result[$i].provider.id = $null
			$Result[$i].authenticationUrl = 'localhost'
		}
	}

	## Return the matching one by name, if provided
	if ($Name) {
		$MatchingResult = $Result | Where-Object { $_.name -eq $Name }
		if ($MatchingResult) {
			return $MatchingResult
		} else {
			return $Result
		}
	}
}

Function New-TMCredential {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$TMCredential,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][PSObject]$Project
	)
	
	if ($global:TMSessions[$TMSession].TMVersion -like '4.7*') {
		New-TMCredential47 @PSBoundParameters

	} else {
		New-TMCredential46 @PSBoundParameters
	}
}

Function New-TMCredential46 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$TMCredential,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][PSObject]$Project
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

	# Write-Host "Creating Credential: "$TMCredential.name

	## Check for existing credential 
	$TMCredentialCheck = Get-TMCredential -Name $TMCredential.name -TMSession $TMSession
	if ($TMCredentialCheck) {
		if ($PassThru) {
			return $TMCredentialCheck
		} else { return $true }
	} else {

		## No Credential exists.  Create it
		$instance = $Server.Replace('/tdstm', '')
		$instance = $instance.Replace('https://', '')
		$instance = $instance.Replace('http://', '')
	
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/credential'

		## Lookup Cross References
		if ($Project) {
			$ProjectID = $Project.id
			$TMCredential.project.name = $Project.Name
		} else {
			$ProjectID = ($Projects | Where-Object { $_.name -eq $TMCredential.project.name }).id
		}
		$ProviderID = ($Providers | Where-Object { $_.name -eq $TMCredential.provider.name }).id

		## Fix up the object
		$TMCredential.PSObject.properties.Remove('id')
		$TMCredential.project.id = $ProjectID
		$TMCredential.provider.id = $ProviderID
		$TMCredential.version = 1
		$TMCredential | Add-Member -NotePropertyName 'password' -NotePropertyValue 'tmemptypassword'
		$PostBodyJSON = $TMCredential | ConvertTo-Json -Depth 100

		Set-TMHeaderAccept "JSON" -TMSession $TMSession
		Set-TMHeaderContentType "JSON" -TMSession $TMSession

		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				return $responseContent.data
			}	
		}
	}
}
Function New-TMCredential47 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$TMCredential,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][int]$ProjectId = $global:TMSessions[$TMSession].UserContext.project.id
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

	# Write-Host "Creating Credential: "$TMCredential.name

	## Check for existing credential 
	$TMCredentialCheck = Get-TMCredential -Name $TMCredential.name -TMSession $TMSession
	if ($TMCredentialCheck) {
		return $TMCredentialCheck
	} else {

		## Provider Reference will be required
		$Providers = Get-TMProvider -TMSession $TMSession

		## No Credential exists.  Create it
		$instance = $Server.Replace('/tdstm', '')
		$instance = $instance.Replace('https://', '')
		$instance = $instance.Replace('http://', '')
	
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/credential'

		## Get the Provider ID from the newly created providers list
		$ProviderID = ($Providers | Where-Object { $_.name -eq $TMCredential.provider.name }).id

		## Fix up the object
		$TMCredential.PSObject.properties.Remove('id')
		$TMCredential.project.id = $ProjectID
		$TMCredential.provider.id = $ProviderID
		$TMCredential.version = 1
		$TMCredential | Add-Member -NotePropertyName 'password' -NotePropertyValue 'tmemptypassword'
		$PostBodyJSON = $TMCredential | ConvertTo-Json -Depth 100

		Set-TMHeaderAccept "JSON" -TMSession $TMSession
		Set-TMHeaderContentType "JSON" -TMSession $TMSession

		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				if ($PassThru) {
					return $responseContent.data
				}
			}	
		} elseif ($response.StatusCode -eq 204) {
			return
		}
	}
}