

# Recipes
Function Get-TMRecipe {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $false)][String]$Name,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][String]$SaveCodePath,
		[Parameter(Mandatory = $false)][Switch]$ResetIDs,
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
	$uri += '/tdstm/ws/cookbook/recipe/list?archived=n&context=All'

	try {
		$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
	} catch {
		return $_
	}

	if ($response.StatusCode -eq 200) {
		$Result = ($response.Content | ConvertFrom-Json).data.list
	} else {
		return "Unable to collect Recipes."
	}
	
	## Get each recipe's Source Code in the list
	for ($i = 0; $i -lt $Result.Count; $i++) {
		
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/cookbook/recipe/' + $Result[$i].recipeId
		try {
			$response = Invoke-WebRequest -Method Get -Uri $uri -WebSession $TMSessionConfig.TMWebSession @TMCertSettings
		} catch {
			return $_
		}

		if ($response.StatusCode -eq 200) {
			$Result[$i] = ($response.Content | ConvertFrom-Json).data
		} else {
			return "Unable to collect Recipes."
		}
	}

	if ($ResetIDs) {
		for ($i = 0; $i -lt $Result.Count; $i++) {
			$Result[$i].recipeId = $null
			if ($Result[$i].context.eventId) { $Result[$i].context.eventId = $null }
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
			$SafeScriptName = Get-FilenameSafeString $Item.name

			## Create the Provider Action Folder path
			Test-FolderPath -FolderPath $SaveCodePath

			## Create a File ame for the Action
			$ScriptPath = Join-Path $SaveCodePath  ($SafeScriptName + '.groovy')

			## Build a config of the important References
			$TMConfig = [PSCustomObject]@{
				RecipeName    = $Item.name
				Description   = $Item.description
				VersionNumber = $Item.versionNumber
			} | ConvertTo-Json | Out-String

			## Create a Script String output
			$ScriptOutput = [System.Text.StringBuilder]::new()
			$ScriptOutput.AppendLine("/*********TransitionManager-Recipe-Script*********") | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
		
			$ScriptOutput.AppendLine($TMConfig) | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
		
			$ScriptOutput.AppendLine("*********TransitionManager-Recipe-Script*********/") | Out-Null
	
			$ScriptOutput.AppendLine() | Out-Null
			$ScriptOutput.AppendLine() | Out-Null
	
			## Write the Script to the Configuration
			$ScriptOutput.AppendLine($Item.sourceCode) | Out-Null
			$ScriptOutput.AppendLine() | Out-Null

			## Start Writing the Content of the Script (Force to overwrite any existing files)
			Set-Content -Path $ScriptPath -Force -Value $ScriptOutput.toString()

		}
	} else {

		return $Output
	}
}
Function New-TMRecipe {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Recipe,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$Update, 
		[Parameter(Mandatory = $false)][Switch]$PassThru
	)
	if ($global:TMSessions[$TMSession].TMVersion -like '4.6*') {
		New-TMRecipe46 @PSBoundParameters
	} else {
		New-TMRecipe47 @PSBoundParameters
	}
}

