## TM ETL Scripts
Function Get-TMETLScript {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$ResetIDs, 
		[Parameter(Mandatory = $false)][String]$SaveCodePath,
		[Parameter(Mandatory = $false)][Switch]$Label,
		[Parameter(Mandatory = $false)][Switch]$Passthru
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
	$uri += "/tdstm/ws/dataingestion/datascript/list"

	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$Result = ($response.Content | ConvertFrom-Json).data
		if ($Result.Count -eq 0) { return $false }
	} else {
		return "Unable to collect ETL Scripts."
	}
	
	## Get each ETL Script's Source Code in the list
	for ($i = 0; $i -lt $Result.Count; $i++) {
		
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/dataingestion/datascript/' + $Result[$i].id
		try {
			$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
		} catch {
			return $_
		}

		if ($response.StatusCode -eq 200) {
			$Result[$i] = ($response.Content | ConvertFrom-Json).data.datascript
		} else {
			return "Unable to collect ETL Scripts."
		}
	}

	if ($ResetIDs) {
		for ($i = 0; $i -lt $Result.Count; $i++) {
			$Result[$i].id = $null
			$Result[$i].provider.id = $null
		}
	}

	## Return the details
	if ($Name) {
		$Output = $Result | Where-Object { $_.name -eq $Name }

	} else {
		
		$Output = $Result
	}

	
	## Save the Code Files to a folder
	if ($SaveCodePath) {

		## Save Each of the Script Source Data
		foreach ($Item in (ConvertTo-Array $Output)) {

			## Get a FileName safe version of the Provider Name
			$SafeProviderName = Get-FilenameSafeString -String $Item.provider.name
			$SafeActionName = Get-FilenameSafeString -String $Item.name

			## Create the Provider Action Folder path
			$ProviderPath = Join-Path $SaveCodePath  $SafeProviderName
			Test-FolderPath -FolderPath $ProviderPath
		
			## Create a File ame for the Action
			$ProviderScriptPath = Join-Path $ProviderPath  ($SafeActionName + '.groovy')

			## Build a config of the important References
			$TMConfig = [PSCustomObject]@{
				EtlScriptName = $Item.name
				Description   = $Item.description
				ProviderName  = $Item.provider.name
				IsAutoProcess = $Item.isAutoProcess
				Target        = $Item.target
				Mode          = $Item.mode
			} | ConvertTo-Json | Out-String

			## Create a Script String output
			$ScriptOutput = [System.Text.StringBuilder]::new()
			$ScriptOutput.AppendLine("/*********TransitionManager-ETL-Script*********") | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
			$ScriptOutput.AppendLine($TMConfig) | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
		
			$ScriptOutput.AppendLine('*********TransitionManager-ETL-Script*********/') | Out-Null
	
			$ScriptOutput.AppendLine() | Out-Null
	
			## Write the Script to the Configuration
			$ScriptOutput.AppendLine($Item.etlSourceCode) | Out-Null
			$ScriptOutput.AppendLine() | Out-Null

			## Start Writing the Content of the Script (Force to overwrite any existing files)
			Set-Content -Path $ProviderScriptPath -Force -Value $ScriptOutput.toString()
		}
	} else {
		return $Output
	}
}
Function New-TMETLScript {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$ETLScript,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][switch]$Update

	)	
	if ($global:TMSessions[$TMSession].TMVersion -like '4.6.*') {
		New-TMETLScript46 @PSBoundParameters
	} else {
		New-TMETLScript47 @PSBoundParameters
	}
}
Function New-TMETLScript46 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$ETLScript,
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

	$ETLScriptName = $ETLScript.name
	$ExistingETLScript = Get-TMETLScript -Name $ETLScriptName -TMSession $TMSession
	if ($ExistingETLScript) {
		# Write-Host "ETL Script Exists: "$ETLScriptName
		if ($PassThru) { return $ExistingETLScript } else { return }
	} 

	## Action 0 (Renumber) - Confirm the name is unique
	$uri = "https://"
	$uri += $Server
	$uri += '/tdstm/ws/dataingestion/datascript/validateUnique'

	$PostBodyJSON = @{
		name       = $ETLScriptName
		providerId = (Get-TMProvider -Name $ETLScript.provider.name -TMSession $TMSession).id
	} | ConvertTo-Json -Depth 100

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings 
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				$isUnique = $responseContent.data.isUnique
				if ($isUnique -ne $true) {
					$thisETLScript = Get-TMETLScript -Name $ETLScriptName -TMSession $TMSession
				}
			}	
		}
	} catch {
		Write-Host "Unable to determine if ETL Script Name is unique."
		return $_
	}

	
	## Action 2, Create the ETL Script so the Script code can be saved into it. 
	$uri = "https://"
	$uri += $Server
	$uri += '/tdstm/ws/dataingestion/datascript'

	## If there is an existing ETL script, update it
	if ($thisETLScript) {
		$ETLScript.id = $thisETLScript.id
		$uri += '/' + $ETLScript.id
	} else {
		$ETLScript.PSObject.properties.Remove('id')
	}
	
	## Lookup Cross References
	$ProviderID = (Get-TMProvider -TMSession $TMSession | Where-Object { $_.name -eq $ETLScript.provider.name }).id

	$PostBodyJSON = @{
		name        = $ETLScriptName
		mode        = $ETLScript.mode
		description = $ETLScript.description
		providerId  = $ProviderID
		# etlSourceCode = $ETLScript.etlSourceCode
	} | ConvertTo-Json -Depth 100

	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				
				$NewETLScript = $responseContent.data.datascript
				$PostBodyJSON = @{
					id     = $NewETLScript.id
					script = $ETLScript.etlSourceCode
				} | ConvertTo-Json -Depth 100

				$uri = "https://"
				$uri += $Server
				$uri += '/tdstm/ws/dataingestion/dataScript/saveScript'
				$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
				if ($response.StatusCode -eq 200) {
					$responseContent = $response.Content | ConvertFrom-Json
					if ($responseContent.status -eq 'success') {
						if ($PassThru) { return $responseContent.data.dataScript } else { return }
					}
				}
			}	
		}
	} catch {
		Write-Host "Unable to create ETL script."
		return $_
	}
	
}
Function New-TMETLScript47 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$ETLScript,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][switch]$Update

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

	## Look for an existing Script
	$ETLScriptName = $ETLScript.name
	$ExistingETLScript = Get-TMETLScript -Name $ETLScriptName -TMSession $TMSession
	
	## If the Script should not be updated, return it
	if ($ExistingETLScript) {

		## End the function if there is not an update to be made
		if ($Update) {
			
			## Record the ETLScriptId for the update
			$ETLScriptID = $ExistingETLScript.id

		} else {
			
			## If $PassThru is present, return the Existing ETL script.
			if ($PassThru) {
				return $ExistingETLScript
			} else { 
				return 
			}

		}
	} else {
		
		## Lookup Provider ID
		$ProviderID = (Get-TMProvider -TMSession $TMSession -Name $ETLScript.provider.name ).id
		if ($null -eq $ProviderID) {
			Throw ("Provider: " + $ETLScript.provider.name + " does not exist.")
		}
		
		## There is not an existing ETL Script, Create the basic
		## Create the shell ETL object, which must be created first
		$PostBodyJSON = @{
			description = $ETLScript.description
			mode        = $ETLScript.mode
			name        = $ETLScript.name
			providerId  = $ProviderID
		} | ConvertTo-Json -Compress

		try {
			
			$uri = "https://"
			$uri += $Server
			$uri += '/tdstm/ws/dataingestion/datascript'

			## Post the ETL Object to the server
			Set-TMHeaderContentType -ContentType JSON
			$response = Invoke-WebRequest -Method 'POST' -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
			if ($response.StatusCode -eq 200) {
				$responseContent = $response.Content | ConvertFrom-Json
				if ($responseContent.status -eq "success") {
				
					## Now that the shell exists, get it's ID
					$ETLScriptID = $responseContent.data.datascript.id
					
				}	
			}
		} catch {
			Write-Host "Unable to create ETL script."
			return $_
		}

	}

	## Now that we have an ID for the ETL script, send the source code content
	$PostBodyJSON = @{
		id     = $ETLScriptID
		script = $ETLScript.etlSourceCode
	} | ConvertTo-Json -Depth 100

	try {
		
		## Post the Source to be saved for this script.
		$uri = "https://"
		$uri += $Server
		$uri += '/tdstm/ws/dataScript/saveScript'
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq 'success') {
				if ($PassThru) {
					return $responseContent.data.dataScript
				} 
			}
		} elseif ($response.StatusCode -eq 204) {
			return
		}
	} catch {
		Write-Host "Unable to save ETL Source to server"
		return $_
	}
	
}

