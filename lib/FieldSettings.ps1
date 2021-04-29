
## TM Field Settings
Function Get-TMNextSharedColumn {
	param(
		[Parameter(Mandatory = $false, ValueFromPipeline = $true)][PSObject]$FieldSpecs
	)

	## Get furthest Custom field number number in each

	for ($i = 1; $i -ne 100; $i++) {
		if (
			(-Not ($FieldSpecs.APPLICATION.fields | Where-Object { $_.field -eq 'custom' + $i })) `
				-and (-Not ($FieldSpecs.DEVICE.fields | Where-Object { $_.field -eq 'custom' + $i })) `
				-and (-Not ($FieldSpecs.DATABASE.fields | Where-Object { $_.field -eq 'custom' + $i })) `
				-and (-Not ($FieldSpecs.STORAGE.fields | Where-Object { $_.field -eq 'custom' + $i })) 
		) {
			return 'custom' + $i
		}
	}
}
Function Get-TMNextCustomColumn {
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)][PSObject]$ClassFields
	)
	
	for ($i = 1; $i -ne 100; $i++) {
		if (-Not ($ClassFields.fields | Where-Object { $_.field -eq 'custom' + $i })) {
			return 'custom' + $i
		}
	}
}
Function Get-TMFieldSpecs {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$ResetIDs,
		[Parameter(Mandatory = $false)][Switch]$CustomOnly,
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

	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')
	
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/customDomain/fieldSpec/ASSETS'
	
	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$Result = ($response.Content | ConvertFrom-Json)
	} else {
		return "Unable to collect Field Settings."
	}



	if ($CustomOnly) {
		foreach ($AssetClass in $Result.PSObject.Properties.Value) {	
			$AssetClass.fields = $AssetClass.fields | Where-Object { $_.udf -ne '0' }
		}
	}

	if ($ResetIDs) {
		foreach ($AssetClass in $Result.PSObject.Properties.Value) {
			for ($i = 0; $i -lt $AssetClass.fields.Count; $i++) {
				if ($AssetClass.fields[$i].field -like 'custom*') { 
					$Result.($AssetClass.domain).fields[$i].field = "customN" 
				}
			}
		}

	}
	return $Result
}
Function Update-TMFieldSpecs {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $true)][PSObject]$FieldSpecs
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

	
	## Define the domain classes
	$DomainClasses = @('APPLICATION', 'DEVICE', 'DATABASE', 'STORAGE')
	
	# Get the Existing Field Spec
	$ServerFields = Get-TMFieldSpecs -TMSession $TMSession
	
	# Create the Updated FieldSpec Object and clear the fields
	$UpdateFields = $ServerFields | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
	foreach ($DomainClass in $DomainClasses) {
		$UpdateFields.$DomainClass.fields = @()
	}
	
	# Collect the existing Asset Class Fields, updating them if they exist
	foreach ($DomainClass in $DomainClasses) {
		
		$ServerClassFields = $ServerFields.$DomainClass.fields
		$NewFields = $FieldSpecs.$DomainClass.fields
	
		foreach ($Field in $ServerClassFields) {

			## Look for an existing field name 
			$MatchingNewField = $NewFields | Where-Object { $_.label -eq $Field.label }
			if ($MatchingNewField) {
				
				## Get the UPDATED Field
				$ReturnField = $MatchingNewField | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json
				
				## Update with the original Field ID to keep the existing column
				$ReturnField.field = $Field.field

				## Set the Constraints iist
				if ($ReturnField.control -in @('List', 'YesNo')) {
					
					## For Each field that already exists, get the list of constraints
					$Field.constraints.values | ForEach-Object {
						
						## If the ReturnField Constraints doesn't have the value, add it
						if ($ReturnField.constraints.values -notcontains $_) {
							$ReturnField.constraints.values += $_
						}
					}
				}

				## Remove the Added field from the Incoming Field Spec object so it doesn't get added again
				$NewFields.PSObject.Properties.Remove($MatchingNewField)
				
			} else {
				
				## There is no matching field, return the original Field
				$ReturnField = $Field
			}
			
			$UpdateFields.$DomainClass.fields += $ReturnField
		}
	}
	
	# Add Shared Fields 
	##  This is only done on one asset class (0, which exists every time). Since shared fields go to all asset classes.
	$NewSharedFields = $FieldSpecs.$DomainClass[0].fields | Where-Object { $_.shared -eq 1 }
	foreach ($NewSharedField in $NewSharedFields) {
			
		## Don't allow duplicates by label
		if (
			($UpdateFields.APPLICATION.fields | Where-Object { $_.label -eq $NewSharedField.label }) `
				-or ($UpdateFields.DEVICE.fields | Where-Object { $_.label -eq $NewSharedField.label }) `
				-or ($UpdateFields.DATABASE.fields | Where-Object { $_.label -eq $NewSharedField.label }) `
				-or ($UpdateFields.STORAGE.fields | Where-Object { $_.label -eq $NewSharedField.label }) `
		) {
			
			## Field Already Exists and has been updated
			# Write-Host "Shared Field Name:"$NewSharedField.label"is already in use."
			
			Continue
		}
			
		## Field doesn't exist
		$ReturnField = $NewSharedField | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json
		if ($ReturnField.field -eq 'customN') {
			$ReturnField.field = Get-TMNextSharedColumn $UpdateFields 
		}
		$UpdateFields.APPLICATION.fields += $ReturnField
		$UpdateFields.DEVICE.fields += $ReturnField
		$UpdateFields.DATABASE.fields += $ReturnField
		$UpdateFields.STORAGE.fields += $ReturnField
		# Write-Host 'ADDING SHARED Field Name: ' $ReturnField.label
	}

	## Add NON Shared fields, one for each Asset Class
	foreach ($DomainClass in $DomainClasses) {
		$NewNonSharedFields = $FieldSpecs.$DomainClass.fields | Where-Object { $_.shared -eq 0 }
		
		foreach ($Field in $NewNonSharedFields) {
			
			## Don't allow duplicates by label
			if ($UpdateFields.$DomainClass.fields | Where-Object { $_.label -eq $Field.label }) {
				
				## Field Already Exists and has been updated
				# Write-Host $DomainClass 'Field Name: ' $Field.label ' is already in use.'
				Continue
			}
			
			## Field doesn't exist
			$ReturnField = $Field
			if ($ReturnField.field -eq 'customN') {
				$ReturnField.field = Get-TMNextCustomColumn $UpdateFields.$DomainClass 
			}
			$UpdateFields.$DomainClass.fields += $ReturnField
			# Write-Host 'ADDING '$DomainClass 'Field Name: ' $Field.label

		}
	}

	## Build the URL to post back to
	$uri = "https://"
	$uri += $Server
	$uri += '/tdstm/ws/customDomain/fieldSpec/ASSETS'
		
	$PostBody = $UpdateFields | ConvertTo-Json -Depth 100 -Compress
		
	Set-TMHeaderContentType -ContentType 'JSON' -TMSession $TMSession
		
	try {
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$ResponseJson = $response.Content | ConvertFrom-Json -Depth 100
				
			if ($ResponseJson.status -eq 'success') {
				# Write-Host 'Field Specs been updated.'
				return
			} else {
				throw $ResponseJson.errors
			}
		} elseif ($response.StatusCode -eq 204) {
			return
		} else { throw $_ }
	} catch {
		return $_
	}
	
}
Function Add-TMFieldListValues {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $true)][String]$Domain,
		[Parameter(Mandatory = $true)][String]$FieldLabel,
		[Parameter(Mandatory = $true)][Array]$Values
	)

	if ($Values.Count -gt 0) {

	
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


		## Define the domain classes
		$DomainClasses = @{
			Application = 'APPLICATION'
			Device      = 'DEVICE'
			Database    = 'DATABASE'
			Storage     = 'STORAGE'
		}
	
		# Get the Existing Field Spec
		$FieldSpecs = Get-TMFieldSpecs -TMSession $TMSession
	
		## Create the Updated FieldSpec Object and clear the fields
		$Field = $FieldSpecs.($DomainClasses[$Domain]).fields | Where-Object { $_.label -eq $FieldLabel }
	
		# If the field doesn't yet have a values array, add one.
		if (-not (Get-Member -InputObject $Field.constraints -Name 'values' -MemberType NoteProperty)) {
			Add-Member -InputObject $Field.constraints -NotePropertyName 'values' -NotePropertyValue @()
		}
	
		## Add each new item
		foreach ($NewItem in $Values) {
		
			## Check to see if it's in the list
			if (-Not $Field.constraints.values.Contains($NewItem)) {
				$Field.constraints.values += $NewItem
				# Write-Host ('Adding ' + $NewItem + ' to Field Values for ' + $Domain + ' | ' + $FieldLabel)
			}
		}

		## Put the data back
		$FieldSpecs.($DomainClasses[$Domain]).fields | Where-Object { $_.label -eq $FieldLabel } | ForEach-Object {
			$_ = $Field
		}


		$uri = "https://"
		$uri += $Server
		$uri += '/tdstm/ws/customDomain/fieldSpec/ASSETS'

		$PostBody = $FieldSpecs | ConvertTo-Json -Depth 100

		Set-TMHeaderContentType -ContentType 'JSON' -TMSession $TMSession

		try {
			$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
			if ($response.StatusCode -eq 200) {
				$ResponseJson = $response.Content | ConvertFrom-Json -Depth 100

				if ($ResponseJson.status -eq 'success') {
					# Write-Host ($Domain + ' field: ' + $Field.field + '-' + $FieldLabel + ' has been updated.')
					return
				}
			} elseif ($response.StatusCode -eq 204) {
				return
			} else { ThrowError 'Unable to save Field Settings' }


		} catch {
			return $_
		}
	}
}