Function New-TMRecipe46 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Recipe,
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

	# Write-Host "Creating Recipe: "$Recipe.Name

	## Check for existing credential 
	$RecipeCheck = Get-TMRecipe -Name $Recipe.Name -TMSession $TMSession
	if ($RecipeCheck) {
		return $RecipeCheck
	} else {
		## No Recipe exists.  Create it
		$instance = $Server.Replace('/tdstm', '')
		$instance = $instance.Replace('https://', '')
		$instance = $instance.Replace('http://', '')
	
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/cookbook/recipe'

		## Add Recipe Shell on server
		$PostBody = @{
			name        = $Recipe.Name
			description = $Recipe.description
		}
		
		Set-TMHeaderContentType -ContentType 'Form' -TMSession $TMSession
		
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $PostBody @TMCertSettings
		if ($response.StatusCode -eq 200) {
			$responseContent = $response.Content | ConvertFrom-Json
			if ($responseContent.status -eq "success") {
				
				## Created a new recipe ID, update the Recipe Object and save it.
				$newRecipeID = $responseContent.data.recipeId

				$UpdatedRecipe = @{
					recipeId              = $newRecipeID
					name                  = $Recipe.name
					description           = $Recipe.description
					createdBy             = $Recipe.createdBy
					versionNumber         = $Recipe.versionNumber
					releasedVersionNumber = $Recipe.releasedVersionNumber
					recipeVersionId       = $Recipe.releasedVersionId
					hasWIP                = $Recipe.hasWIP
					sourceCode            = $Recipe.sourceCode
					changelog             = $Recipe.changelog
					clonedFrom            = $Recipe.clonedFrom
				}

				# Update the newly created recipe with the data
				$uri = "https://"
				$uri += $instance
				$uri += '/tdstm/ws/cookbook/recipe/' + $newRecipeID
				$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $UpdatedRecipe @TMCertSettings
				if ($response.StatusCode -eq 200) {
					$responseContent = $response.Content | ConvertFrom-Json
					if ($responseContent.status -eq "success") {
						if ($PassThru) { return $UpdatedRecipe }
					} else {
						throw "Unable to add Recipe."
					}
				} else {
					throw "Unable to add Recipe."
				}
			} else {
				throw "Unable to add Recipe."
			}
		} else {
			throw "Unable to add Recipe."
		}
	
	}	
}
Function New-TMRecipe47 {
	param(
		[Parameter(Mandatory = $false)][String]$TMSession = "Default",
		[Parameter(Mandatory = $true)][PSObject]$Recipe,
		[Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
		[Parameter(Mandatory = $false)]$AllowInsecureSSL = $global:TMSessions[$TMSession].AllowInsecureSSL,
		[Parameter(Mandatory = $false)][Switch]$Update,
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

	## Strip Instance Name out
	$instance = $Server.Replace('/tdstm', '')
	$instance = $instance.Replace('https://', '')
	$instance = $instance.Replace('http://', '')

	#Honor SSL Settings
	if ($TMSessionConfig.AllowInsecureSSL) {
		$TMCertSettings = @{SkipCertificateCheck = $true }
	} else { 
		$TMCertSettings = @{SkipCertificateCheck = $false }
	}

	## Check for existing credential, or Create a shell  
	$RecipeCheck = Get-TMRecipe -Name $Recipe.Name -TMSession $TMSession
	if ($RecipeCheck) {
		
		## If Update is enabled, set the RecipeID for the update
		if ($Update) {
			$NewRecipeID = $RecipeCheck.recipeId
		} else {

			## If Passthru is enabled, return the object
			if ($PassThru) {
				return $RecipeCheck
			} else {
				return
			}
		}
	} else {

		## The Recipe needs to be created.  Start by posting the name to get an ID
		$uri = "https://"
		$uri += $instance
		$uri += '/tdstm/ws/cookbook/recipe'
	
		## Create a new Recipe
		$CreateNewRecipe = @{
			name        = $Recipe.name
			description = $Recipe.description
		}
		
		## Send the New recipe to the server
		Set-TMHeaderContentType -ContentType Form
		$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $CreateNewRecipe @TMCertSettings
		if ($response.StatusCode -eq 200) {
		
			## Convert the response content
			$responseContent = $response.Content | ConvertFrom-Json

			## If Successful
			if ($responseContent.status -eq "success") {
				
				## Created a new recipe ID, update the Recipe Object and save it.
				$NewRecipeID = $responseContent.data.recipeId
			
			} else {
				throw "Unable to add Recipe."
			}
		} else {
			throw "Unable to add Recipe."
		}
	}
	
	##
	## Update or Create the Recipe
	##

	## With the Existing or New RecipeID Update the Recipe Data
	$UpdatedRecipe = @{
		recipeId              = $NewRecipeID
		name                  = $Recipe.name
		description           = $Recipe.description
		createdBy             = $Recipe.createdBy
		versionNumber         = $Recipe.versionNumber
		releasedVersionNumber = $Recipe.releasedVersionNumber
		releasedVersionId     = $Recipe.releasedVersionId
		hasWIP                = $Recipe.hasWIP
		sourceCode            = $Recipe.sourceCode
		changelog             = $Recipe.changelog
		clonedFrom            = $Recipe.clonedFrom
	}
		
	# Update the newly created recipe with the data
	$uri = "https://"
	$uri += $instance
	$uri += '/tdstm/ws/cookbook/recipe/' + $NewRecipeID 
	
	## Send the Recipe (New or Update)
	Set-TMHeaderContentType -ContentType Form
	$response = Invoke-WebRequest -Method Post -Uri $uri -WebSession $TMSessionConfig.TMWebSession -Body $UpdatedRecipe @TMCertSettings
	if ($response.StatusCode -eq 200) {
		
		## Convert the response content
		$responseContent = $response.Content | ConvertFrom-Json

		## If Successful
		if ($responseContent.status -eq "success") {
				
			## Created a new recipe ID, update the Recipe Object and save it.
			$ResponseRecipe = $responseContent.data

			## If Passthru is enabled, return the Updated Recipe
			if ($PassThru) { return $ResponseRecipe }
			
		} else {
			throw "Unable to add Recipe."
		}
	} else {
		throw "Unable to add Recipe."
	}
}


Function Read-TMRecipeScriptFile {
	param(
		[Parameter(Mandatory = $true)]$Path
	)

	## Name the Input File
	$Content = Get-Content -Path $Path -Raw
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
		Where-Object { $_.Text -like '/*********TransitionManager-Recipe-Script*********' } |`
		Select-Object -First 1 | `
		Select-Object -ExpandProperty Extent | `
		Select-Object -ExpandProperty StartLineNumber
	

	## If the Output contains the appropriate TMD Recipe Script header
	if (-Not $ConfigBlockStartLine) {

		## The File is not a formated export with metadata, read it as is and produce a best-effort RecipeConfig
		$RecipeConfig = @{
			recipeId              = $null
			RecipeName            = (Get-Item -Path $Path).BaseName
			description           = ''
			versionnumber         = 1
        
			## Source Code
			sourceCode            = $ContentLines.ToString()
        
			## Other details for the ETL Script
			dateCreated           = Get-Date
			lastUpdated           = Get-Date
			releasedVersionNumber = 1
			hasWIP                = $false
			changeLog             = ''
			clonedFrom            = ''
		}
	} else {
		## Find the Config Block End Header
		$ConfigBlockEndLine = $astTokens | `
			Where-Object { $_.Text -like '*********TransitionManager-Recipe-Script*********/' } |`
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
		$RecipeConfigJson = $JsonConfigBlockStartLine..$JSONConfigBlockEndLine | ForEach-Object {
        
			## Return the line for collection
			$ContentLines[$_ - 1]

		} | Out-String
    
		## Convert the JSON string to an Object
		$RecipeConfig = $RecipeConfigJson | ConvertFrom-Json -ErrorAction 'SilentlyContinue'
    
	

		## 
		## Read the Script Block
		## 
		
		## Note where the Configuration Code is located
		$StartCodeBlockLine = $ConfigBlockEndLine + 1
		$EndCodeBlockLine = $ast[-1].Extent.EndLineNumber
		
		## Create a Text StrinBuilder to collect the Script into
		$RecipeStringBuilder = New-Object System.Text.StringBuilder
	
		## For each line in the Code Block, add it to the Etl Script Code StringBuilder
		$StartCodeBlockLine..$EndCodeBlockLine | ForEach-Object {
			$RecipeStringBuilder.AppendLine($ContentLines[$_]) | Out-Null
		}
	
		## Convert the StringBuilder to a Multi-Line String
		$RecipeConfig | Add-Member -NotePropertyName 'sourceCode' -NotePropertyValue $RecipeStringBuilder.ToString()

	}

	## 

	## Assemble the Action Object
	$TMRecipe = [pscustomobject]@{
		
		## Primary Information
		recipeId              = $RecipeConfig.recipeId
		name                  = $RecipeConfig.RecipeName
		description           = $RecipeConfig.Description
		versionnumber         = $RecipeConfig.VersionNumber
        
		## Source Code
		sourceCode            = $RecipeScriptCode
        
		## Other details for the ETL Script
		dateCreated           = Get-Date
		lastUpdated           = Get-Date
		releasedVersionNumber = $RecipeConfig.VersionNumber
		hasWIP                = $false
		changeLog             = ''
		clonedFrom            = ''
	}
	
	## Return the Recipe Object
	return $TMRecipe

}