Function Invoke-TMETLScript {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][String]$ETLScriptName,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][bool]$QueueBatches = $false,
		[Parameter(Mandatory = $false)][bool]$MonitorBatches = $false,
		[Parameter(Mandatory = $true)][String]$DataType,
		[Parameter(Mandatory = $false)]$Data,
		[Parameter(Mandatory = $false)][String]$FilePath,
		[Parameter(Mandatory = $false)][String]$FileName,
		[Parameter(Mandatory = $false)][Int16]$ActivityId,
		[Parameter(Mandatory = $false)][Int16]$ParentActivityId = -1
	)

	## This function wraps the appropriate version of the function to handle the Invoke-ETL Request
	if ($global:TMSessions[$TMSession].TMVersion) {
		$TMVersion = $global:TMSessions[$TMSession].TMVersion
	} else {
		$TMVersion = $TMVersion = Get-TMVersion -TMSession $TMSession -Server $Server
	}

	$InvocationParameters = $MyInvocation.BoundParameters
	if (($TMVersion -like "4.7*") -or ($TMVersion -like "5.0*")) {
		Invoke-TMETLScript474 @InvocationParameters
	} elseif ($TMVersion -in @("4.5.9", '4.6.3')) {
		Invoke-TMETLScript46 @InvocationParameters
	} else {
		Throw 'TM Version is not supported by this function.'
	}

}

