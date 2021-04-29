

# Reference Designs
# Function New-TMAction {
# 	param(
# 		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
# 		[Parameter(Mandatory = $true)][PSObject]$Action,
# 		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
# 		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
# 		[Parameter(Mandatory = $false)][PSObject]$Project,
# 		[Parameter(Mandatory = $false)][Switch]$Update,
# 		[Parameter(Mandatory = $false)][Switch]$Passthru
# 	)
	
# 	# ## Use the TM Session provided
# 	# $Global:TMSessions[$TMSession]
# 	# switch ($TMSes) {
# 	# 	condition {  }
# 	# 	Default {}
# 	# }
# 	# if ($global:TMSessions[$TMSession].TMVersion -eq '4.7.2') {
# 	# 	New-TMAction472 @PSBoundParameters

# 	# } else
# 	if ($global:TMSessions[$TMSession].TMVersion -like '4.7*') {
# 		New-TMAction474 @PSBoundParameters

# 	} else {
# 		New-TMAction46 @PSBoundParameters
# 	}
# }
# Function New-TMAction46 {
# 	param(
# 		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
# 		[Parameter(Mandatory = $true)][PSObject]$Action,
# 		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
# 		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
# 		[Parameter(Mandatory = $false)][PSObject]$Project,
# 		[Parameter(Mandatory = $false)][Switch]$Passthru

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

# 	## Check for existing Action 
# 	$ActionCheck = Get-TMAction -Name $Action.name -TMSession $TMSession
# 	if ($ActionCheck) {
# 		if ($Passthru) {
# 			return $ActionCheck
# 		} else {
# 			return
# 		}
# 	} else {
# 		## No Credential exists.  Create it
# 		$instance = $Server.Replace('/tdstm', '')
# 		$instance = $instance.Replace('https://', '')
# 		$instance = $instance.Replace('http://', '')
	
# 		$uri = "https://"
# 		$uri += $instance
# 		$uri += '/tdstm/ws/apiAction'
		
# 		## Lookup Cross References
# 		if (-not $Project) {
# 			$Project = $Projects | Where-Object { $_.name -eq $Action.project.name }
# 		}
# 		$ProjectID = $Project.id
		
# 		$ProviderID = (Get-TMProvider -TMSession $TMSession | Where-Object { $_.name -eq $Action.provider.name }).id
# 		$CredentialID = (Get-TMCredential -TMSession $TMSession | Where-Object { $_.name -eq $Action.credential.name }).id

# 		## Fix up the object
# 		$Action.PSObject.properties.Remove('id')
# 		$Action.actionType = $Action.actionType.id
# 		$Action.project.id = $ProjectID
# 		$Action.provider.id = $ProviderID
# 		$Action.credential.id = $CredentialID
# 		$Action.version = 1
# 		$PostBodyJSON = $Action | ConvertTo-Json -Depth 100

# 		Set-TMHeaderAccept "JSON" -TMSession $TMSession
# 		Set-TMHeaderContentType "JSON" -TMSession $TMSession
# 		try {
# 			$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
# 			if ($response.StatusCode -eq 200) {
# 				$responseContent = $response.Content | ConvertFrom-Json
# 				if ($responseContent.status -eq "success") {
# 					if ($Passthru) {
# 						return $responseContent.data
# 					} else {
# 						return
# 					}
# 				}	
# 			}
# 		} catch {
# 			Write-Host "Unable to create Action."
# 			return $_
# 		}
# 	}
	
# }
# Function New-TMAction472 {
# 	param(
# 		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
# 		[Parameter(Mandatory = $true)][PSObject]$Action,
# 		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
# 		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
# 		[Parameter(Mandatory = $false)][PSObject]$Project,
# 		[Parameter(Mandatory = $false)][Switch]$Passthru
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

