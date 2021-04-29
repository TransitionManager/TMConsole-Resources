

# Actions
Function New-TMAction {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Action,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][PSObject]$Project,
		[Parameter(Mandatory = $false)][Switch]$Update,
		[Parameter(Mandatory = $false)][Switch]$Passthru
	)
	
	## Use the TM Session provided
	if ($global:TMSessions[$TMSession].TMVersion -like '4.6*') {
		New-TMAction46 @PSBoundParameters
		
	} else {
		New-TMAction474 @PSBoundParameters
	}
}
Function New-TMAction46 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Action,
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

	## Check for existing Action 
	$ActionCheck = Get-TMAction -Name $Action.name -TMSession $TMSession
	if ($ActionCheck) {
		if ($Passthru) {
			return $ActionCheck
		} else {
			return
		}
	} else {
		## No Credential exists.  Create it
		$instance = $Server.Replace('/tdstm', '')
		$instance = $instance.Replace('https://', '')
		$instance = $instance.Replace('http://', '')
	
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/apiAction'
		
		## Lookup Cross References
		if (-not $Project) {
			$Project = $Projects | Where-Object { $_.name -eq $Action.project.name }
		}
		$ProjectID = $Project.id
		
		$ProviderID = (Get-TMProvider -TMSession $TMSession | Where-Object { $_.name -eq $Action.provider.name }).id
		$CredentialID = (Get-TMCredential -TMSession $TMSession | Where-Object { $_.name -eq $Action.credential.name }).id

		## Fix up the object
		$Action.PSObject.properties.Remove('id')
		$Action.actionType = $Action.actionType.id
		$Action.project.id = $ProjectID
		$Action.provider.id = $ProviderID
		$Action.credential.id = $CredentialID
		$Action.version = 1
		$PostBodyJSON = $Action | ConvertTo-Json -Depth 100

		Set-TMHeaderAccept "JSON" -TMSession $TMSession
		Set-TMHeaderContentType "JSON" -TMSession $TMSession
		try {
			$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
			if ($response.StatusCode -eq 200) {
				$responseContent = $response.Content | ConvertFrom-Json
				if ($responseContent.status -eq "success") {
					if ($Passthru) {
						return $responseContent.data
					} else {
						return
					}
				}	
			}
		} catch {
			Write-Host "Unable to create Action."
			return $_
		}
	}	
}
Function New-TMAction474 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Action,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][PSObject]$Project,
		[Parameter(Mandatory = $false)][Switch]$Update,
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

	## Check for existing Action 
	$ActionCheck = Get-TMAction -Name $Action.name -TMSession $TMSession
	if ($ActionCheck -and -not $Update) {
		if ($PassThru) {
			return $ActionCheck
		} else {
			return
		}
	} else {
		
		
		## No Credential exists.  Create it
		$instance = $Server.Replace('/tdstm', '')
		$instance = $instance.Replace('https://', '')
		$instance = $instance.Replace('http://', '')
		
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/apiAction'
		
		## Cleans the Action Name of characters we don't want
		$Action.name = $Action.name -replace "\\", '' -replace "\/", '' -replace "\:", '' -replace ">", '' -replace "<", '' -replace '\(', '' -replace '\)', '' -replace '\*', ''
		# $Action.name = $SafeActionName

		## If The Existing action should be updated 
		if ($ActionCheck -and $Update) {
			
			## When the Action is an update, use important details from the current object.
			$Action.id = $ActionCheck.id
			$Action.dateCreated = $ActionCheck.dateCreated
			$Action.lastUpdated = $ActionCheck.lastUpdated
			$Action.debugEnabled = $ActionCheck.debugEnabled
			$Action.version = $ActionCheck.version
			$action.project = $ActionCheck.project
			

			## Set the HTTP call details
			$uri += '/' + $Action.id
			$HttpMethod = 'Put'
		} else {

			## Process as a new object.
			$HttpMethod = 'Post'
			$Action.PSObject.Properties.Remove('id')
		}

		## Lookup Provider and Credential IDs, Field Specs
		$ProviderID = (Get-TMProvider -Name $Action.provider.name -TMSession $TMSession).id
		$Action.provider.id = $ProviderID
		
		## If the Credential name is provided, look up the proper credential and add the ID
		if ($Action.credential.name) {
			$CredentialID = (Get-TMCredential -Name $Action.credential.name -TMSession $TMSession ).id
			if ($CredentialID) { $Action.credential.id = $CredentialID }
			$Action.remoteCredentialMethod = 'SUPPLIED'
		} else {
			$Action.credential = $null
			$Action.remoteCredentialMethod = 'USER_PRIV'
		}
		
		$FieldSettings = Get-TMFieldSpecs -TMSession $TMSession
		## Fix the Parameters to the correct custom field name
		if ($Action.methodParams) {
			$Parameters = $Action.methodParams | ConvertFrom-Json
			for ($j = 0; $j -lt $Parameters.Count; $j++) {
				if ($Parameters[$j].context -in @('DEVICE', 'APPLICATION', 'STORAGE', 'DATABASE')) {

					## Check if a fieldLabel param exists in the Parameters[$j].  
					## This is added by the New-TMIntegrationPlugin command so the correct
					## Custom fields can be assigned when the new Action is installed.
					if ($Parameters[$j].PSobject.Properties.name -match 'fieldLabel') {

						## Update the Project's assigned Field by associating the label to the current field list.
						$Parameters[$j].fieldName = ($FieldSettings.($Parameters[$j].context).fields | Where-Object { $_.label -eq $Parameters[$j].fieldLabel }).field

						## Remove the 'fieldLabel property as it's invalid column definition
						$Parameters[$j].PSObject.Properties.Remove('fieldLabel')
					}
				}
			}
			$Action.methodParams = (ConvertTo-Array -InputObject $Parameters | ConvertTo-Json -Depth 100 -Compress ).toString()
		}

		$PostBodyJSON = $Action | ConvertTo-Json -Depth 100

		Set-TMHeaderAccept "JSON" -TMSession $TMSession
		Set-TMHeaderContentType "JSON" -TMSession $TMSession
		try {
			$response = Invoke-WebRequest -Method $HttpMethod -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBodyJSON @TMCertSettings
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
		} catch {
			Write-Host "Unable to create Action."
			return $_
		}
	}
	
}
Function Get-TMAction {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$ResetIDs,
		[Parameter(Mandatory = $false)][String]$SaveCodePath
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
	$uri += '/tdstm/ws/apiAction'
	
	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		throw $_
	}

	if ($response.StatusCode -in @(200, 204)) {
		$Result = ($response.Content | ConvertFrom-Json).data
	} else {
		throw "Unable to collect Actions."
	}

	if ($ResetIDs) {
		
		## Get the Field Settings - This is required when IDs are reset so the label can be added to the output.
		$FieldSettings = Get-TMFieldSpecs -TMSession $TMSession

		## Clear pertinent data in each Action
		for ($i = 0; $i -lt $Result.Count; $i++) {
			$Result[$i].id = $null
			$Result[$i].project.id = $null
			if ($Result[$i].credential) { $Result[$i].credential.id = $null }
			$Result[$i].provider.id = $null

			## Fix the Parameters to the correct custom field name
			if ($Result[$i].methodParams) {
				$Parameters = $Result[$i].methodParams | ConvertFrom-Json
				for ($j = 0; $j -lt $Parameters.Count; $j++) {
					if ($Parameters[$j].context -in @('DEVICE', 'APPLICATION', 'STORAGE', 'DATABASE')) {
						
						## The custom column field identifer is lost when the IDs get reset.  Add a fieldLabel node to put the custom field label.  This will get replaced/updated by the Import
						$FieldLabel = ($FieldSettings.($Parameters[$j].context).fields | Where-Object { 
								$_.field -eq $Parameters[$j].fieldName 
							}).label
						$Parameters[$j] | Add-Member -NotePropertyName 'fieldLabel' -NotePropertyValue $FieldLabel
						$Parameters[$j].fieldName = $null
					}
				}
				$Result[$i].methodParams = ($Parameters | ConvertTo-Json -Depth 100 -Compress ).toString()
			}
		}
	}

	

	## Return the details
	if ($Name) {
		$Result = $Result | Where-Object { $_.name -eq $Name }
		$Result = , @($Result)

	} 

	## Save the Code Files to a folder
	if ($SaveCodePath) {

		## Save Each of the Script Source Data
		foreach ($Item in $Result) {
				
			## Get a FileName safe version of the Provider Name
			$SafeProviderName = Get-FilenameSafeString $Item.provider.name
			$SafeActionName = Get-FilenameSafeString $Item.name
			
			## Create the Provider Action Folder path
			$ProviderPath = Join-Path $SaveCodePath  $SafeProviderName
			Test-FolderPath -FolderPath $ProviderPath
			
			## Create a File ame for the Action
			$ProviderScriptPath = Join-Path $ProviderPath  ($SafeActionName + '.ps1')

			## Collect the Script into a Script Block
			$Script = [ScriptBlock]::Create($Item.script)

			## Build a config of the important References
			$TMConfig = [PSCustomObject]@{
				ActionName   = $Item.name
				ProviderName = $Item.provider.name
				Credential   = $Item.credential.name
			} | ConvertTo-Json | Out-String

			## Collect the Parameters
			if ($Item.methodParams) {
					
				## Get the JSON Params and print them as an array of Hashtables
				$Parameters = $item.methodParams | ConvertFrom-Json
			}

			## Create a Script String output
			## Note - Indentations don't look correct here, but they produce good looking code.  Don't adjust.
			$ScriptOutput = [System.Text.StringBuilder]::new()
			$ScriptOutput.AppendLine("<####### TransitionManager Action Script ######") | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
			$ScriptOutput.AppendLine("	ActionName			= $SafeActionName ") | Out-Null
			$ScriptOutput.AppendLine("	ProviderName		= $SafeProviderName ") | Out-Null
			$ScriptOutput.AppendLine(("	CredentialName 		= " + $TMConfig.Credential)) | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
			$ScriptOutput.AppendLine(("	Description			= " + $Item.description )) | Out-Null
			$ScriptOutput.AppendLine('#>') | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
				
			## Only write a Parameters block if there is one.
			if ($Parameters) {

				## Open a Parameters Array
				$ScriptOutput.AppendLine("## Parameter Configuration")  | Out-Null
				$ScriptOutput.AppendLine('$Params = @{') | Out-Null
				
				for ($i = 0; $i -lt $Parameters.Count; $i++) {
					
					## Get the singular Param
					$Parameter = $Parameters[$i]
					$ParameterName = $Parameter.paramName -replace ' ', ''

					## Add Strings to the Parameter Name if it has any offending (non-word) characters 
					if ($ParameterName -match '\W') {
						$ParameterName = "'" + $ParameterName + "'"
					}

					## Add the Param Object Header
					$ScriptOutput.AppendLine(("	" + $ParameterName + " = @{")) | Out-Null
					# $ScriptOutput.AppendLine('	@{') | Out-Null
					
					## Write the param details that are always present
					$ScriptOutput.AppendLine(("		Description		= '" + $Parameter.desc + "'")) | Out-Null
					$ScriptOutput.AppendLine(("		Context			= '" + $Parameter.context + "'")) | Out-Null
					
					## Add Conditional Fields
					if ($Parameter.fieldLabel -ne '') {
						$ScriptOutput.AppendLine(("		FieldLabel		= '" + $Parameter.fieldLabel + "'")) | Out-Null

					}
					if ($Parameter.value -ne '') {
						$ScriptOutput.AppendLine(("		Value			= '" + $Parameter.value + "'")) | Out-Null

					}
					
					## Close the Parameter Object
					$ScriptOutput.AppendLine('	}') | Out-Null
				


				}

				## Close the Parameters Object
				$ScriptOutput.AppendLine('}') | Out-Null
			}
			
			## Write the Configuration Footer
			$ScriptOutput.AppendLine('## End of TM Configuration, Begin Script') | Out-Null
			
			$ScriptOutput.AppendLine() | Out-Null
				
			## Write the Script to the Configuration
			$ScriptOutput.AppendLine($Script) | Out-Null
			$ScriptOutput.AppendLine() | Out-Null

			## Start Writing the Content of the Script (Force to overwrite any existing files)
			Set-Content -Path $ProviderScriptPath -Force -Value $ScriptOutput.toString()

		}
	}
	
	## Saving the Code Path will skip outputing results
	if (-Not $SaveCodePath) {

		## Return a single value, or an Array
		if ($Result.Count -eq 1) {
			return $Result[0]
		} else {
			return $Result
		}
	} 
}