Function Invoke-TMETLScript47 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][String]$ETLScriptName,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][bool]$QueueBatches = $false,
		[Parameter(Mandatory = $false)][bool]$MonitorBatches = $false,
		[Parameter(Mandatory = $true)][String]$DataType,
		[Parameter(Mandatory = $false)]$Data,
		[Parameter(Mandatory = $false)][String]$FilePath,
		[Parameter(Mandatory = $false)][String]$FileName,
		[Parameter(Mandatory = $false)][Int16]$ActivityId,
		[Parameter(Mandatory = $false)][Int16]$ParentActivityId = -1
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

	## If a File Path was passed and there is no data, Read the file
	if ($FileName -and -not $Data) {
		$Data = Get-Content $FileBody
	}

	if ($ActivityId) {
		## Parent ID is only used on the root 'TransitionManager Data Import' Activity
		## ParentID + 1 = Import Batches
		## ParentID + 2 + n for each batch

		## Add the ETL Processing Progress Indicators
		$ProgressIndicators = @()
		$ProgressIndicators += @{ Id = $ActivityId; Activity = 'TransitionManager Data Import'; ParentId = $ParentActivityId }
		$ProgressIndicators += @{ Id = ($ActivityId + 1); Activity = 'ETL Data Transformation'; ParentId = $ActivityId }
		$ProgressIndicators += @{ Id = ($ActivityId + 2); Activity = 'Manage Batches'; ParentId = $ActivityId }
		
		#Write Progress Indicators for each in the Array
		$ProgressIndicators | ForEach-Object {
			Write-Progress @_ -CurrentOperation 'Queued' -PercentComplete 0
		}
	}
	
	## Fix the Server URL
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')

	$Boundary = '----------------------------540299933173025267350719'

	## First Test to see if the ETL Script exists or not
	if ($ActivityId) { 
		
		Write-Progress -Id ($ActivityId + 1) -ParentId $ActivityId -Activity 'ETL Data Transformation' -CurrentOperation 'Validating ETL Script' -Status 'Confirming ETL Script exists in TransitionManager' -PercentComplete 5
	}
	$ETLScript = Get-TMETLScript -TMSession $TMSession -Name $ETLScriptName
	if (-Not $ETLScript) { Throw  'The ETL Script [' + $ETLScriptName + '] does not exist' }
	
	## Build the Data Post
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/fileSystem/uploadFileETLAssetImport"
		
	## FileName
	if (-not $FileName) {
		$FileName = ('DataForETL_' + (Get-Date -Format FileDateTime ) + '.' + $DataType)
	}
	$FileLine = 'Content-Disposition: form-data; name="file"; filename="' + $FileName + '"'
	
	$CRLF = "`r`n";
	switch ($DataType) {
		'json' { 
			$PostBody = ("-----------------------------$boundary",
				'Content-Disposition: form-data; name="uploadType"',
				'',
				'assetImport',
			
				"-----------------------------$boundary",
				$FileLine,
				"Content-Type: application/json",
				'',
				($Data | ConvertTo-Json -Depth 100),
				"-----------------------------$boundary--",
				''
			) -join $CRLF
		}
		'csv' { 
			# $csvData = ($Data | ConvertTo-Csv -NoTypeInformation) -join $CRLF
			$PostBody = ("-----------------------------$boundary",
				'Content-Disposition: form-data; name="uploadType"',
				'',
				'assetImport',
				
				"-----------------------------$boundary",
				$FileLine,
				"Content-Type: application/vnd.ms-excel",
				'',
				$Data,
				'',
				"-----------------------------$boundary--",
				''
			) -join $CRLF
		}
		'xlsx' { 
			$PostBody = ("-----------------------------$boundary",
				'Content-Disposition: form-data; name="uploadType"',
				'',
				'assetImport',
			
				"-----------------------------$boundary",
				$FileLine,
				"Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
				'',
				(Get-Content $Data -Encoding 'UTF-8' -Raw ),
				"-----------------------------$boundary--",
				''
			) -join $CRLF
		}
		Default { }
	}
	

	## Upload the Data File
	if ($ActivityId) { 
		Write-Progress -Id ($ActivityId + 1) -ParentId $ActivityId -Activity 'ETL Data Transformation' -CurrentOperation 'Uploading Data' -Status ('Uploading ' + $FileName)  -PercentComplete 5
	}
	
	$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession ` ##-Body $PostBody `
	-ContentType ('multipart/form-data; boundary=---------------------------' + $boundary) @TMCertSettings
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
			$ETLdataFileName = $responseContent.data.filename
		} else { 
			Throw "Unable to upload data to TM ETL pre-transform storage."
		}
	}

	## With the file uploaded, Initiate the ETL script on the server
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/assetImport/initiateTransformData"
	$uri += "?dataScriptId=" + $ETLScript.id
	$uri += "&filename=" + $ETLdataFileName
						
	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
						
	## Post the data starting the ETL process.  A progress key is provided.  This progress key is what can be used to poll for the status of the ETL script		
	if ($ActivityId) { 
		Write-Progress -Id ($ActivityId + 1) -ParentId $ActivityId -Activity 'ETL Data Transformation' -CurrentOperation 'Starting ETL Processing' -PercentComplete 5
	} else {
		Write-Host 'TransitionManager Data Import: Starting ETL Processing'
	}
	
	$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
			$ETLProgressKey = $responseContent.data.progressKey
		} else {
			throw $responseContent.errors
		}
	} else {
		Throw $response
	}
	
	
	## Supply Progress from ETL Transformation Progress		
	if ($ActivityId) { 
		Write-Progress -Id $($ActivityId + 1) -Activity 'ETL Data Transformation' -CurrentOperation 'Running ETL Transformation'  -PercentComplete 0 -ParentId $ActivityId
	} else {
		Write-Host 'ETL Data Transformation: Starting ETL Processing'
	}
				
	## The ETL is underway, Setup a progress URL
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/progress/" + $ETLProgressKey
	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
				
	## Poll for the status of the ETL engine
	$Completed = $false
	while ($Completed -eq $false) {
			
		## Post the data starting the ETL process.  A progress key is provided.  This progress key is what can be used to poll for the status of the ETL script
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				$ETLProgress = $responseContent.data
									
				switch ($ETLProgress.status) {
					"Queued" { 
						
						$CurrentOperation = 'ETL Queued'
						$Status = 'Queued'
						$ProgressString = 'Status - Queued: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2	
						
					}
					"Pending" { 
						$CurrentOperation = 'ETL Pending'
						$Status = 'Pending'
						$ProgressString = 'Status - Pending: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2	
					}
					"RUNNING" { 
						$CurrentOperation = 'ETL Running'
						$Status = 'Transforming Data'
						$ProgressString = 'Status - Running: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2	
					}
					"COMPLETED" {
						$EtlOutputKey = $ETLProgress.detail
						$CurrentOperation = 'ETL Processing Complete'
						$Status = 'Creating Import Batches'
						$Completed = $true
						$SleepSeconds = 0
						$PercentComplete = 99
						$ProgressString = "Status - ETL Processing Complete, Creating Import Batches."
					}
					"Failed" {
						$CurrentOperation = 'Failed'
						$Status = $ETLProgress.status
						Write-Host "ETL Processing Failed "$ETLProgress.detail
						Throw $ETLProgress.detail
					}
					Default { 
						$CurrentOperation = 'State Unknown'
						$Status = 'Unknown.  Sleeping to try again.'
						$ProgressString = "Unknown Status: " + $ETLProgress.status
						$PercentComplete = 99
						$SleepSeconds = 2
					}
				}
				
				## Notify the user of the ETL Progress
				if ($ActivityId) { 
					Write-Progress -Id ($ActivityId + 1) `
						-ParentId $ActivityId `
						-Activity 'ETL Data Transformation' `
						-CurrentOperation $CurrentOperation `
						-Status $Status `
						-PercentComplete $PercentComplete
				} else {
					Write-Host $ProgressString
				}
				Start-Sleep -Seconds $SleepSeconds
			}	
		}	
	}

	## Notify the user of the ETL Completion
	if ($ActivityId) { 
		Write-Progress -Id ($ActivityId + 1) `
			-ParentId $ActivityId `
			-Activity 'ETL Data Transformation' `
			-CurrentOperation 'ETL Processing Complete'  `
			-Status 'Creating Import Batches' `
			-PercentComplete 99
		Write-Progress -Id ($ActivityId + 2) `
			-ParentId $ActivityId `
			-Activity 'Manage Batches' `
			-CurrentOperation 'Creating Import Batches'  `
			-Status 'Creating Import Batches' `
			-PercentComplete 1
	} else {
		Write-Host 'ETL Processing Complete, Creating Import Batches'
	}

	## With the ETL converted, Use it to create Import Batches
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/assetImport/loadData?filename="
	$uri += $EtlOutputKey
							
	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
							
	## Post the Transformed data filename to the ETL engine to Import the Batches.
	$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
			$Batches = $responseContent.data
				
			## Print the results of the ETL Transformation Process
			if ($ActivityId) { 
				Write-Progress -Id ($ActivityId + 1) `
					-ParentId $ActivityId `
					-Activity 'ETL Data Processing' `
					-CurrentOperation 'Batches Created' `
					-Status ([string]$Batches.batchesCreated + ' Batches created') `
					-PercentComplete 100
				Write-Progress -Id ($ActivityId + 2) `
					-ParentId $ActivityId `
					-Activity 'Manage Batches' `
					-CurrentOperation 'Batches Created' `
					-Status ([string]$Batches.batchesCreated + ' Batches created') `
					-PercentComplete 1
			} else {
				Write-Host "Batches Created:" $Batches.batchesCreated
			}
		}	
	} else {
		Throw 'Failed to Import ETL Result.'
	}
	
	## Complete the Transformation Activity
	Write-Progress -Id ($ActivityId + 1) `
		-ParentId $ActivityId `
		-Activity 'ETL Data Transformation' `
		-CurrentOperation 'Batch Creation Complete'  `
		-Status ('Created ' + [string]$Batches.batchesCreated + 'Import Batches') `
		-PercentComplete 100 `
		-Complete

	if ($QueueBatches) {
		
		## Assemble the batch list object.  Dependencies are deliberately moved to the end
		$BatchesToProcess = [System.Collections.ArrayList]@()

		## Separate Asset batches from dependency Batches
		$Batches.domains | Where-Object { $_.domainClass -ne 'Dependency' } | ForEach-Object { $BatchesToProcess.Add($_) | Out-Null }
		$Batches.domains | Where-Object { $_.domainClass -eq 'Dependency' } | ForEach-Object { $BatchesToProcess.Add($_) | Out-Null }
	
		## Write Progress to the Monitor Import Batches 
		if ($ActivityId) { 
			Write-Progress -Id ($ActivityId + 2) `
				-ParentId $ActivityId `
				-Activity 'Manage Batches' `
				-CurrentOperation 'Queueing Batches' `
				-Status ('Queueing ' + [string]$Batches.batchesCreated + ' batches.') `
				-PercentComplete 5
		} else {
			Write-Host "Queueing Batches:" $Batches.batchesCreated
		}

		## Add a Progress Activity for each of the Import Batches
		for ($i = 0; $i -lt $BatchesToProcess.Count; $i++) {
			
			## Set Variable for Batch
			$Batch = $BatchesToProcess[$i]

			## Create Progress Results for the batches that were created
			if ($ActivityId) { 
			
				## Activity Explained: The $ActivityId is considered the (Root) + 2 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
				Write-Progress -Id ($ActivityId + 3 + $i + 1) `
					-ParentId ($ActivityId + 2) `
					-Activity ('Batch: ' + $Batch.batchId + ' | ' + $Batch.rowsCreated + ' ' + $Batch.domainClass) `
					-CurrentOperation 'Queueing Batch' `
					-Status ([String]$Batch.rowsCreated + ' ' + $Batch.domainClass + ' records created.') `
					-PercentComplete 0
			} else {
				Write-Host "Batch Created: " $Batch.rowsCreated $Batch.domainClass 'records created.'
			}
		}

		## Queue each Batch
		for ($i = 0; $i -lt $BatchesToProcess.Count; $i++) {
			
			## Set Variable for Batch
			$Batch = $BatchesToProcess[$i]
			if ($Batch.rowsCreated -gt 0) {

				## With the file uploaded, Initiate the ETL script on the server
				$uri = "https://"
				$uri += $instance
				$uri += "/tdstm/ws/import/batches"
								
				Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
			
				$PostBody = @{ 
					action = 'QUEUE'
					ids    = $Batch.batchId
				} | ConvertTo-Json -Depth 100


				## Post this batch to begin it's Queueing
				$response = Invoke-WebRequest -Method Patch -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
				if ($response.StatusCode -eq 200) {
					$responseContent = $response.Content | ConvertFrom-Json
					if ($responseContent.status -eq "success") {
						
						## Create Progress Results for the batches that were created
						if ($ActivityId) { 
							
							## Notify the Manage Batches Activity of a queued batch
							Write-Progress -Id ($ActivityId + 2) `
								-ParentId $ActivityId `
								-Activity 'Manage Batches' `
								-CurrentOperation 'Queueing Batches' `
								-Status ('Queued ' + $Batch.domainClass + ' Batch') `
								-PercentComplete 5

							## Activity (Root) + 2 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
							Write-Progress -Id ($ActivityId + 3 + $i + 1) `
								-ParentId ($ActivityId + 2) `
								-Activity ('Batch: ' + $Batch.batchId + ' | ' + $Batch.rowsCreated + ' ' + $Batch.domainClass) `
								-CurrentOperation 'Batch Queued'  `
								-Status 'Queued' `
								-PercentComplete 0
						} else {
							Write-Host "Batch Queued:" $Batch.domainClass
						}
					} else {
						Throw 'Failed to Queue Batch'
					}	
				} else {
					Throw 'Failed to Queue Batch.'
				}
			}
		}
	}

	## Allow the batch to be monitored and reported on in the UI
	if ($MonitorBatches) {
		$BatchStatus = @{
			CompletedBatches = 0
			TotalBatches     = $BatchesToProcess.Count
		}
		
		## Monitor the batches to completion
		for ($i = 0; $i -lt $BatchesToProcess.Count; $i++) {
			
			## Set Variable for Batch
			$Batch = $BatchesToProcess[$i]
			if ($Batch.rowsCreated -gt 0) {
				## With the file uploaded, Initiate the ETL script on the server
				$uri = "https://"
				$uri += $instance
				$uri += "/tdstm/ws/import/batch/"
				$uri += $Batch.batchId
				$uri += "/progress"
									
				Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
				
				## Poll for the status of the Import Batch
				if ($ActivityId) { 
					
					## Activity (Root) + 2 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
					Write-Progress -Id ($ActivityId + 3 + $i + 1) `
						-ParentId ($ActivityId + 2) `
						-Activity ('Batch: ' + $Batch.batchId + ' | ' + $Batch.rowsCreated + ' ' + $Batch.domainClass) `
						-CurrentOperation 'Monitoring Progress'  `
						-Status 'Importing' `
						-PercentComplete 1
				} else {
					Write-Host 'Getting Status for '$Batch.domainClass
				}

				## Start a loop to run while the batch is not complete.
				$Completed = $false
				while ($Completed -eq $false) {
					
					## Post the data starting the ETL process.  A progress key is provided.  This progress key is what can be used to poll for the status of the ETL script
					$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
					if ($response.StatusCode -eq 200) {
						$responseContent = $response.Content | ConvertFrom-Json
						if ($responseContent.status -eq "success") {
							
							$BatchProgress = $responseContent.data
							
							switch ($BatchProgress.status.code) {
								"RUNNING" { 
									$CurrentOperation = 'Import Running'
									$Status = 'Importing Batch Data'
									$ProgressString = $DomainClass + ' Import Running: ' + $BatchProgress.progress + "%"
									$PercentComplete = $BatchProgress.progress	
									$SleepSeconds = 2	
								}
								"QUEUED" { 
									$CurrentOperation = 'Batch Queued'
									$Status = 'Batch Queued'
									$ProgressString = $DomainClass + ' status: Queued'
									$PercentComplete = $BatchProgress.progress	
									$SleepSeconds = 2	
									
								}
								"PENDING" { 
									$CurrentOperation = 'Batch Pending'
									$Status = 'Batch Pending'
									$ProgressString = $DomainClass + ' status: Pending'
									$PercentComplete = $BatchProgress.progress	
									$SleepSeconds = 2
									
								}
								"COMPLETED" {
									$Completed = $true
									$CurrentOperation = 'Complete'
									$Status = 'Complete'
									$ProgressString = ($batch.domainClass + "Importing Complete")
									$PercentComplete = 100
									$SleepSeconds = 0

								}
								Default { 
									$CurrentOperation = 'Status Unknown.  Retrying'
									$Status = 'Retrying'
									$ProgressString = ($batch.domainClass + "Status Unkown. Retrying")
									$PercentComplete = 1	
									$SleepSeconds = 2
										
								}
							}
							
							## Display the Status of this loop
							if ($ActivityId) { 
					
								## Activity (Root) + 2 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
								Write-Progress -Id ($ActivityId + 3 + $i + 1) `
									-ParentId ($ActivityId + 3) `
									-Activity ('Batch: ' + $Batch.batchId + ' | ' + $Batch.rowsCreated + ' ' + $Batch.domainClass) `
									-CurrentOperation $CurrentOperation  `
									-Status $Status  `
									-PercentComplete $PercentComplete
							} else {
								Write-Host $ProgressString
							}
							
							## Calcuate Percentage for Manage Batches progress bar.  This is based on how many batches there are, how many are done and what percentage we have in this loop
							$ManageBatchesPercentage = ((($BatchStatus.CompletedBatches * 100) + $PercentComplete) / ($BatchStatus.TotalBatches * 100))
							
							Write-Progress -Id ($ActivityId + 2) `
								-ParentId $ActivityId `
								-Activity 'Manage Batches' `
								-CurrentOperation 'Monitoring Progress'  `
								-Status 'Processing' `
								-PercentComplete $ManageBatchesPercentage
							
							## Increate how many jobs are marked as completed
							Start-Sleep -Seconds $SleepSeconds
						}	
					}
				}
			}
			## Now that this batch is done, increment the Completed Batches counter
			$BatchStatus.CompletedBatches++
		}

		## Mark the Manage Batches Activity Complete
		if ($ActivityId) {
			Write-Progress -Id ($ActivityId + 2) `
				-ParentId $ActivityId `
				-Activity 'Manage Batches' `
				-CurrentOperation 'Complete'  `
				-Status 'All Batches Imported' `
				-PercentComplete 100
		}
	}

	## Mark the TM Import Activity complete
	if ($ActivityId) {
		Write-Progress -Id $ActivityId `
			-ParentId $ParentActivityId `
			-Activity 'TransitionManager Data Import' `
			-CurrentOperation 'Complete'  `
			-Status 'All Data Imported' `
			-PercentComplete 100
	}
}

