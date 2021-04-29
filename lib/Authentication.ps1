
## Define a TMSessions Variable to store connection details in
New-Variable -Scope global -Name 'TMSessions' -Value @{ } -Force

## Session Management
Function New-TMSession {
    [CmdletBinding()]
    [Alias('Connect-TMServer')]
    param(
        [Parameter(Mandatory = $false)][String]$SessionName = 'Default',
        [Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].SiteURL, ## This mis-matches what should be on the rest of the $Server string throughout this module.
        [Parameter(Mandatory = $false)][PSCredential]$Credential, 
        [Parameter(Mandatory = $false)][String]$TMVersion,
        [Parameter(Mandatory = $false)][Bool]$AllowInsecureSSL,
        [Parameter(Mandatory = $false)][Switch]$PassThru

    )
    if ((-not $Server) -or (-not $Credential)) {
        Write-Host 'Credential and Server are required' -ForegroundColor Red
        throw 'Credential and Server are required'
    }

    # if ($Server -notcontains '.') {
    #     $Server += '.transitionmanager.net'
    # }

    ## Create the TMServers Array that will be reachable at $global:TMSessions
    if (-not $global:TMSessions) {
        New-Variable -Name TMSessions -Scope Global -Value @{}
    }   

    ## Check for Existing Session to this server
    if ($global:TMSessions.PSObject.Peroperties.SessionName -match $SessionName) {
        
        $NewTMSession = $global:TMSessions[$SessionName]
    } else {
        ## Create a session object for this new connection
        $NewTMSession = @{
            # TMWebSession Variable. Maintained by the Invoke-WebRequest function's capability
            TMWebSession     = ''       
            
            # TM Server hostname
            TMServer         = $Server       
            
            # Logged in TM User's Context (indicates loggedin-ness)
            UserContext      = ''       
            
            # TMVersion drives the selection of compatible APIs to use
            TMVersion        = ''       
            
            ## Should PowerShell ignore the SSL Cert on the TM Server? 
            ##  This is the only applied default.  A user must provide -AllowInsecureSSL
            ##  at the time of their logon.  That overrides this default, 
            ##  and is sticky for that SSL session only
            AllowInsecureSSL = $AllowInsecureSSL   

            ## Initalize an empty cache to track non-changing items to reduce HTTP lookups, and
            ## Increase speed of script
            ## DataCache is expected to be a k/v pair, where the V could be another k/v pair,
            ## However, it's implementation will be more of the nature to hold the list of object calls from the API
            ## like 'credentials' = @(@{...},@{...});  'actions' = @(@{...},@{...})
            ## Get-TM* functions will cache unless a -NoCache switch is provided
            DataCache        = @{ }
        }
    }

    #Honor SSL Settings from the user
    if ($AllowInsecureSSL) {
        $TMCommandSwitches = @{AllowInsecureSSL = $true }
        $TMCertSettings = @{SkipCertificateCheck = $true }
    } else { 
        $TMCommandSwitches = @{AllowInsecureSSL = $false }
        $TMCertSettings = @{SkipCertificateCheck = $false }
    }

    ## normalize the Server URL
    $instance = $Server.Replace('/tdstm', '')
    $instance = $instance.Replace('https://', '')
    $instance = $instance.Replace('http://', '')

    ## Add this shortened Instance name (Just the hostname) into the Session Object
    $NewTMSession.TMServer = $instance

    # Get the TM Version (Allow a different api usage of an alternate version)
    if ($TMVersion) {
        $NewTMSession.TMVersion = $TMVersion
    } else {
        $NewTMSession.TMVersion = Get-TMVersion -Server $Server @TMCommandSwitches
    }

    ## Prepare Request Headers for use in the Session Header Cache
    $RequestHeaders = @{
        "Accept-Version" = "1.0";
        "Content-Type"   = "application/json;charset=UTF-8";
        "Accept"         = "application/json";
        "Cache-Control"  = "no-cache";

    } 
	
    # Get API Enpoint
    $uri = Get-TMEndpointUri -Server $Server -EndpointName 'signIn' -TMVersion $NewTMSession.TMVersion
    
    ## Attempt Login
    Write-Host "Logging into TransitionManager instance [ " -NoNewline
    Write-Host $instance -ForegroundColor Cyan -NoNewline
    Write-Host " ]"
    try {
        
        ## TM Versions 4.4, 4.5 and 4.6
        if (($NewTMSession.TMVersion -like '4.4*') -or ($NewTMSession.TMVersion -like '4.5*') -or ($NewTMSession.TMVersion -like '4.6*')) {
            
            
            $PostBody = @{
                username = $Credential.UserName
                password = $Credential.GetNetworkCredential().Password
            } | ConvertTo-Json
            $ContentType = 'application/json;charset=UTF-8'
            $Response = Invoke-WebRequest -Method 'POST' -Uri $uri -Headers $RequestHeaders -Body $PostBody -SessionVariable TMWebSession -PreserveAuthorizationOnRedirect @TMCertSettings -ContentType $ContentType
                
            if ($Response.StatusCode -eq 200) {
            
                $UserContext = ($Response.Content | ConvertFrom-Json -Depth 100 ).userContext 
                if ($UserContext) {
                        
                    $ConnectedTMContext = @{
                        TMServer         = $Server
                        UserContext      = $UserContext
                        AllowInsecureSSL = $AllowInsecureSSL
                        TMVersion        = $TMVersion
                    }
                            
                    Write-Host "Login Successful! Selected Project: "$ConnectedTMContext.UserContext.project.name
                            
                    ## Set the necessary global variables
                    $global:TMWebSession = $TMWebSession
                    $global:ConnectedTMContext = $ConnectedTMContext
                    return
                }
            }
        
            ##Versions 4.7.x
        } elseif ($NewTMSession.TMVersion -like '4.7*') {
            
            $PostBody = @{
                username = $Credential.UserName
                password = $Credential.GetNetworkCredential().Password
            } | ConvertTo-Json
            $ContentType = 'application/json;charset=UTF-8'
                
            ## Send the Web Request to get a Response
            $WebRequestSplat = @{
                Method = 'POST'
                Uri = $uri 
                Headers = $RequestHeaders 
                Body = $PostBody 
                SessionVariable = 'TMWebSession' 
                PreserveAuthorizationOnRedirect = $true
                ContentType = $ContentType 
            }
            $Response = Invoke-WebRequest @WebRequestSplat @TMCertSettings

            ## Check the Response code for 200
            if ($Response.StatusCode -eq 200) {
                $ResponseContent = ($Response.Content | ConvertFrom-Json -Depth 100 )

                ## Ensure the login succeeded.
                if ($ResponseContent.PSObject.Properties.name -eq 'error' ) {
                        
                    ## Report Error Condition
                    $LoginError = 'Login Failed: ' + $ResponseContent[0].'error'
                    throw $LoginError
                }

                ## Login Succeeded
                # $UserContext = ($Response.Content | ConvertFrom-Json -Depth 100 ).userContext 
                if ($ResponseContent.userContext) {
                    
                    $UserContext = $ResponseContent.userContext
                    Write-Host "Login Successful! Entering Last Project used: [" -NoNewline
                    Write-Host $UserContext.project.name -ForegroundColor Cyan -NoNewline
                    Write-Host "]"

                } else {
                    Throw "Login Failure! Unable to Log into $Server.  Check the URL and Credentials and try again"
                }
            } else {
                Throw $_
            }
        } 
        ##Versions 5.0.*
        elseif ($NewTMSession.TMVersion -like '5.0*') {
            
            $PostBody = @{
                username = $Credential.UserName
                password = $Credential.GetNetworkCredential().Password
            } | ConvertTo-Json
            $ContentType = 'application/json;charset=UTF-8'
                
            ## Send the Web Request to get a Response
            $WebRequestSplat = @{
                Method = 'POST' 
                Uri = $uri 
                Headers = $RequestHeaders 
                Body = $PostBody 
                SessionVariable = 'TMWebSession' 
                PreserveAuthorizationOnRedirect = $true
                ContentType = $ContentType 
            }
            $Response = Invoke-WebRequest @WebRequestSplat @TMCertSettings
        
            ## Check the Response code for 200
            if ($Response.StatusCode -eq 200) {
                $ResponseContent = ($Response.Content | ConvertFrom-Json -Depth 100 )

                ## Ensure the login succeeded.
                if ($ResponseContent.PSObject.Properties.name -eq 'error' ) {
                        
                    ## Report Error Condition
                    $LoginError = 'Login Failed: ' + $ResponseContent[0].'error'
                    throw $LoginError
                }

                ## Login Succeeded
                # $UserContext = ($Response.Content | ConvertFrom-Json -Depth 100 ).userContext 
                if ($ResponseContent.userContext) {
                    
                    $UserContext = $ResponseContent.userContext
                    Write-Host "Login Successful! Entering Last Project used: [" -NoNewline
                    Write-Host $UserContext.project.name -ForegroundColor Cyan -NoNewline
                    Write-Host "]"

                } 
                else {
                    Throw "Login Failure! Unable to Log into $Server.  Check the URL and Credentials and try again"
                }
            } 
            else {
                Throw $_
            }
        } 
        else {
            Throw 'Unable to Log in.  Version of Login not supported'
        }

        ## Create the TMSessionObject that will be checked/used by the rest of the TransitionManager Modules
        $NewTMSession.TMWebSession = $TMWebSession
        $NewTMSession.UserContext = $UserContext

        ## Version 5 adds a CSRF token to the login.  This must be added to the WebSession Headers for future requests
        if($ResponseContent.csrf){
            $NewTMSession.TMWebSession.Headers.($ResponseContent.csrf.tokenHeaderName) = $ResponseContent.csrf.token
        }

        ## Add this Session to the TMSessions list
        # $global:TMSessions | Add-Member -NotePropertyName $SessionName -NotePropertyValue $NewTMSession
        $global:TMSessions[$SessionName] = $NewTMSession

        ## Return the session if requested
        if ($PassThru) {
            return $NewTMSession
        }
    } 
    catch {
        throw $_
    }
}


