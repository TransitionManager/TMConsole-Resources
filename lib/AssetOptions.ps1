## TM Dependency Type
Function Get-TMDependencyType {
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
	$uri += '/tdstm/assetEntity/assetOptions'
	
	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		
		## A whole page is returned.  We need the content from the table with ID dependencyTypeTbodyId
		$HTML = ConvertFrom-Html -Content $response.Content -Raw
		$DependencyTypeTableBody = $HTML.DocumentNode.SelectNodes("//*[contains(@id, 'dependencyTypeTbodyId')]")
		
		$Result = @()
		foreach ($node in $DependencyTypeTableBody.ChildNodes) {
			if ($node.Attributes.Count -gt 0) {
				if ($node.Attributes[0].Name -eq 'id') {
					$TypeId = $node.Attributes[0].Value.Split("_")[1]
					$TypeName = $node.ChildNodes[1].innerText
					$Result += @{ id = $TypeId; label = $TypeName }
				}
			}
		}
	} else {
		return "Unable to collect Dependency Types."
	}

	if ($ResetIDs) {
		for ($i = 0; $i -lt $Result.Count; $i++) {
			$Result[$i].id = $null
		}
	}

	if ($Name) {
		return ($Result | Where-Object { $_.label -eq $Name })
	} else {
		return $Result
	}
}
Function New-TMDependencyType {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][psobject]$DependencyType,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL
	)
	if ($global:TMSessions[$TMSession].TMVersion -like '4.7*') {
		New-TMDependencyType47 @PSBoundParameters

	} else {
		New-TMDependencyType46 @PSBoundParameters
	}
}
Function New-TMDependencyType46 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][psobject]$DependencyType,
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

	# Get existing Dependency Type
	$ExistingDependencyType = Get-TMDependencyType -Name $DependencyType.label -TMSession $TMSession

	if ($ExistingDependencyType) {
		# Write-Host "Dependency Type Exists: "$DependencyType.label
		return
	} else {
		# Write-Host "Creating Dependency Type:"$DependencyType.label
	}

	## Update the Server
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/assetEntity/saveAssetoptions'

	Set-TMHeaderContentType -ContentType 'Form' -TMSession $TMSession

	$PostBody = @{
		dependencyType  = $DependencyType.label
		assetOptionType = 'dependency'
	}

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				if ($PassThru) {
					return $responseContent
				}
			}	
		}
	} catch {
		return $_
	}
}
Function New-TMDependencyType47 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][psobject]$DependencyType,
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

	# Get existing Dependency Type
	$ExistingDependencyType = Get-TMDependencyType -Name $DependencyType.label -TMSession $TMSession
	if ($ExistingDependencyType) {
		# Write-Host "Dependency Type Exists: "$DependencyType.label
		if ($PassThru) { return $ExistingDependencyType } else { return }
	} 

	## Update the Server
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/assetEntity/saveAssetoptions'

	Set-TMHeaderContentType -ContentType 'Form' -TMSession $TMSession

	$PostBody = @{
		dependencyType  = $DependencyType.label
		assetOptionType = 'dependency'
	}

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				if ($PassThru) {
					return $responseContent
				}
			}
		}
	} catch {
		return $_
	}
}