Function Invoke-TMETLScript474 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][String]$ETLScriptName,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][bool]$QueueBatches = $false,
		[Parameter(Mandatory = $false)][bool]$MonitorBatches = $false,
		[Parameter(Mandatory = $true)][String]$DataType,
		[Parameter(Mandatory = $false)]$Data,
		[Parameter(Mandatory = $false)][String]$FilePath,
		[Parameter(Mandatory = $false)][String]$FileName,
		[Parameter(Mandatory = $false)][Int16]$ActivityId,
		[Parameter(Mandatory = $false)][Int16]$ParentActivityId = -1
	)
	## Get Session Configuration
	$TMSessionConfig = $global:TMSessions[$TMSession]
	if (-not $TMSessionConfig) {
		Write-Host 'TMSession: [' -NoNewline
		Write-Host $TMSession -ForegroundColor Cyan
		Write-Host '] was not Found. Please use the New-TMSession command.'
		Throw "TM Session Not Found.  Use New-TMSession command before using features."
	}
	
	## If a File Path was passed and there is no data, Read the file
	if ($FilePath -and -not $Data) {
		$Data = Get-Content $FilePath -Raw
		$FileName = (Get-Item $FilePath).Name
	}
	
	## If a File Path was passed and there is no File Name, get the file name
	if ($FilePath -and -not $FileName) {
		$FileName = (Get-Item $FilePath).Name
	}
	
	#Honor SSL Settings
	if ($TMSessionConfig.AllowInsecureSSL) {
		$TMCertSettings = @{SkipCertificateCheck = $true }
	} else { 
		$TMCertSettings = @{SkipCertificateCheck = $false }
	}
	
	if ($ActivityId) {
		## Parent ID is only used on the root 'TransitionManager Data Import' Activity
		## ParentID + 1 = Transform Data
		## ParentID + 2 = Import Batches
		## ParentID + 3 + n for each batch

		## Add the ETL Processing Progress Indicators
		$ProgressIndicators = @()
		$ProgressIndicators += @{ Id = $ActivityId; Activity = 'TransitionManager Data Import'; ParentId = $ParentActivityId }
		$ProgressIndicators += @{ Id = ($ActivityId + 1); Activity = 'ETL Data Transformation'; ParentId = $ActivityId }
		$ProgressIndicators += @{ Id = ($ActivityId + 2); Activity = 'Import Batches'; ParentId = $ActivityId }
		$ProgressIndicators += @{ Id = ($ActivityId + 3); Activity = 'Monitor Batches'; ParentId = $ActivityId }
		
		#Write Progress Indicators for each in the Array
		$ProgressIndicators | ForEach-Object {
			Write-Progress @_ -CurrentOperation 'Queued' -PercentComplete 0
		}
	}
	
	## Fix the Server URL
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')

	$Boundary = '----------------------------540299933173025267350719'

	## First Test to see if the ETL Script exists or not
	if ($ActivityId) { 
		
		Write-Progress -Id ($ActivityId + 1) -ParentId $ActivityId -Activity 'ETL Data Transformation' -CurrentOperation 'Validating ETL Script' -Status 'Confirming ETL Script exists in TransitionManager' -PercentComplete 5
	}
	$ETLScript = Get-TMETLScript -TMSession $TMSession -Name $ETLScriptName
	if (-Not $ETLScript) { Throw  'The ETL Script [' + $ETLScriptName + '] does not exist' }
	
	## Build the Data Post
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/fileSystem/uploadFileETLAssetImport"
		
	## FileName
	if (-not $FileName) {
		$FileName = ('DataForETL_' + (Get-Date -Format FileDateTime ) + '.' + $DataType)
	}
	$FileLine = 'Content-Disposition: form-data; name="file"; filename="' + $FileName + '"'
	
	$CRLF = "`r`n";
	switch ($DataType) {
		'json' { 
			$PostBody = ("-----------------------------$boundary",
				'Content-Disposition: form-data; name="uploadType"',
				'',
				'assetImport',
			
				"-----------------------------$boundary",
				$FileLine,
				"Content-Type: application/json",
				'',
				($Data | ConvertTo-Json -Depth 100),
				"-----------------------------$boundary--",
				''
			) -join $CRLF
			break
		}
		'csv' { 
			# $csvData = ($Data | ConvertTo-Csv -NoTypeInformation) -join $CRLF
			$PostBody = ("-----------------------------$boundary",
				'Content-Disposition: form-data; name="uploadType"',
				'',
				'assetImport',
			
				"-----------------------------$boundary",
				$FileLine,
				"Content-Type: application/vnd.ms-excel",
				'',
				$Data,
				'',
				"-----------------------------$boundary--",
				''
			) -join $CRLF
			break
		}
		'xls' { 
			$FileBody = [System.IO.File]::ReadAllBytes($FilePath)
			$Enc = [System.Text.Encoding]::GetEncoding("utf-8")
			$FileBodyString = $Enc.GetString($FileBody)
			# $FileBodyString = Get-Content -Path $FilePath -Encoding Byte
			
			$PostBody = ("-----------------------------$boundary",
				'Content-Disposition: form-data; name="uploadType"',
				'',
				'assetImport',
				"-----------------------------$boundary",
				$FileLine,
				"Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
				'',
				$FileBodyString,
				"-----------------------------$boundary--",
				''
			) -join $CRLF
			$FileUpload = @{
				Form = @{
					uploadType = 'assetImport'
					file       = Get-Item -Path $FilePath
					fileName   = $FileName
				}
			}
			break
		}
		'xlsx' { 
			# $FileBody = [System.IO.File]::ReadAllBytes($FilePath)
			# $Enc = [System.Text.Encoding]::GetEncoding("utf-8")
			# $FileBodyString = $Enc.GetString($FileBody)
			
			# $FileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
			# # $FileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
			# #$FileHeader.Name = $FieldName
			# # $FileHeader.FileName = Split-Path -Leaf $FilePath
			# $FileContent = [System.Net.Http.StreamContent]::new($FileStream)
			
			# $FileBodyString = Get-Content -Path $FilePath -Encoding Byte
			
			$FileBodyBytes = [System.IO.File]::ReadAllBytes($FilePath)
			# $Enc = [System.Text.Encoding]::GetEncoding("utf-8")
			# $FileBodyString = $Enc.GetBytes($FileBodyBytes)
			
			$PostBody = ("-----------------------------$boundary",
				'Content-Disposition: form-data; name="uploadType"',
				'',
				'assetImport',
				"-----------------------------$boundary",
				# $FileLine,
				# "Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;", #  charset=utf-8",
				# '',
				# $($FileBodyBytes),
				# "-----------------------------$boundary--",
				''
			) -join $CRLF
			$FileUpload = @{
				Form = @{
					uploadType = 'assetImport'
					file       = Get-Item -Path $FilePath
					fileName   = $FileName
				}
			}

			break
		}
		Default { }
	}
	

	## Upload the Data File
	if ($ActivityId) { 
		Write-Progress -Id ($ActivityId + 1) -ParentId $ActivityId -Activity 'ETL Data Transformation' -CurrentOperation 'Uploading Data' -Status ('Uploading ' + $FileName)  -PercentComplete 5
	}
	
	try {

		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -ContentType ('multipart/form-data; boundary=---------------------------' + $boundary) @TMCertSettings @FileUpload
	} catch {
		throw $_
	}
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
			$ETLdataFileName = $responseContent.data.filename
		} else { 
			Throw "Unable to upload data to TM ETL pre-transform storage."
		}
	}

	## With the file uploaded, Initiate the ETL script on the server
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/assetImport/initiateTransformData"
	$uri += "?dataScriptId=" + $ETLScript.id
	$uri += "&filename=" + $ETLdataFileName
						
	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession

	## Post the data starting the ETL process.  A progress key is provided.  This progress key is what can be used to poll for the status of the ETL script		
	if ($ActivityId) { 
		Write-Progress -Id ($ActivityId + 1) -ParentId $ActivityId -Activity 'ETL Data Transformation' -CurrentOperation 'Starting ETL Processing' -PercentComplete 5
	} else {
		Write-Host 'TransitionManager Data Import: Starting ETL Processing'
	}
	
	$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
			$ETLProgressKey = $responseContent.data.progressKey
		} else {
			throw $responseContent.errors
		}
	} else {
		Throw $response
	}
	
	
	## Supply Progress from ETL Transformation Progress		
	if ($ActivityId) { 
		Write-Progress -Id $($ActivityId + 1) -Activity 'ETL Data Transformation' -CurrentOperation 'Running ETL Transformation'  -PercentComplete 0 -ParentId $ActivityId
	} else {
		Write-Host 'ETL Data Transformation: Starting ETL Processing'
	}
			
	## The ETL is underway, Setup a progress URL
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/progress/" + $ETLProgressKey
	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
				
	## Poll for the status of the ETL engine
	## TODO: This should be converted to a function for polling the job engine.  It's nearly dupilcated now in the Import Batch watching.
	$Completed = $false
	while ($Completed -eq $false) {
			
		## Post the data starting the ETL process.  A progress key is provided.  This progress key is what can be used to poll for the status of the ETL script
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				$ETLProgress = $responseContent.data
									
				switch ($ETLProgress.status) {
					"Queued" { 
						
						$CurrentOperation = 'ETL Queued'
						$Status = 'Queued'
						$ProgressString = 'Status - Queued: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2
						Break
						
					}
					"Pending" { 
						$CurrentOperation = 'ETL Pending'
						$Status = 'Pending'
						$ProgressString = 'Status - Pending: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2
						Break
					}
					"RUNNING" { 
						$CurrentOperation = 'ETL Running'
						$Status = 'Transforming Data'
						$ProgressString = 'Status - Running: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2	
						Break
					}
					"COMPLETED" {
						$EtlOutputKey = $ETLProgress.detail
						$CurrentOperation = 'ETL Processing Complete'
						$Status = 'Creating Import Batches'
						$Completed = $true
						$SleepSeconds = 0
						$PercentComplete = 99
						$ProgressString = "Status - ETL Processing Complete, Creating Import Batches."
						Break
					}
					"Failed" {
						$CurrentOperation = 'Failed'
						$Status = $ETLProgress.status
						Write-Host "ETL Processing Failed "$ETLProgress.detail
						Throw $ETLProgress.detail
					}
					Default { 
						$CurrentOperation = 'State Unknown'
						$Status = 'Unknown.  Sleeping to try again.'
						$ProgressString = "Unknown Status: " + $ETLProgress.status
						$PercentComplete = 99
						$SleepSeconds = 2
						Break
					}
				}
				
				## Notify the user of the ETL Progress
				if ($ActivityId) { 
					Write-Progress -Id ($ActivityId + 1) `
						-ParentId $ActivityId `
						-Activity 'ETL Data Transformation' `
						-CurrentOperation $CurrentOperation `
						-Status $Status `
						-PercentComplete $PercentComplete
				} else {
					Write-Host $ProgressString
				}
				Start-Sleep -Seconds $SleepSeconds
			}	
		}	
	}

	## Update Progress and transition to Activity + 2
	Write-Progress -Id ($ActivityId + 1) -ParentId $ActivityId -Activity 'ETL Data Transformation' -CurrentOperation 'Transformation Complete' -PercentComplete 100 -Completed
	Write-Progress -Id ($ActivityId + 2) -ParentId $ActivityId -Activity 'Importing Batches' -CurrentOperation 'Beginning Import' -PercentComplete 5

	## With the ETL converted, Use it to create Import Batches
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/assetImport/loadData?filename="
	$uri += $EtlOutputKey
	$uri += "&dataScriptId="
	$uri += $ETLScript.id
							
	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
							
	## Post the Transformed data filename to the ETL engine to Import the Batches.
	$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	if ($response.StatusCode -eq 200) {
		$responseContent = $response.Content | ConvertFrom-Json
		if ($responseContent.status -eq "success") {
			$ImportJob = $responseContent.data
			$ETLProgressKey = $ImportJob.progressKey
		} else {
			throw 'Failed to Load Import Batch'
		}
	} else {
		Throw 'Failed to Load Import Batch.'
	}
	

	## Ensure the Batches loaded and the job is finished
	## The ETL is underway, Setup a progress URL
	$uri = "https://"
	$uri += $instance
	$uri += "/tdstm/ws/progress/" + $ETLProgressKey
	Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
				
	## Poll for the status of the ETL engine
	## TODO: This should be converted to a function for polling the job engine.  It's nearly dupilcated now in the Import Batch watching.
	$Completed = $false
	while ($Completed -eq $false) {
			
		## Post the data starting the ETL process.  A progress key is provided.  This progress key is what can be used to poll for the status of the ETL script
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				$ETLProgress = $responseContent.data
									
				switch ($ETLProgress.status) {
					"Queued" { 
						$CurrentOperation = 'Loading Batches Queued'
						$Status = 'Queued'
						$ProgressString = 'Status - Queued: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2	
						Break
					}
					"Pending" { 
						$CurrentOperation = 'Loading Batches Pending'
						$Status = 'Pending Batch Loading'
						$ProgressString = 'Status - Pending: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2
						Break
					}
					"RUNNING" { 
						$CurrentOperation = 'Loading Batches'
						$Status = 'Loading Batches'
						$ProgressString = 'Status - Running: ' + $ETLProgress.percentComp + '%'
						$PercentComplete = $ETLProgress.percentComp	
						$SleepSeconds = 2
						Break
					}
					"COMPLETED" {
						$BatchGroupGuid = $ETLProgress.data.groupGuid
						$CurrentOperation = 'Batch Loading Complete'
						$Status = 'Loaded Import Batches'
						$Completed = $true
						$SleepSeconds = 0
						$PercentComplete = 99
						$ProgressString = "Status - Completed Loading Import Batches."
						Break
					}
					"Failed" {
						$CurrentOperation = 'Failed'
						$Status = $ETLProgress.status
						Write-Host "Batch Loading Processing Failed "$ETLProgress.detail
						Throw $ETLProgress.detail
					}
					Default { 
						$CurrentOperation = 'State Unknown'
						$Status = 'Unknown.  Sleeping to try again.'
						$ProgressString = "Unknown Status: " + $ETLProgress.status
						$PercentComplete = 99
						$SleepSeconds = 2
						Break
					}
				}
				
				## Notify the user of the ETL Progress
				if ($ActivityId) { 
					$ProgressOptions = @{
						Id               = ($ActivityId + 2)
						ParentId         = $ActivityId
						Activity         = 'Import Batch Loading'
						CurrentOperation = $CurrentOperation
						Status           = $Status
						PercentComplete  = $PercentComplete
					}
					if ($Completed) {
						Write-Progress @ProgressOptions -Completed
					} else {
						Write-Progress @ProgressOptions
					}
				} else {
					Write-Host $ProgressString
				}
				Start-Sleep -Seconds $SleepSeconds
			}	
		}	
	}

	## Update Progress and transition to Activity + 3
	Write-Progress -Id ($ActivityId + 2) -ParentId $ActivityId -Activity 'Batches Imported' -CurrentOperation 'Importing Batches Complete' -PercentComplete 100 -Completed
	Write-Progress -Id ($ActivityId + 3) -ParentId $ActivityId -Activity 'Monitoring Batches' -CurrentOperation 'Monitoring Batches' -PercentComplete 5

	## OPTIONAL - If the switch was set to Queue the batches
	if ($QueueBatches) {
		
		## Assemble the batch list object.  Dependencies are deliberately moved to the end
		$BatchesToProcess = [System.Collections.ArrayList]@()


		## Get the Batches that were created during the import
		## With the ETL converted, Use it to create Import Batches
		$uri = "https://"
		$uri += $instance
		$uri += "/tdstm/ws/import/batches?groupGuid="
		$uri += $BatchGroupGuid
								
		Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
								
		## Post the Transformed data filename to the ETL engine to Import the Batches.
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				$Batches = $responseContent.data	
			} else {

			}
		} else {

		}

		## Separate Asset batches from dependency Batches
		$Batches | Where-Object { $_.domainClass -ne 'Dependency' } | ForEach-Object { $BatchesToProcess.Add($_) | Out-Null }
		$Batches | Where-Object { $_.domainClass -eq 'Dependency' } | ForEach-Object { $BatchesToProcess.Add($_) | Out-Null }
	
		## Write Progress to the Monitor Import Batches 
		if ($ActivityId) { 
			Write-Progress -Id ($ActivityId + 3) `
				-ParentId $ActivityId `
				-Activity 'Manage Batches' `
				-CurrentOperation 'Queueing Batches' `
				-Status ('Queueing ' + [string]$Batches.Length + ' batches.') `
				-PercentComplete 5
		} else {
			Write-Host "Queueing Batches:" $Batches.Length
		}

		## Add a Progress Activity for each of the Import Batches
		for ($i = 0; $i -lt $BatchesToProcess.Count; $i++) {
			
			## Set Variable for Batch
			$Batch = $BatchesToProcess[$i]

			## Create Progress Results for the batches that were created
			if ($ActivityId) { 
			
				## Activity Explained: The $ActivityId is considered the (Root) + 2 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
				Write-Progress -Id ($ActivityId + 3 + $i + 1) `
					-ParentId ($ActivityId + 3) `
					-Activity ($Batch.domainClassName + ' batch: ' + $Batch.id + ' | Total: ' + $Batch.recordsSummary.count) `
					-CurrentOperation 'Queueing Batch' `
					-Status ([String]$Batch.recordsSummary.count + ' ' + $Batch.domainClassName + ' records created.') `
					-PercentComplete 10
			} else {
				Write-Host "Batch Created: " [String]$Batch.recordsSummary.count $Batch.domainClassName 'records created.'
			}
		}

		## Queue each Batch
		for ($i = 0; $i -lt $BatchesToProcess.Count; $i++) {
			
			## Set Variable for Batch
			$Batch = $BatchesToProcess[$i]
			if ($Batch.autoProcess -eq 0) {

				## With the file uploaded, Initiate the ETL script on the server
				$uri = "https://"
				$uri += $instance
				$uri += "/tdstm/ws/import/batches"
								
				Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
			
				$PostBody = @{ 
					action = 'QUEUE'
					ids    = $Batch.id
				} | ConvertTo-Json -Depth 100


				## Post this batch to begin it's Queueing
				$response = Invoke-WebRequest -Method Patch -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
				if ($response.StatusCode -eq 200) {
					$responseContent = $response.Content | ConvertFrom-Json
					if ($responseContent.status -eq "success") {
						
						## Create Progress Results for the batches that were created
						if ($ActivityId) { 
							
							## Notify the Manage Batches Activity of a queued batch
							Write-Progress -Id ($ActivityId + 3) `
								-ParentId $ActivityId `
								-Activity 'Monitor Batches' `
								-CurrentOperation 'Queueing Batches' `
								-Status ('Queued ' + $Batch.domainClass + ' Batch') `
								-PercentComplete 5

							## Activity (Root) + 2 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
							Write-Progress -Id ($ActivityId + 3 + $i + 1) `
								-ParentId ($ActivityId + 3) `
								-Activity ($Batch.domainClassName + ' batch: ' + $Batch.id + ' | Total: ' + $Batch.recordsSummary.count) `
								-CurrentOperation 'Batch Queued'  `
								-Status 'Queued' `
								-PercentComplete 0
						} else {
							Write-Host "Batch Queued:" $Batch.domainClass
						}
					} else {
						Throw 'Failed to Queue Batch'
					}	
				} else {
					Throw 'Failed to Queue Batch.'
				}
			}
		}

		## If Monitoring isn't going to occur, status should be complete here
		if ($MonitorBatches -ne $true) {
			Write-Progress -Id ($ActivityId + 3) -ParentId $ActivityId -Activity 'Batches Queued' -CurrentOperation 'Batches have been queued' -PercentComplete 100 -Completed
		}
	}

	## Allow the batch to be monitored and reported on in the UI
	if ($MonitorBatches) {
		$BatchStatus = @{
			CompletedBatches = 0
			TotalBatches     = $BatchesToProcess.Count
		}
		
		## Monitor the batches to completion
		for ($i = 0; $i -lt $BatchesToProcess.Count; $i++) {
			
			## Set Variable for Batch
			$Batch = $BatchesToProcess[$i]
			if ($Batch.recordsSummary.count -gt 0) {
				## Build the URL
				$uri = "https://"
				$uri += $instance
				$uri += "/tdstm/ws/import/batch/"
				$uri += $Batch.id
				$uri += "/progress"
									
				Set-TMHeaderContentType -ContentType JSON -TMSession $TMSession
				
				## Poll for the status of the Import Batch
				if ($ActivityId) { 
					
					## Activity (Root) + 3 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
					Write-Progress -Id ($ActivityId + 3 + $i + 1) `
						-ParentId ($ActivityId + 3) `
						-Activity ($Batch.domainClassName + ' batch: ' + $Batch.id + ' | Total: ' + $Batch.recordsSummary.count) `
						-CurrentOperation 'Monitoring Progress'  `
						-Status 'Importing' `
						-PercentComplete 1
				} else {
					Write-Host 'Getting Status for '$Batch.domainClassName
				}

				## Start a loop to run while the batch is not complete.
				$Completed = $false
				while ($Completed -eq $false) {
					
					## Post the data starting the ETL process.  A progress key is provided.  This progress key is what can be used to poll for the status of the ETL script
					$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
					if ($response.StatusCode -eq 200) {
						$responseContent = $response.Content | ConvertFrom-Json
						if ($responseContent.status -eq "success") {
							
							$BatchProgress = $responseContent.data
							
							switch ($BatchProgress.status.code) {
								"RUNNING" { 
									$CurrentOperation = 'Import Running'
									$Status = 'Importing Batch Data'
									$ProgressString = $DomainClass + ' Status: Running - ' + $BatchProgress.progress + "%"
									$PercentComplete = $BatchProgress.progress	
									$SleepSeconds = 2
									break
								}
								"QUEUED" { 
									$CurrentOperation = 'Batch Queued'
									$Status = 'Batch Queued'
									$ProgressString = $DomainClass + ' Status: Queued'
									$PercentComplete = $BatchProgress.progress	
									$SleepSeconds = 2	
									break
									
								}
								"PENDING" { 
									$CurrentOperation = 'Batch Pending'
									$Status = 'Batch Pending'
									$ProgressString = $DomainClass + ' Status: Pending'
									$PercentComplete = $BatchProgress.progress	
									$SleepSeconds = 2
									break
									
								}
								"COMPLETED" {
									$Completed = $true
									$CurrentOperation = 'Complete'
									$Status = 'Complete'
									$ProgressString = ($batch.domainClassName + " Status: Complete")
									$PercentComplete = 100
									$SleepSeconds = 0
									break
									
								}
								Default { 
									$CurrentOperation = 'Status Unknown.  Retrying'
									$Status = 'Retrying'
									$ProgressString = ($batch.domainClassName + "Status Unkown. Retrying")
									$PercentComplete = 1	
									$SleepSeconds = 2	
									break
								}
							}
							
							## Display the Status of this loop
							if ($ActivityId) { 
					
								$ProgressOptions = @{
									Id               = ($ActivityId + 3 + $i + 1)
									ParentId         = ($ActivityId + 3)
									Activity         = ($Batch.domainClassName + ' batch: ' + $Batch.id + ' | Total: ' + $Batch.recordsSummary.count)
									CurrentOperation = $CurrentOperation
									Status           = $Status
									PercentComplete  = $PercentComplete
								}
								## Activity (Root) + 3 (to move to Monitoring Batches) + I for the looping + 1 to add a new layer
								if ($Completed) { 
									Write-Progress @ProgressOptions -Completed
								} else {
									Write-Progress @ProgressOptions
								}

							} else {
								Write-Host $ProgressString
							}
							
							## TMD client now handles all progress percentage roll up when Parent id is specified. This is no longer necessary.
							## Calcuate Percentage for Manage Batches progress bar.  This is based on how many batches there are, how many are done and what percentage we have in this loop
							# $ManageBatchesPercentage = ((($BatchStatus.CompletedBatches * 100) + $PercentComplete) / ($BatchStatus.TotalBatches * 100))
							
							# Write-Progress -Id ($ActivityId + 3) `
							# 	-ParentId $ActivityId `
							# 	-Activity 'Manage Batches' `
							# 	-CurrentOperation 'Monitoring Progress'  `
							# 	-Status 'Processing' `
							# 	-PercentComplete $ManageBatchesPercentage
							
							## Increate how many jobs are marked as completed
							Start-Sleep -Seconds $SleepSeconds
						}	
					}
				}
			}
			## Now that this batch is done, increment the Completed Batches counter
			$BatchStatus.CompletedBatches++
		}

		## Mark the Manage Batches Activity Complete
		if ($ActivityId) {
			Write-Progress -Id ($ActivityId + 3) `
				-ParentId $ActivityId `
				-Activity 'Batches Posted' `
				-CurrentOperation 'Complete'  `
				-Status 'All Batches Imported' `
				-PercentComplete 100 `
				-Completed
		}
	}


	## Mark the TM Import Activity complete
	if ($ActivityId) {
		Write-Progress -Id $ActivityId `
			-ParentId $ParentActivityId `
			-Activity 'TransitionManager Data Import' `
			-CurrentOperation 'Complete'  `
			-Status 'All Data Imported' `
			-PercentComplete 100 `
			-Complete
	}
}