Function Read-TMActionScriptFile {
	param(
		[Parameter(Mandatory = $true)]$Path
	)

	
	## Name the Input File
	# $File = 'C:\Src\TDS\TM-Servers Git\tmddev.transitionmanager.net\Lab - TBW\Actions\TransitionManager\Devices - Get Windows System Info.ps1'
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
	$ConfigBlockEndLine = $astTokens | `
		Where-Object { $_.Text -like '## End of TM Configuration, Begin Script*' } |`
		Select-Object -First 1 | `
		Select-Object -ExpandProperty Extent | `
		Select-Object -ExpandProperty StartLineNumber

	## Test to see if the Script is formatted output with Metadata
	if (-not $ConfigBlockEndLine) {
	
		## There is no metadata, create the basic object with just the source code
		$ActionConfig = [pscustomobject]@{
			ActionName      = (Get-Item -Path $Path).BaseName
			Description     = ""

			
			script          = $ContentLines
			reactionScripts = '{"PRE":"","ERROR":"// Put the task on hold and add a comment with the cause of the error\n task.error( response.stderr )","FINAL":"","FAILED":"","LAPSED":"","STATUS":"// Check the HTTP response code for a 200 OK \n if (response.status == SC.OK) { \n \t return SUCCESS \n } else { \n \t return ERROR \n}","DEFAULT":"// Put the task on hold and add a comment with the cause of the error\n task.error( response.stderr )\n","STALLED":"","SUCCESS":"// Update Asset Fields\nif(response?.data?.assetUpdates){\n\tfor (field in response.data.assetUpdates) {\n   \t\tasset.\"${field.key}\" = field.value;\n\t}\n}\ntask.done()"}'
			
			ProviderName    = (Get-Item -Path $Path).Directory.BaseName
			
		}

		## Create the objects the below constructor expect
		$ActionScriptCode = $ContentLines
		$TMActionParams = [System.Collections.ArrayList] @() 
	
	} else {

		## 
		## Read the Script Header to gather the configurations
		## 

		## Get all of the lines in the header comment
		$TMConfigHeader = 0..$ConfigBlockEndLine | ForEach-Object {
        
			if ($astTokens[$_].kind -eq 'comment') { $astTokens[$_] }
		} | Select-Object -First 1 | Select-Object -ExpandProperty Text
    
		## Create a Properties object that will store the values listed in the header of the script file
		$ActionConfig = [PSCustomObject]@{
		}
    
		## Process each line of the Header string
		$TMConfigHeader -split "`n" | ForEach-Object {
        
			## Process each line of the comment
			if ($_ -like '*=*') {
				$k, $v = $_ -split '='
				$k = $k.Trim() -replace "'", '' -replace '"', ''
				$v = $v.Trim() -replace "'", '' -replace '"', ''
				$ActionConfig | Add-Member -NotePropertyName $k -NotePropertyValue $v     
			}
		}
    
		## 
		## Read the Script Block
		## 

		## Note where the Configuration Code is located
		$StartCodeBlockLine = $ConfigBlockEndLine + 1
		$EndCodeBlockLine = $ast[-1].Extent.EndLineNumber

		## Create a Text StrinBuilder to collect the Script into
		$ActionConfigStringBuilder = New-Object System.Text.StringBuilder

		## For each line in the Code Block, add it to the Action Script Code StringBuilder
		0..$ConfigBlockEndLine | ForEach-Object {
			$ActionConfigStringBuilder.AppendLine($ContentLines[$_]) | Out-Null
		}
		$ActionConfigScriptString = $ActionConfigStringBuilder.ToString()
		$ActionConfigScriptBlock = [scriptblock]::Create($ActionConfigScriptString)

		## Invoke the Script Block to create the $Params Object in this scope
		## this line populates the $Params object from the Action Script
		Invoke-Command -ScriptBlock $ActionConfigScriptBlock -NoNewScope

		## Note where the Action Code is located
		$StartCodeBlockLine = $ConfigBlockEndLine + 1
		$EndCodeBlockLine = $ast[-1].Extent.EndLineNumber

		## Create a Text StrinBuilder to collect the Script into
		$ActionScriptStringBuilder = New-Object System.Text.StringBuilder

		## For each line in the Code Block, add it to the Action Script Code StringBuilder
		$StartCodeBlockLine..$EndCodeBlockLine | ForEach-Object {
			$ActionScriptStringBuilder.AppendLine($ContentLines[$_]) | Out-Null
		}

		## Convert the StringBuilder to a Multi-Line String
		$ActionScriptCode = $ActionScriptStringBuilder.ToString()

		## Collect the Parameters
		$TMActionParams = [System.Collections.ArrayList] @()
		## Action Parameter Class Definition
		# {
		#     "desc": "",
		#     "type": "string",
		#     "value": "",
		#     "context": "DEVICE",
		#     "encoded": false,
		#     "readonly": false,
		#     "required": false,
		#     "fieldName": null,
		#     "paramName": "IPAddress",
		#     "fieldLabel": "IP Address"
		#   }
    
		## Process the Parameters into Action Params
		foreach ($ParamLabel in $Params.Keys) {
        
			## Create a new Params Object to load to the Action
			$NewParamConfig = [PSCustomObject]@{
				type       = 'string'
				value      = ''
				desc       = ''
				context    = ''
				fieldLabel = ''
				required   = $false
				encoded    = $false
				readonly   = $false
				fieldName  = $null
			}

			## Read the existing Params configuration, assembling each additional Paramater option
			$ScriptParamConfig = $Params.$ParamLabel
			$ScriptParamConfig.Keys | ForEach-Object {
				switch ($_.toLower()) {
					'value' { 
						$NewParamConfig.value = $ScriptParamConfig[$_]
						break
					}
					'type' { 
						$NewParamConfig.type = $ScriptParamConfig[$_]
						break
					}
					'description' { 
						$NewParamConfig.desc = $ScriptParamConfig[$_]
						break
					}
					'context' { 
						$NewParamConfig.context = $ScriptParamConfig[$_]
						break
					}
					'fieldlabel' { 
						$NewParamConfig.fieldLabel = $ScriptParamConfig[$_]
						break
					}
					'required' { 
						$NewParamConfig.required = (ConvertTo-Boolean $ScriptParamConfig[$_])
						break
					}
				}
			}

			## Add the Parameter Name from the Configuration Object
			Add-Member -InputObject $NewParamConfig -NotePropertyName 'paramName' -NotePropertyValue $ParamLabel
			$TMActionParams.Add($NewParamConfig) | Out-Null
		}
	
		## If no Parameters were assembled, provide an empty array
		if (-not $TMActionParams) { $TMActionParams = [System.Collections.ArrayList] @() }
	}

	## Assemble the Action Object
	$TMAction = [pscustomobject]@{
		id                     = $null
		name                   = $ActionConfig.ActionName
		description            = $ActionConfig.Description
		debugEnabled           = $false
        
		methodParams           = ($TMActionParams | ConvertTo-Json -Compress)
		script                 = $ActionScriptCode
		reactionScripts        = '{"PRE":"","ERROR":"// Put the task on hold and add a comment with the cause of the error\n task.error( response.stderr )","FINAL":"","FAILED":"","LAPSED":"","STATUS":"// Check the HTTP response code for a 200 OK \n if (response.status == SC.OK) { \n \t return SUCCESS \n } else { \n \t return ERROR \n}","DEFAULT":"// Put the task on hold and add a comment with the cause of the error\n task.error( response.stderr )\n","STALLED":"","SUCCESS":"// Update Asset Fields\nif(response?.data?.assetUpdates){\n\tfor (field in response.data.assetUpdates) {\n   \t\tasset.\"${field.key}\" = field.value;\n\t}\n}\ntask.done()"}'
        
		provider               = @{
			id   = $null
			name = $ActionConfig.ProviderName
		}
		project                = @{
			id   = $null
			name = $null
		}
        
		remoteCredentialMethod = 'USER_PRIV'
		credential             = $null 
        
		asyncQueue             = $null
		
		version                = 1
		dateCreated            = Get-Date
		lastUpdated            = Get-Date

		timeout                = 0
		commandLine            = $null
		dictionaryMethodName   = "Select..."
		callbackMethod         = $null 
		connectorMethod        = $null 
		pollingStalledAfter    = 0
		pollingInterval        = 0
		pollingLapsedAfter     = 0
		defaultDataScript      = $null
		useWithTask            = 0
		reactionScriptsValid   = 1
		docUrl                 = ''
		isRemote               = $true
		actionType             = 'POWER_SHELL'
		useWithAsset           = 0
		isPolling              = 0
		endpointUrl            = ''
		apiCatalog             = $null
	}

	
	## Handle Credential Loading  Defaults to User priv, but if there is a credential Name supplied, the credential should be used
	if ($ActionConfig.CredentialName) {
		$TMAction.remoteCredentialMethod = 'SUPPLIED'
		$TMAction.credential = [pscustomobject]@{
			name = $TMCredential.name
		}
	}

	## Return the Action Object
	return $TMAction

}