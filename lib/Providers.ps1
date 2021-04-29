

## TM Providers
Function New-TMProvider {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Provider,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
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

	
	# Write-Host "Creating Provider: "$Provider.name
	
	## Action 1, Confirm the name is unique
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/dataingestion/provider/validateUnique"
	
	$PostBody = @{ name = $Provider.name }

	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
	$PostBodyJSON = $PostBody | ConvertTo-Json -Depth 100

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				$isUnique = $responseContent.data.isUnique
				if ($isUnique -ne $true) {
					$ExistingProvider = Get-TMProvider -Name $Provider.name -TMSession $TMSession
					if ($PassThru) { return $ExistingProvider } else { return }
				}
			}	
		}
	} catch {
		Write-Host "Unable to determine if Provider is unique."
		return $_
	}

	# Step 2, Create the provider
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/dataingestion/provider/'

	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
	$ProviderJson = $Provider | ConvertTo-Json -Depth 100

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $ProviderJson @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				if ($PassThru) { return $responseContent.data.provider } else { return }
			}	
		} elseif ($response.StatusCode -eq 204) {
			return
		}
	} catch {
		Write-Host "Unable to create Provider."
		return $_
	}
	
}
Function Get-TMProvider {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
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
	$uri += '/tdstm/ws/dataingestion/provider/list'
	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$Result = ($response.Content | ConvertFrom-Json).data
	} else {
		return "Unable to collect Providers."
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
