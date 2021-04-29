
## Projects
Function Get-TMProject {
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
	
	$uri = Get-TMEndpointUri -EndpointName 'Project' -Server $Server
	
	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		

		$Results = Invoke-ResponseHandling -HandlerName 'GetProjectList' -Server $TMVersion
	
	} else {
		return "Unable to collect Projects."
	}

	if ($ResetIDs) {
		
		## Version 4.6.3 is legacy and has a different data structure.  All forward versions are the same
		if ($global:TMSessions[$TMSession].TMVersion -eq '4.6.3') {
			
			## Clear All projects (No nesting here)
			for ($i = 0; $i -lt $Results.Count; $i++) {
				$Results[$i].id = $null
			}

			# 4.7.1+
		} else {
			
			## Clear Active Projects
			for ($i = 0; $i -lt $Results.activeProjects.Count; $i++) {
				$Results.activeProjects[$i].id = $null
			}
			## Clear Active Projects
			for ($i = 0; $i -lt $Results.completedProjects.Count; $i++) {
				$Results.completedProjects[$i].id = $null
			}
		}
	}

	if ($Name) {
		#4.4, 4.5, 4.6
		if ($global:TMSessions[$TMSession].TMVersion -in @('4.4.3', '4.5.9', '4.6.3')) {
			$Result = $Results | Where-Object { $_.name -eq $Name }
			return $Result
		}

		# 4.7+
		else {
			
			foreach ($Project in $Results) {
				if ($Project.name -eq $Name) { return $Project }
			}
			
		}
	} else {
		return $Results
	}
}
Function Enter-TMProject {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)][string]$ProjectName,
		[Parameter(Mandatory = $false)][Int]$ProjectID,
		[Parameter(Mandatory = $false)][Switch]$Create

	)
	try {
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

		## If the Project ID was known, it could be used.  However, support for changing based just on the project name is possible
		if (-not $ProjectID) {
			## Get the Project by Name
			$Project = Get-TMProject -Name $ProjectName -TMSession $TMSession
			$ProjectID = $Project.id 
			if ($ProjectID -eq 0) {
				# if ($Create) {
				
				throw "Project [" + $ProjectName + "] does not exist.  Please create it and run the script again."
				# }
			}
		}

		## 4.4, 4.5, 4.6
		if ($global:TMSessions[$TMSession].TMVersion -in @('4.4.3', '4.5.9' , '4.6.3')  ) {

			$uri = "https://"
			$uri += $Server
			$uri += '/tdstm/project/addUserPreference/' + $ProjectID
		
		}
	
		## 4.7.0+
		# if ($global:TMSessions[$TMSession].TMVersion -in @('4.7.1' , '4.7.2', '4.7.3', '4.7.4', '4.7.4.1')) {
		if ($global:TMSessions[$TMSession].TMVersion -like '4.7*') {

			$uri = "https://"
			$uri += $Server
			$uri += '/tdstm/ws/project/viewEditProject/' + $ProjectID
		
		}

		try {
			$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
		} catch {
			return $_
		}

		if ($response.StatusCode -in @(200,204)) {
			Write-Host 'Project has been changed to: ' -NoNewline
			Write-Host $ProjectName -ForegroundColor Cyan
		} else {
			return "Unable to Set Projects."
		}
	} catch {}
}

Function New-TMProject {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][string]$ProjectName,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$Create
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

	if (-not $ProjectID) {
		$ProjectID = (Get-TMProject -Name $ProjectName -TMSession $TMSession).id
		if ($ProjectID -eq 0) {
				
			throw "Project [" + $ProjectName + "] does not exist.  Please create it and run the script again."
		}
	}
	

	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	
	$uri = "https://"
	$uri += $instance
	
	$uri += '/tdstm/project/addUserPreference/' + $ProjectID

	

	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -in @(200, 204)) {
		Write-Host "Project has been changed to: "$ProjectName
	} else {
		return "Unable to Set Projects."
	}
}
