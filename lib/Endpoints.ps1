
$TMApiResponseHandlers = @{
    '4.4.3' = @{
        GetProjectList = [scriptblock] {
            
            $ResultRows = ($response.Content | ConvertFrom-Json).rows
		
            ## Unwrap the 'cell' node
            for ($i = 0; $i -lt $ResultRows.Count; $i++) {
                $ResultRows[$i] = @{
                    id          = $ResultRows[$i].id
                    projectCode = $ResultRows[$i].cell[0]
                    name        = $ResultRows[$i].cell[1]
                    startDate   = $ResultRows[$i].cell[2]
                    endDate     = $ResultRows[$i].cell[3]
                }
            }
            return $ResultRows
        }
        GetBundleList  = [scriptblock] {
            
            $ResultRows = $response.Content | ConvertFrom-Json
            return $ResultRows
        }
        GetDependency  = [scriptblock] { #Needs to be tested!
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
    }
    '4.5.9' = @{
        GetProjectList = [scriptblock] {
            
            $ResultRows = ($response.Content | ConvertFrom-Json).rows
		
            ## Unwrap the 'cell' node
            for ($i = 0; $i -lt $ResultRows.Count; $i++) {
                $ResultRows[$i] = @{
                    id          = $ResultRows[$i].id
                    projectCode = $ResultRows[$i].cell[0]
                    name        = $ResultRows[$i].cell[1]
                    startDate   = $ResultRows[$i].cell[2]
                    endDate     = $ResultRows[$i].cell[3]
                }
            }
            return $ResultRows
        }
        GetBundleList  = [scriptblock] {
            
            $ResultRows = ($response.Content | ConvertFrom-Json).rows
		
            ## Unwrap the 'cell' node
            for ($i = 0; $i -lt $ResultRows.Count; $i++) {
                $ResultRows[$i] = @{
                    id          = $ResultRows[$i].id
                    projectCode = $ResultRows[$i].cell[0]
                    name        = $ResultRows[$i].cell[1]
                    startDate   = $ResultRows[$i].cell[2]
                    endDate     = $ResultRows[$i].cell[3]
                }
            }
            return $ResultRows
        }
        GetDependency  = [scriptblock] { #Needs to be tested!
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
    }
    '4.6.3' = @{
        GetProjectList = [scriptblock] {
            
            $ResultRows = ($response.Content | ConvertFrom-Json).rows
		
            ## Unwrap the 'cell' node
            for ($i = 0; $i -lt $ResultRows.Count; $i++) {
                $ResultRows[$i] = @{
                    id          = $ResultRows[$i].id
                    projectCode = $ResultRows[$i].cell[0]
                    name        = $ResultRows[$i].cell[1]
                    startDate   = $ResultRows[$i].cell[2]
                    endDate     = $ResultRows[$i].cell[3]
                }
            }
            return $ResultRows
        }
        GetDependency  = [scriptblock] { #Needs to be tested!
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
        GetBundleList  = [scriptblock] {
            
            $ResultRows = $response.Content | ConvertFrom-Json
            return $ResultRows
        }
        
    }
    '4.7.1' = @{
        GetProjectList = [scriptblock] {
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
        GetBundleList  = [scriptblock] {
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
        GetDependency  = [scriptblock] {
            $Data = $response.Content | ConvertFrom-Json
            Switch ($Data.Status) {
                "error" {
                    Write-Host $Data.errors
                    break
                } 
                "success" {
                    
                    $Deps = $Data.data.dependencies

                    if ( $AssetId ) { $Deps = $Deps | Where-Object { $_.assetId -eq $AssetId } }
                    if ( $DependentId ) { $Deps = $Deps | Where-Object { $_.dependentId -eq $DependentId } }

                    return $Deps
                    break
                }               

                Default {
                    break
                }
            }
        }
    }
    '4.7.2' = @{
        GetProjectList = [scriptblock] {
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
        GetBundleList  = [scriptblock] {
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
        GetDependency  = [scriptblock] {
            $Data = $response.Content | ConvertFrom-Json
            Switch ($Data.Status) {
                "error" {
                    Write-Host $Data.errors
                    break
                } 
                "success" {
                    
                    $Deps = $Data.data.dependencies

                    if ( $AssetId ) { $Deps = $Deps | Where-Object { $_.assetId -eq $AssetId } }
                    if ( $DependentId ) { $Deps = $Deps | Where-Object { $_.dependentId -eq $DependentId } }

                    return $Deps
                    break
                }               

                Default {
                    break
                }
            }
        }
    }
    '4.7.3' = @{
        GetProjectList = [scriptblock] {
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data.projects
        }
        GetBundleList  = [scriptblock] {
            $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            return $Data
        }
        GetDependency  = [scriptblock] {
            $Data = $response.Content | ConvertFrom-Json
            Switch ($Data.Status) {
                "error" {
                    Write-Host $Data.errors
                    break
                } 
                "success" {
                    
                    $Deps = $Data.data.dependencies

                    if ( $AssetId ) { $Deps = $Deps | Where-Object { $_.assetId -eq $AssetId } }
                    if ( $DependentId ) { $Deps = $Deps | Where-Object { $_.dependentId -eq $DependentId } }

                    return $Deps
                    break
                }               

                Default {
                    break
                }
            }
        }
    }
    '4.7.4' = @{
        GetProjectList = [scriptblock] {
            # $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            $Data = ($response.Content | ConvertFrom-Json).data
            return $Data.projects
        }
        GetBundleList  = [scriptblock] {
            # $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            $Data = ($response.Content | ConvertFrom-Json).data 
            return $Data
        }
        GetDependency  = [scriptblock] {
            $Data = $response.Content | ConvertFrom-Json
            Switch ($Data.Status) {
                "error" {
                    Write-Host $Data.errors
                    break
                } 
                "success" {
                    
                    $Deps = $Data.data.dependencies

                    if ( $AssetId ) { $Deps = $Deps | Where-Object { $_.assetId -eq $AssetId } }
                    if ( $DependentId ) { $Deps = $Deps | Where-Object { $_.dependentId -eq $DependentId } }

                    return $Deps
                    break
                }               

                Default {
                    break
                }
            }
        }
    }
    '4.7.5' = @{
        GetProjectList = [scriptblock] {
            # $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            $Data = ($response.Content | ConvertFrom-Json).data
            return $Data.projects
        }
        GetBundleList  = [scriptblock] {
            # $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            $Data = ($response.Content | ConvertFrom-Json).data 
            return $Data
        }
        GetDependency  = [scriptblock] {
            $Data = $response.Content | ConvertFrom-Json
            Switch ($Data.Status) {
                "error" {
                    Write-Host $Data.errors
                    break
                } 
                "success" {
                    
                    $Deps = $Data.data.dependencies

                    if ( $AssetId ) { $Deps = $Deps | Where-Object { $_.assetId -eq $AssetId } }
                    if ( $DependentId ) { $Deps = $Deps | Where-Object { $_.dependentId -eq $DependentId } }

                    return $Deps
                    break
                }               

                Default {
                    break
                }
            }
        }
    }
    '4.7.6' = @{
        GetProjectList = [scriptblock] {
            # $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            $Data = ($response.Content | ConvertFrom-Json).data
            return $Data.projects
        }
        GetBundleList  = [scriptblock] {
            # $Data = ($response.Content | ConvertFrom-Json).data # | ConvertTo-Hashtable
            $Data = ($response.Content | ConvertFrom-Json).data 
            return $Data
        }
        GetDependency  = [scriptblock] {
            $Data = $response.Content | ConvertFrom-Json
            Switch ($Data.Status) {
                "error" {
                    Write-Host $Data.errors
                    break
                } 
                "success" {
                    
                    $Deps = $Data.data.dependencies

                    if ( $AssetId ) { $Deps = $Deps | Where-Object { $_.assetId -eq $AssetId } }
                    if ( $DependentId ) { $Deps = $Deps | Where-Object { $_.dependentId -eq $DependentId } }

                    return $Deps
                    break
                }               

                Default {
                    break
                }
            }
        }
    }
   
}

$TMApiEndpoints = @{
    
    '4.4.3' = @{
        signIn                = '/auth/signIn'
        Project               = '/project/listJson?isActive=active&_search=false&sidx=projectCode&sord=asc'
        addUserPreference     = '/project/addUserPreference/' + $UriParam #get
        setProject            = '/project/addUserPreference/' + $UriParam #get
        getEvent              = 'moveEvent/listJson'
        Tasks                 = '/ws/task'
	
        #     if ($JustMine) { $justMyTasks = 1 } else { $justMyTasks = 0 }
        #     $uri += '?justMyTasks=' + $justMyTasks
            
        #     if ($JustActionalble) { $vJustActionalble = 1 } else { $vJustActionalble = 0 }
        #     $uri += '&justActionable=' + $vJustActionalble
            
        #     ## Using a static one for now
        #     $uri += '&project=' + $appconfig.TransitionManager.UserContext.projectId
        # }
    
        Credential            = '/ws/credential' #/list, :id:
        ImportBatch           = '/ws/import/batch' #/list, :id:
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
    
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }
        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        GetBundle             = '/moveBundle/retrieveBundleList'
        SaveBundle            = '/moveBundle/save'
        Actions               = '/ws/apiAction'
        GetRecipe             = '/ws/cookbook/recipe' #/list
        #?archived=n&context=All'

        GetDependency         = '/ws/asset/listDependencies' #Untested - Copied from 4.7.1
    }
    '4.5.6' = @{
        signIn                = '/auth/signIn'
        Project               = '/project/listJson?isActive=active&_search=false&sidx=projectCode&sord=asc'
        addUserPreference     = '/project/addUserPreference/' + $UriParam #get
        setProject            = '/project/addUserPreference/' + $UriParam #get
        getEvent              = 'moveEvent/listJson'
        Tasks                 = '/ws/task'
	
        #     if ($JustMine) { $justMyTasks = 1 } else { $justMyTasks = 0 }
        #     $uri += '?justMyTasks=' + $justMyTasks
            
        #     if ($JustActionalble) { $vJustActionalble = 1 } else { $vJustActionalble = 0 }
        #     $uri += '&justActionable=' + $vJustActionalble
            
        #     ## Using a static one for now
        #     $uri += '&project=' + $appconfig.TransitionManager.UserContext.projectId
        # }
    
        Credential            = '/ws/credential' #/list, :id:
        ImportBatch           = '/ws/import/batch' #/list, :id:
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
    
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }
        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        GetBundle             = '/moveBundle/retrieveBundleList'
        SaveBundle            = '/moveBundle/save'
        Actions               = '/ws/apiAction'
        GetRecipe             = '/ws/cookbook/recipe' #/list
        #?archived=n&context=All'

        GetDependency         = '/ws/asset/listDependencies' #Untested - Copied from 4.7.1
    }
    '4.5.9' = @{
        signIn                = '/auth/signIn'
        Project               = '/project/listJson?isActive=active&_search=false&sidx=projectCode&sord=asc'
        addUserPreference     = '/project/addUserPreference/' + $UriParam #get
        setProject            = '/project/addUserPreference/' + $UriParam #get
        getEvent              = 'moveEvent/listJson'
        Tasks                 = '/ws/task'
	
        #     if ($JustMine) { $justMyTasks = 1 } else { $justMyTasks = 0 }
        #     $uri += '?justMyTasks=' + $justMyTasks
            
        #     if ($JustActionalble) { $vJustActionalble = 1 } else { $vJustActionalble = 0 }
        #     $uri += '&justActionable=' + $vJustActionalble
            
        #     ## Using a static one for now
        #     $uri += '&project=' + $appconfig.TransitionManager.UserContext.projectId
        # }
    
        Credential            = '/ws/credential' #/list, :id:
        ImportBatch           = '/ws/import/batch' #/list, :id:
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
    
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }
        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        GetBundle             = '/moveBundle/retrieveBundleList'
        SaveBundle            = '/moveBundle/save'
        Actions               = '/ws/apiAction'
        GetRecipe             = '/ws/cookbook/recipe' #/list
        #?archived=n&context=All'

        GetDependency         = '/ws/asset/listDependencies' #Untested - Copied from 4.7.1
    }
    '4.6.3' = @{
        signIn                = '/auth/signIn'
        Project               = '/project/listJson?isActive=active&_search=false&sidx=projectCode&sord=asc'
        addUserPreference     = '/project/addUserPreference/' + $UriParam #get
        getEvent              = 'moveEvent/listJson'
        Tasks                 = '/ws/task'
        Credential            = '/ws/credential' #/list, :id:
        ImportBatch           = '/ws/import/batch' #/list, :id:
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
    
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }
        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        GetBundle             = '/moveBundle/retrieveBundleList'
        SaveBundle            = '/moveBundle/save'
        Actions               = '/ws/apiAction'
        GetRecipe             = '/ws/cookbook/recipe' #/list
        #?archived=n&context=All'
        GetDependency         = '/ws/asset/listDependencies' #Untested - Copied from 4.7.1
    }
    '4.7.1' = @{
        signIn                = '/auth/signIn'
        Project               = '/ws/project/lists'
        addUserPreference     = 'tdstm/project/addUserPreference/' + $UriParam #get
        setProject            = '/ws/project/viewEditProject/' + $ProjectId #get
        getEvent              = 'moveEvent/listJson'
        getTasks              = '/ws/task'
	
        #     if ($JustMine) { $justMyTasks = 1 } else { $justMyTasks = 0 }
        #     $uri += '?justMyTasks=' + $justMyTasks
            
        #     if ($JustActionalble) { $vJustActionalble = 1 } else { $vJustActionalble = 0 }
        #     $uri += '&justActionable=' + $vJustActionalble
            
        #     ## Using a static one for now
        #     $uri += '&project=' + $appconfig.TransitionManager.UserContext.projectId
        # }
    
        Credential            = '/ws/credential' #/list, :id:
        ImportBatch           = '/ws/import/batch' #/list, :id:
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
    
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }
        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        Actions               = '/ws/apiAction'
        GetRecipe             = '/ws/cookbook/recipe'
        GetDependency         = '/ws/asset/listDependencies'
    }
    '4.7.2' = @{
        
        signIn                = '/auth/signIn'
        ## Upgrading to API
        # setProject            = '/ws/project/viewEditProject/' + $ProjectId #get  Getting Depricated, API calls should include a project.id: assertion
        
        ## Needed
        Project               = '/ws/project/userProjects'
        getEvent              = 'moveEvent/listJson'
        
        Credential            = '/ws/credential' #/list, :id:
        getTasks              = '/ws/task'
        #includes Patch to update objects
        
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        
        
        ## Process ETL is now under one call -- Old no longer needed for v1
        ImportBatch           = '/ws/import/batch' #/list, :id:
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }

        ## Process ETL is now under one call:
        # scheduleImportAPIActionCommand

        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        # Adding Get, Set


        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        # Adding Get/Set
        
        
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        # Adding Get/Set

        
        Actions               = '/ws/apiAction'
        # Adding Get/Setup/Validates
        
        GetRecipe             = '/ws/cookbook/recipe'
        # Adding Get/Setup/Validates
        # Release, Clone
        
        GetDependency         = '/ws/asset/listDependencies'
        # Adding Get/Setup/Validates

    }
    '4.7.3' = @{
        
        signIn                = '/auth/signIn'
        ## Upgrading to API
        # setProject            = '/ws/project/viewEditProject/' + $ProjectId #get  Getting Depricated, API calls should include a project.id: assertion
        
        ## Needed
        Project               = '/ws/project/userProjects'
        getEvent              = 'moveEvent/listJson'
        
        Credential            = '/ws/credential' #/list, :id:
        getTasks              = '/ws/task'
        #includes Patch to update objects
        
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        
        
        ## Process ETL is now under one call -- Old no longer needed for v1
        ImportBatch           = '/ws/import/batch' #/list, :id:
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }

        ## Process ETL is now under one call:
        # scheduleImportAPIActionCommand

        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        # Adding Get, Set


        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        # Adding Get/Set
        
        
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        # Adding Get/Set

        
        Actions               = '/ws/apiAction'
        # Adding Get/Setup/Validates
        
        GetRecipe             = '/ws/cookbook/recipe'
        # Adding Get/Setup/Validates
        # Release, Clone
        
        GetDependency         = '/ws/asset/listDependencies'
        # Adding Get/Setup/Validates

    }
    '4.7.4' = @{
        
        signIn                = '/auth/signIn'
        ## Upgrading to API
        # setProject            = '/ws/project/viewEditProject/' + $ProjectId #get  Getting Depricated, API calls should include a project.id: assertion
        
        ## Needed
        Project               = '/ws/project/userProjects'
        getEvent              = 'moveEvent/listJson'
        
        Credential            = '/ws/credential' #/list, :id:
        getTasks              = '/ws/task'
        #includes Patch to update objects
        
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        
        
        ## Process ETL is now under one call -- Old no longer needed for v1
        ImportBatch           = '/ws/import/batch' #/list, :id:
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }

        ## Process ETL is now under one call:
        # scheduleImportAPIActionCommand

        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        # Adding Get, Set


        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        # Adding Get/Set
        
        
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        # Adding Get/Set

        
        Actions               = '/ws/apiAction'
        # Adding Get/Setup/Validates
        
        GetRecipe             = '/ws/cookbook/recipe'
        # Adding Get/Setup/Validates
        # Release, Clone
        
        GetDependency         = '/ws/asset/listDependencies'
        # Adding Get/Setup/Validates

    }
    '4.7.5' = @{
        
        signIn                = '/auth/signIn'
        ## Upgrading to API
        # setProject            = '/ws/project/viewEditProject/' + $ProjectId #get  Getting Depricated, API calls should include a project.id: assertion
        
        ## Needed
        Project               = '/ws/project/userProjects'
        getEvent              = 'moveEvent/listJson'
        
        Credential            = '/ws/credential' #/list, :id:
        getTasks              = '/ws/task'
        #includes Patch to update objects
        
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        
        
        ## Process ETL is now under one call -- Old no longer needed for v1
        ImportBatch           = '/ws/import/batch' #/list, :id:
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }

        ## Process ETL is now under one call:
        # scheduleImportAPIActionCommand

        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        # Adding Get, Set


        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        # Adding Get/Set
        
        
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        # Adding Get/Set

        
        Actions               = '/ws/apiAction'
        # Adding Get/Setup/Validates
        
        GetRecipe             = '/ws/cookbook/recipe'
        # Adding Get/Setup/Validates
        # Release, Clone
        
        GetDependency         = '/ws/asset/listDependencies'
        # Adding Get/Setup/Validates

    }
    '4.7.6' = @{
        
        signIn                = '/auth/signIn'
        ## Upgrading to API
        # setProject            = '/ws/project/viewEditProject/' + $ProjectId #get  Getting Depricated, API calls should include a project.id: assertion
        
        ## Needed
        Project               = '/ws/project/userProjects'
        getEvent              = 'moveEvent/listJson'
        
        Credential            = '/ws/credential' #/list, :id:
        getTasks              = '/ws/task'
        #includes Patch to update objects
        
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        
        
        ## Process ETL is now under one call -- Old no longer needed for v1
        ImportBatch           = '/ws/import/batch' #/list, :id:
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }

        ## Process ETL is now under one call:
        # scheduleImportAPIActionCommand

        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        # Adding Get, Set


        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        # Adding Get/Set
        
        
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        # Adding Get/Set

        
        Actions               = '/ws/apiAction'
        # Adding Get/Setup/Validates
        
        GetRecipe             = '/ws/cookbook/recipe'
        # Adding Get/Setup/Validates
        # Release, Clone
        
        GetDependency         = '/ws/asset/listDependencies'
        # Adding Get/Setup/Validates

    }
    '5.0.1' = @{
        
        signIn                = '/auth/signIn'
        ## Upgrading to API
        # setProject            = '/ws/project/viewEditProject/' + $ProjectId #get  Getting Depricated, API calls should include a project.id: assertion
        
        ## Needed
        Project               = '/ws/project/userProjects'
        getEvent              = 'moveEvent/listJson'
        
        Credential            = '/ws/credential' #/list, :id:
        getTasks              = '/ws/task'
        #includes Patch to update objects
        
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        
        
        ## Process ETL is now under one call -- Old no longer needed for v1
        ImportBatch           = '/ws/import/batch' #/list, :id:
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }

        ## Process ETL is now under one call:
        # scheduleImportAPIActionCommand

        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        # Adding Get, Set


        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        # Adding Get/Set
        
        
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        # Adding Get/Set

        
        Actions               = '/ws/apiAction'
        # Adding Get/Setup/Validates
        
        GetRecipe             = '/ws/cookbook/recipe'
        # Adding Get/Setup/Validates
        # Release, Clone
        
        GetDependency         = '/ws/asset/listDependencies'
        # Adding Get/Setup/Validates

    }
    '5.0.2' = @{
        
        signIn                = '/auth/signIn'
        ## Upgrading to API
        # setProject            = '/ws/project/viewEditProject/' + $ProjectId #get  Getting Depricated, API calls should include a project.id: assertion
        
        ## Needed
        Project               = '/ws/project/userProjects'
        getEvent              = 'moveEvent/listJson'
        
        Credential            = '/ws/credential' #/list, :id:
        getTasks              = '/ws/task'
        #includes Patch to update objects
        
        Provider              = '/ws/dataingestion/provider' #/list, :id:, validateUnique/:id:
        
        ETLScript             = '/ws/dataingestion/datascript' #/list, :id:
        ETLScriptSave         = '/ws/dataingestion/dataScript/saveScript'
        
        
        ## Process ETL is now under one call -- Old no longer needed for v1
        ImportBatch           = '/ws/import/batch' #/list, :id:
        FileSystem            = '/ws/fileSystem/uploadFileETLAssetImport'
        initiateTransformData = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/initiateTransformData"
            $uri += "?dataScriptId=" + $ETLScript.id
            $uri += "&filename=" + $ETLdataFileName
        }
        ETLProcess            = {
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/progress/" + $ETLProgressKey
        }
        LoadBatch             = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/assetImport/loadData?filename="
            $uri += $EtlOutputKey
        }
        BatchProgress         = {
            ## With the file uploaded, Initiate the ETL script on the server
            $uri = "https://"
            $uri += $instance
            $uri += "/tdstm/ws/import/batch/"
            $uri += $BatchId
            $uri += "/progress"
        }

        ## Process ETL is now under one call:
        # scheduleImportAPIActionCommand

        FieldSpecs            = '/ws/customDomain/fieldSpec/ASSETS'
        # Adding Get, Set


        GetAssetOptions       = '/assetEntity/assetOptions'
        SaveAssetOptions      = '/assetEntity/saveAssetoptions'
        # Adding Get/Set
        
        
        GetBundle             = '/ws/moveBundle/list'
        SaveBundle            = '/moveBundle/save'
        # Adding Get/Set

        
        Actions               = '/ws/apiAction'
        # Adding Get/Setup/Validates
        
        GetRecipe             = '/ws/cookbook/recipe'
        # Adding Get/Setup/Validates
        # Release, Clone
        
        GetDependency         = '/ws/asset/listDependencies'
        # Adding Get/Setup/Validates

    }
}