Function Read-TMETLScriptFile {
	param(
		[Parameter(Mandatory = $true)]$Path
	)

	
	## Name the Input File
	$Content = Get-Content -Path $Path -Raw

	## Ignore Empty Files
	if(-Not $Content){
		return 
	}
	
	$ContentLines = Get-Content -Path $Path

	## Create Automation Token Variables Parse the Script File
	New-Variable astTokens -Force
	New-Variable astErr -Force
	$ast = [System.Management.Automation.Language.Parser]::ParseInput($Content, [ref]$astTokens, [ref]$astErr)

	## 
	## Assess the Script Parts to get delineating line numbers
	## 
	
	## Locate the Delimiting line
	$ConfigBlockStartLine = $astTokens | `
		Where-Object { $_.Text -like '/*********TransitionManager-ETL-Script*********' } |`
		Select-Object -First 1 | `
		Select-Object -ExpandProperty Extent | `
		Select-Object -ExpandProperty StartLineNumber
	
	## Test if the file has been written with MetaData
	if (-Not $ConfigBlockStartLine) {

		## This file does not have metadata.  Create the minimum data for the constructor below
		$EtlScriptConfig = @{
			EtlScriptName =  (Get-Item -Path $Path).BaseName
			Description = ""
			ProviderName = (Get-Item -Path $Path).Directory.Parent.Parent.BaseName
			Target = ''

		}

		## Add Variables that will be used in the construction
		$EtlScriptCode = $ContentLines


		$TMEtlScript = [pscustomobject]@{
		
			## Primary Information
			id                     = $null
			name                   = $EtlScriptConfig.EtlScriptName
			description            = $EtlScriptConfig.Description
			
			## Source Code
			etlSourceCode          = $EtlScriptCode
			
			## Provider
			provider               = @{
				id   = $Provider.id
				name = $EtlScriptConfig.ProviderName
			}
			
			## Configuration Settings from the JSON configuration
			# target = $Null
			# mode = $Null
			# isAutoProcess = $Null
			# useWithAssetActions = $Null
			
			## Other details for the ETL Script
			dateCreated            = Get-Date
			lastUpdated            = Get-Date
			sampleFilename         = ""
			originalSampleFilename = ""
		}


	} else {

		## This File has metadata - Work to parse it

		$ConfigBlockEndLine = $astTokens | `
			Where-Object { $_.Text -like '*********TransitionManager-ETL-Script*********/' } |`
			Select-Object -First 1 | `
			Select-Object -ExpandProperty Extent | `
			Select-Object -ExpandProperty StartLineNumber
	
		## Adjust the Line Numbers to capture just the JSON
		$JsonConfigBlockStartLine = $ConfigBlockStartLine + 1
		$JsonConfigBlockEndLine = $ConfigBlockEndLine - 1
	

		## 
		## Read the Script Header to gather the configurations
		## 

		## Get all of the lines in the header comment
		$EtlConfigJson = $JsonConfigBlockStartLine..$JSONConfigBlockEndLine | ForEach-Object {
        
			## Return the line for collection
			$ContentLines[$_ - 1]

		} | Out-String
    
		## Convert the JSON string to an Object
		$EtlScriptConfig = $EtlConfigJson | ConvertFrom-Json
    
		## 
		## Read the Script Block
		## 

		## Note where the Configuration Code is located
		$StartCodeBlockLine = $ConfigBlockEndLine + 1
		$EndCodeBlockLine = $ast[-1].Extent.EndLineNumber

		## Create a Text StrinBuilder to collect the Script into
		$ETLScriptStringBuilder = New-Object System.Text.StringBuilder

		## For each line in the Code Block, add it to the Etl Script Code StringBuilder
		$StartCodeBlockLine..$EndCodeBlockLine | ForEach-Object {
			$EtlScriptStringBuilder.AppendLine($ContentLines[$_]) | Out-Null
		}

		## Convert the StringBuilder to a Multi-Line String
		$EtlScriptCode = $EtlScriptStringBuilder.ToString()
	
		## Get the Provider ID for the Script
		# $Provider = Get-TMProvider -Name $EtlScriptConfig.ProviderName

	}

	## Assemble the Action Object
	$TMEtlScript = [pscustomobject]@{
		
		## Primary Information
		id                     = $null
		name                   = $EtlScriptConfig.EtlScriptName
		description            = $EtlScriptConfig.Description
        
		## Source Code
		etlSourceCode          = $EtlScriptCode
        
		## Provider
		provider               = @{
			id   = $Provider.id
			name = $EtlScriptConfig.ProviderName
		}
		
		## Configuration Settings from the JSON configuration
		# target                 = $EtlScriptConfig.Target
		# mode                   = $EtlScriptConfig.Mode
		# isAutoProcess          = $EtlScriptConfig.isAutoProcess
		# useWithAssetActions    = $EtlScriptConfig.useWithAssetActions
		
		## Other details for the ETL Script
		dateCreated            = Get-Date
		lastUpdated            = Get-Date
		# sampleFilename         = ""
		# originalSampleFilename = ""
	}
	
	## Return the Action Object
	return $TMEtlScript

}