# 	## Check for existing Action 
# 	$ActionCheck = Get-TMAction -Name $Action.name -TMSession $TMSession
# 	if ($ActionCheck) {
# 		if ($Passthru) {
# 			return $ActionCheck
# 		} else {
# 			return
# 		}
# 	} else {
# 		## No Credential exists.  Create it
# 		$instance = $Server.Replace('/tdstm', '')
# 		$instance = $instance.Replace('https://', '')
# 		$instance = $instance.Replace('http://', '')
	
# 		$uri = "https://"
# 		$uri += $instance
# 		$uri += '/tdstm/ws/apiAction'
		
# 		## Lookup Provider and Credential IDs
# 		$ProviderID = (Get-TMProvider -TMSession $TMSession | Where-Object { $_.name -eq $Action.provider.name }).id
# 		$CredentialID = (Get-TMCredential -TMSession $TMSession | Where-Object { $_.name -eq $Action.credential.name }).id

# 		## Fix up the object
# 		$Action.PSObject.properties.Remove('id')
# 		# $Action.actionType = $Action.actionType.id
# 		# $Action.project.id = $ProjectID
# 		$Action.provider.id = $ProviderID
# 		$Action.credential.id = $CredentialID
# 		$Action.version = 1
# 		$PostBodyJSON = $Action | ConvertTo-Json -Depth 100

# 		Set-TMHeaderAccept "JSON" -TMSession $TMSession
# 		Set-TMHeaderContentType "JSON" -TMSession $TMSession
# 		try {
# 			$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
# 			if ($response.StatusCode -eq 200) {
# 				$responseContent = $response.Content | ConvertFrom-Json
# 				if ($responseContent.status -eq "success") {
# 					if ($Passthru) {
# 						return $responseContent.data
# 					} else {
# 						return
# 					}
# 				}	
# 			}
# 		} catch {
# 			Write-Host "Unable to create Action."
# 			return $_
# 		}
# 	}
	
# }
# Function New-TMAction474 {
# 	param(
# 		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
# 		[Parameter(Mandatory = $true)][PSObject]$Action,
# 		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
# 		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
# 		[Parameter(Mandatory = $false)][PSObject]$Project,
# 		[Parameter(Mandatory = $false)][Switch]$Update,
# 		[Parameter(Mandatory = $false)][Switch]$Passthru
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

# 	## Check for existing Action 
# 	$ActionCheck = Get-TMAction -Name $Action.name -TMSession $TMSession
# 	if ($ActionCheck -and -not $Update) {
# 		if ($PassThru) {
# 			return $ActionCheck
# 		} else {
# 			return
# 		}
# 	} else {
		
# 		## If The Existing action should be updated 
# 		if ($ActionCheck -and $Update) {
# 			$Action.id = $ActionCheck.id
# 		} else {
# 			$Action.PSObject.Properties.Remove('id')
# 		}
		
# 		## No Credential exists.  Create it
# 		$instance = $Server.Replace('/tdstm', '')
# 		$instance = $instance.Replace('https://', '')
# 		$instance = $instance.Replace('http://', '')
	
# 		$uri = "https://"
# 		$uri += $instance
# 		$uri += '/tdstm/ws/apiAction'
		
# 		## Lookup Provider and Credential IDs, Field Specs
# 		$ProviderID = (Get-TMProvider -Name $Action.provider.name -TMSession $TMSession).id
# 		$CredentialID = (Get-TMCredential -Name $Action.credential.name -TMSession $TMSession ).id
# 		$FieldSettings = Get-TMFieldSpecs -TMSession $TMSession

# 		## Fix up the object
# 		if ($CredentialID) { $Action.credential.id = $CredentialID }
# 		$Action.provider.id = $ProviderID
# 		$Action.version = 1

# 		## Fix the Parameters to the correct custom field name
# 		if ($Action.methodParams) {
# 			$Parameters = $Action.methodParams | ConvertFrom-Json
# 			for ($j = 0; $j -lt $Parameters.Count; $j++) {
# 				if ($Parameters[$j].context -in @('DEVICE', 'APPLICATION', 'STORAGE', 'DATABASE')) {

