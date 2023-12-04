<#
    Download-TMConsolePrequisites

    This script will download fresh versions of all TMConsole prerequisites

#>

$ProgressPreference = 'SilentlyContinue'

$ClearFolders = @(
    'PowerShell'
    'TMConsole'
    'VSCode'
)
foreach ($ClearFolder in $ClearFolders) {
    Get-ChildItem -Path $ClearFolder -Force -Recurse | Remove-Item -Force -Recurse
}

## Define the Versions of the resources required
$Versions = @{
    TMConsole                 = '2.5.2'
    PowerShell                = '7.3.9'
    VSCode                    = '1.84.2'
    VSCodePowerShellExtension = '2023.8.0'

    ## PowerShell Modules
    PSModules                 = @{
        'BAMCIS.Common'        = '1.0.4.0'
        'BAMCIS.Logging'       = '1.0.0.2'
        'PoshRSJob'            = '1.7.4.4'
        'Posh-SSH'             = '3.1.1'
        'PowerHTML'            = '0.1.7'
        'TMConsole.BrokerTask' = '2.0.0-foxtrot'
        'TMConsole.Caching'    = '1.1.0'
        'TMConsole.Client'     = '2.5.1'
        'TMD.Common'           = '2.5.2'
        'TransitionManager'    = '6.4.5'
    }
}

## Create a Download Queue
$DownloadQueue = [System.Collections.Queue]@()

## TMConsole
$DownloadQueue.Enqueue(
    @{
        Name      = 'TMConsole for Windows'
        URL       = "https://tm-nexus.transitionmanager.net/repository/tmd/installer/v$($Versions.TMConsole)/tmconsole-setup-$($Versions.TMConsole).exe"
        OutFolder = "TMConsole"
        OutFile   = "tmconsole-setup-$($Versions.TMConsole).exe"
    }
)

## PowerShell
$DownloadQueue.Enqueue(
    @{
        Name      = 'PowerShell for Windows, x64'
        URL       = "https://github.com/PowerShell/PowerShell/releases/download/v$($Versions.PowerShell)/PowerShell-$($Versions.PowerShell)-win-x64.msi"
        OutFolder = "PowerShell/"
        OutFile   = "PowerShell-$($Versions.PowerShell)-win-x64.msi"
    }
)

## VSCode
$DownloadQueue.Enqueue(
    @{
        Name      = 'VSCode System Installer for Windows x64'
        URL       = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        OutFolder = "VSCode"
        OutFile   = "VSCodeSetup-x64-$($Versions.VSCode).exe"
    }
)

## VSCode PowerShell Extension
$DownloadQueue.Enqueue(
    @{
        Name      = 'VSCode Extension - PowerShell'
        URL       = "https://github.com/PowerShell/vscode-powershell/releases/download/v$($Versions.VSCodePowerShellExtension)/powershell-$($Versions.VSCodePowerShellExtension).vsix"
        OutFolder = "VSCode"
        OutFile   = "ms-vscode.PowerShell-$($Versions.VSCodePowerShellExtension).vsix"
    }
)

## PowerShell Modules
foreach ($ModuleName in $Versions.PSModules.Keys) {
    $ModuleVersion = $Versions.PSModules.$ModuleName

    $DownloadQueue.Enqueue(
        @{
            Name      = "PS Module - $ModuleName"
            URL       = "https://www.powershellgallery.com/api/v2/package/$ModuleName/$ModuleVersion"
            OutFolder = "PowerShell/Modules"
            OutFile   = "$ModuleName.$ModuleVersion.nupkg"
        }
    )
}

##
## Run the Downloads
##
while ($DownloadQueue.Count) {

    $DownloadObject = $DownloadQueue.Dequeue()

    $OutFolderPath = Join-Path $PSScriptRoot $DownloadObject.OutFolder
    $OutFilePath = Join-Path $OutFolderPath $DownloadObject.OutFile
    Write-Host "Downloading File: " -NoNewline
    Write-Host $DownloadObject.Name -ForegroundColor Yellow

    Test-FolderPath $OutFolderPath
    Invoke-WebRequest -Uri $DownloadObject.URL -OutFile $OutFilePath

}