Function Get-TMVersion {
    param(
        [Parameter(Mandatory = $false)][String]$Server = $global:TMSessions[$TMSession].TMServer,
        [Parameter(Mandatory = $false)][String]$Format = "SemVer", 
        [Parameter(Mandatory = $false)]$AllowInsecureSSL
    )

    ## Select the Version formatter
    $regex = switch ($Format) {
        "VersionSemVer" { "/Version\ [0-9].[0-9].[0-9]/" }
        "SemVer" { "[0-9].[0-9].[0-9]" }
        "Minor" { "[0-9].[0-9]" }
        Default { "((.|\n)*)" }
    }

    #Honor SSL Settings
    if ($TMSessionConfig.AllowInsecureSSL -or $AllowInsecureSSL) {
        $TMCertSettings = @{SkipCertificateCheck = $true }
    } else { 
        $TMCertSettings = @{SkipCertificateCheck = $false }
    }

    $instance = $Server.Replace('/tdstm', '')
    $instance = $instance.Replace('https://', '')
    $instance = $instance.Replace('http://', '')
	
    # Check for 4.6
    $uri = "https://$instance/tdstm/auth/login"
    # $uri = Get-TMEndpointUri -Server $Server -EndpointName 'signIn'
	

    try {
        $Response = Invoke-WebRequest -Method Get -Uri $uri @TMCertSettings
        if ($Response.StatusCode -eq 200) {
			
            $buildNumbers = $Response.Content | Select-String -Pattern "Version\ [0-9]\.[0-9]\.[0-9]"
            if ($buildNumbers.Matches.Count -gt 0) {
                $result = $buildNumbers.Matches | Select-String -Pattern $regex | ForEach-Object { $_.Matches } | Select-Object -First 1
				
                ## Force use of a certain version:
                # if ($result.Value -eq '4.5.9') {
                # 	$result = '4.6.3'
                # }
				
                return $result
	
            } else {
                # We didn't find a 4.6 version number.  It might be a 4.7 or greater, where the versionInfo was introduced
                $uri = "https://$instance/tdstm/auth/loginInfo"
                $Response = Invoke-WebRequest -Method Get -Uri $uri @TMCertSettings
                if ($Response.StatusCode -eq 200) {
                    $BuildVersion = ($Response.Content | ConvertFrom-Json).data.buildVersion
                    $FinalBuildNumber = Select-String -Pattern $regex -InputObject $BuildVersion
                    if ($FinalBuildNumber.Matches.Count -gt 0) {
                        $result = $FinalBuildNumber.Matches | Select-Object -First 1

                        ## Force use of a certain version:
                        # if ($result -eq '4.5.9') { $result = '4.6.3' }

                        return $result
                    }
                }
            }
        }
    } catch {
        Write-Host "Could not get version"
        return $_
    }
}