# 					## Check if a fieldLabel param exists in the Parameters[$j].  
# 					## This is added by the New-TMIntegrationPlugin command so the correct
# 					## Custom fields can be assigned when the new Action is installed.
# 					if ($Parameters[$j].PSobject.Properties.name -match 'fieldLabel') {

# 						## Update the Project's assigned Field by associating the label to the current field list.
# 						$Parameters[$j].fieldName = ($FieldSettings.($Parameters[$j].context).fields | Where-Object { $_.label -eq $Parameters[$j].fieldLabel }).field

# 						## Remove the 'fieldLabel property as it's invalid column definition
# 						$Parameters[$j].PSObject.Properties.Remove('fieldLabel')
# 					}
# 				}
# 			}
# 			$Action.methodParams = ($Parameters | ConvertTo-Json -Depth 100 -Compress ).toString()
# 		}

# 		$PostBodyJSON = $Action | ConvertTo-Json -Depth 100

# 		Set-TMHeaderAccept "JSON" -TMSession $TMSession
# 		Set-TMHeaderContentType "JSON" -TMSession $TMSession
# 		try {
# 			$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
# 			if ($response.StatusCode -eq 200) {
# 				$responseContent = $response.Content | ConvertFrom-Json
# 				if ($responseContent.status -eq "success") {
# 					if ($PassThru) {
# 						return $responseContent.data
# 					}
# 				}	
# 			}
# 		} catch {
# 			Write-Host "Unable to create Action."
# 			return $_
# 		}
# 	}
	
# }
# Function Get-TMAction {
# 	param(
# 		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
# 		[Parameter(Mandatory = $false)][String]$Name,
# 		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
# 		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
# 		[Parameter(Mandatory = $false)][Switch]$ResetIDs,
# 		[Parameter(Mandatory = $false)][String]$SaveCodePath,
# 		[Parameter(Mandatory = $false)][Switch]$Passthru
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

# 	$instance = $Server.Replace('/tdstm', '')
# 	$instance = $instance.Replace('https://', '')
# 	$instance = $instance.Replace('http://', '')
	
# 	$uri = "https://"
# 	$uri += $instance
# 	$uri += '/tdstm/ws/apiAction'
	
# 	try {
# 		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
# 	} catch {
# 		return $_
# 	}

# 	if ($response.StatusCode -eq 200) {
# 		$Result = ($response.Content | ConvertFrom-Json).data
# 	} else {
# 		return "Unable to collect Actions."
# 	}

# 	if ($ResetIDs) {
		
# 		## Get the Field Settings - This is required when IDs are reset so the label can be added to the output.
# 		$FieldSettings = Get-TMFieldSpecs -TMSession $TMSession

# 		## Clear pertinent data in each Action
# 		for ($i = 0; $i -lt $Result.Count; $i++) {
# 			$Result[$i].id = $null
# 			$Result[$i].project.id = $null
# 			if ($Result[$i].credential) { $Result[$i].credential.id = $null }
# 			$Result[$i].provider.id = $null

# 			## Fix the Parameters to the correct custom field name
# 			if ($Result[$i].methodParams) {
# 				$Parameters = $Result[$i].methodParams | ConvertFrom-Json
# 				for ($j = 0; $j -lt $Parameters.Count; $j++) {
# 					if ($Parameters[$j].context -in @('DEVICE', 'APPLICATION', 'STORAGE', 'DATABASE')) {
						
# 						## The custom column field identifer is lost when the IDs get reset.  Add a fieldLabel node to put the custom field label.  This will get replaced/updated by the Import
# 						$FieldLabel = ($FieldSettings.($Parameters[$j].context).fields | Where-Object { 
# 								$_.field -eq $Parameters[$j].fieldName 
# 							}).label
# 						$Parameters[$j] | Add-Member -NotePropertyName 'fieldLabel' -NotePropertyValue $FieldLabel
# 						$Parameters[$j].fieldName = $null
# 					}
# 				}
# 				$Result[$i].methodParams = ($Parameters | ConvertTo-Json -Depth 100 -Compress ).toString()
# 			}
# 		}
# 	}

	