Function Invoke-ResponseHandling {
    [CmdletBinding()]
    param (
        # TransitionManager Server Hostname/URL
        [Parameter(Mandatory = $false)]
        [String]
        $Server = $global:TMSessions[$TMSession].TMServer,

        # TransitionManager Server Sofware Version
        [Parameter(Mandatory = $false)]
        [String]
        $TMVersion = $global:TMSessions[$TMSession].TMVersion,

        # Connection Protocol
        [Parameter(Mandatory = $false)]
        [String]
        $Protocol = 'https',

        # HandlerName Name
        [Parameter(Mandatory = $true)]
        [String]
        $HandlerName

    )
    
    return Invoke-Command -ScriptBlock $TMApiResponseHandlers[$TMVersion].($HandlerName) -NoNewScope

}
function Get-TMEndpointUri {
    [CmdletBinding()]
    param (
        # TransitionManager Server Hostname/URL
        [Parameter(Mandatory = $false)]
        [String]
        $Server = $global:TMSessions[$TMSession].TMServer,

        # TransitionManager Server Sofware Version
        [Parameter(Mandatory = $false)]
        [String]
        $TMVersion = $global:TMSessions[$TMSession].TMVersion,

        # Connection Protocol
        [Parameter(Mandatory = $false)]
        [String]
        $Protocol = 'https',

        # Endpoint Name
        [Parameter(Mandatory = $true)]
        [String]
        $EndpointName

    )
    
    begin {
        if (-not $TMVersion) {
            $TMVersion = Get-TMVersion -Server $Server
            if (-not $TMVersion) {
                Write-Host "Unable to proceed determine server version."
                break
            }
        }
    }
    
    process {
        try {
            ## Start with the Protocol/Schema
            $uri = switch ($Protocol) {
                'http' { 'http://' }
                'https' { 'https://' }
                Default {
                    Write-Host 'unknown protocol': $Protocol
                    ThrowError "Unknown Protocol: $Protocol"
                    break
                }
            }

            # Add the Server Hostname
            $instance = $Server.Replace('/tdstm', '')
            $instance = $instance.Replace('https://', '')
            $ServerHost = $instance.Replace('http://', '') 
            $uri += $ServerHost + '/tdstm'
    
            # Add the Module Path
            $uri += $TMApiEndpoints[$TMVersion].($EndpointName)
            return $uri
        } catch {
            Write-Host "Unable to construct endpoint for Version:$TMVersion, Endpoint:$EndpointName"
            return $false
        }
    }
    
    end {
    }
}