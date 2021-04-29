

## Tasks
Function Get-TMTasks {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][Switch]$JustMine = $false,
		[Parameter(Mandatory = $false)][Switch]$JustActionalble = $false,
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

	# Write-Host "Getting TM Tasks - Just Mine: " $JustMine ", Just Actionable: " $JustActionalble
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/task'
	
	if ($JustMine) { $justMyTasks = 1 } else { $justMyTasks = 0 }
	$uri += '?justMyTasks=' + $justMyTasks
	
	if ($JustActionalble) { $vJustActionalble = 1 } else { $vJustActionalble = 0 }
	$uri += '&justActionable=' + $vJustActionalble
	
	## Using a static one for now
	$uri += '&project=' + $appconfig.TransitionManager.UserContext.projectId

	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	}
	catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$contentJson = $response.Content | ConvertFrom-Json
		Add-Member -InputObject $global:data.TransitionManager -NotePropertyName Tasks -NotePropertyValue $contentJson.data -Force
	}
}