# 	## Return the details
# 	if ($Name) {
# 		$SingleResult = $Result | Where-Object { $_.name -eq $Name }
# 		## Save the Code Files to a folder
# 		if ($SaveCodePath) {
# 			## Confirm the folder exists, create if not
# 			Test-FolderPath -FolderPath $SaveCodePath


# 			$Script = [ScriptBlock]::Create($SingleResult.script)
			
# 			Set-Content -Path (Join-Path $SaveCodePath ($SingleResult.name + '.ps1')) -Value $SingleResult.script -Force
# 		}
		
# 		## Set the Return Value (for Passthru)
# 		$Result = $SingleResult
		
# 	} else {
# 		## Save the Code Files to a folder
# 		if ($SaveCodePath) {
			
# 			## Confirm the folder exists, create if not
# 			Test-FolderPath -FolderPath $SaveCodePath
			
# 			## Save Each of the Script Source Data
# 			foreach ($Item in $Result) {
				
# 				## ScriptFile File Path for the Script Resource
# 				$FileName = ($Item.name -replace '\\', '-' -replace '\/', '-' -replace ':', '-') + '.ps1'
# 				$ProviderFolderName = $Item.provider.name -replace '\\', '-' -replace '\/', '-' 
# 				$ScriptFile = Join-Path $SaveCodePath $ProviderFolderName $FileName

# 				## Confirm the folder exists, create if not
# 				Test-FolderPath -FolderPath (Join-Path $SaveCodePath $ProviderFolderName)

# 				## Collect the Script into a Script Block
# 				$Script = [ScriptBlock]::Create($Item.script)
# 				## Remove the Script to create the rest of the ActionConfig Object
# 				# $Item.PSObject.Properties.Remove('script') 
# 				$ItemName = $Item.name

# 				## Build a config of the important References
# 				$TMConfig = [PSCustomObject]@{
# 					ActionName   = $Item.name
# 					ProviderName = $Item.provider.name
# 					Credential   = $Item.credential
# 				} | ConvertTo-Json | Out-String

# 				## Collect the Parameters
# 				if ($item.methodParams) {
					
# 					## Get the JSON Params and print them as an array of Hashtables
# 					$Parameters = $item.methodParams | ConvertFrom-Json | ConvertTo-Json | Out-String
# 				}

# 				## Create a Script String output
# 				$ScriptOutput = [System.Text.StringBuilder]::new()
# 				$ScriptOutput.AppendLine("<####### TransitionManager Action Script ######") | Out-Null
# 				$ScriptOutput.AppendLine() | Out-Null
# 				$ScriptOutput.AppendLine("Script Name: $ItemName ") | Out-Null
# 				$ScriptOutput.AppendLine() | Out-Null
				
# 				$ScriptOutput.AppendLine("Action Configuration") | Out-Null
# 				$ScriptOutput.AppendLine($TMConfig) | Out-Null
# 				$ScriptOutput.AppendLine() | Out-Null
				
# 				$ScriptOutput.AppendLine("Action Parameters:")  | Out-Null
# 				$ScriptOutput.AppendLine($Parameters) | Out-Null
				
# 				$ScriptOutput.AppendLine('#>') | Out-Null
				
# 				$ScriptOutput.AppendLine() | Out-Null
# 				$ScriptOutput.AppendLine() | Out-Null
				
# 				## Write the Script to the Configuration
# 				$ScriptOutput.AppendLine($Script) | Out-Null
# 				$ScriptOutput.AppendLine() | Out-Null

# 				## Start Writing the Content of the Script (Force to overwrite any existing files)
# 				Set-Content -Path $ScriptFile -Force -Value $ScriptOutput.toString()
				
# 			}
# 		}
# 	}

# 	## Return Data if Passthru
# 	if ($Passthru) {

# 		return $Result
# 	}
# }


<#
 #  Get TM Reference Design 
	Collects Reference Design Details into a Reference Design object
 #>

Function Get-TMReferenceDesign {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][PSObject]$Project,
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
}
