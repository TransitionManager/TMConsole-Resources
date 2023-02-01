
Function Invoke-TMDPsExec {
    param(
        [CmdletBinding()]
        [Parameter(mandatory = $true)][String]$ComputerName,
        [Parameter(mandatory = $true)][pscredential]$Credential,
        [Parameter(mandatory = $false)][String]$Command,
        [Parameter(mandatory = $false)]$CommandArguments,
        [Parameter(mandatory = $false)]$Script,
        [Parameter(mandatory = $false)][Switch]$Console,
        [Parameter(mandatory = $false)][Switch]$PassThru,
        [Parameter(mandatory = $false)][Switch]$UseSystemAccount,
        [Parameter(mandatory = $false)][string]$CommandDelimiter = ';',
        [Parameter(mandatory = $false)][String]$PsSuitePath = 'C:\TMConsole\SysinternalsSuite'
    )
    Begin {
        
        ## Test if PsExec is installed
        $PsExecPath = Join-Path $PsSuitePath 'psexec.exe'
        $PsExeFileExists = Test-Path -Path $PsExecPath

        if (-Not $PsExeFileExists) {
            Throw "PSExec is not installed at $($PsSuitePath). Install there, or use the -PsSuitePath Parameter to define the copy to use."
        }

        ## A Script may have been provided, convert it into a single line command.
        if ($Script -and -not $Command) {
            $Commands = [System.Text.StringBuilder]::new()
            $Script.Values | ForEach-Object {
                [void]$Commands.Append($_)
                [void]$Commands.Append($CommandDelimiter)
            }
            $Command = $Commands.ToString()
        }
    }
    
    Process {
        
        # Make sure this is Windows
        if (-not $isWindows) {
            Throw 'Running PsExec Commands are only supported when running on Windows.'
        }
        
        ## Create an ArgumentList for the PsExec Command
        $PsExecArguments = @()
        $PsExecArguments += "\\$ComputerName"       ## Computer Name to connect to
        if ($UseSystemAccount) {                      
            $PsExecArguments += '-s'                ## Run as the System Account
        }
        $PsExecArguments += '-h'                    ## Request User Account Control admin permissions
        if ($Credential) {
            $PsExecArguments += '-u'                    ## Supply Username
            $PsExecArguments += $Credential.UserName
            $PsExecArguments += '-p'                    ## Supply Password
            $PsExecArguments += '"' + $Credential.GetNetworkCredential().Password + '"'
        }
        $PsExecArguments += '-r TMConsole-PsExec'         ## Use a Named Service Session
        $PsExecArguments += '-nobanner'             ## Suppress the Banner
        $PsExecArguments += '-accepteula'           ## Accept the EULA to prevent a dialog
        $PsExecArguments += $Command                ## Supply the command to run   
        if ($CommandArguments) {
            ## And optional arguments
            $PsExecArguments += $CommandArguments
        }
        
        ## StartProcess Options
        $PsExecProcessSplat = @{
            FilePath      = $PsExecPath
            ArgumentList  = $PsExecArguments
            Wait          = $True
            # NoNewWindow = $true
            WindowStyle   = 'Minimized'
            ErrorAction   = 'SilentlyContinue'
            WarningAction = 'SilentlyContinue'   
        }
        
        ## PsExec output's Its StdOut on the StdErr channel so the inside SSH content can be delivered to StdOut
        ## This requires altering the Error Action Preference to Continue (so the output can be red as well as saved)
        $ExistingErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'

        ## Starting the process may involve Writing to the console, or not.
        $StdOutTempFile = New-TemporaryFile
        Start-Process @PsExecProcessSplat -RedirectStandardOutput $StdOutTempFile.FullName
        $PsExecOutput = Get-Content $StdOutTempFile.FullName
        Remove-Item $StdOutTempFile.FullName -Force

        if ($Console) {
            $PsExecOutput | Write-Host             
        }

        ## Return Error Preference Setting
        $ErrorActionPreference = $ExistingErrorAction

    }
                            
    End {

        ## Return the Session Standard Output
        if ($PassThru) {
            return $PsExecOutput
        }
    }
}


## Process.Start Constructor Method for starting exe
## Create a Process object (and a fuction level cache) and use Std<Out|Err> handlers + rediretion
## Create a Cache to return only appropriate objects back
# $ProcessOutputCache = @{
#     StdOut = @()
#     StdErr = @()
# }
        
## Construct a new ProcessStartInfo object
# $psi = New-Object System.Diagnostics.ProcessStartInfo
# $psi.CreateNoWindow = $true
#     # $psi.UseShellExecute = $false
#     # $psi.RedirectStandardOutput = $true
#     # $psi.RedirectStandardError = $true
# $psi.UseShellExecute = $true
# $psi.FileName = $PsExec
# $psi.Arguments = $PsExecArguments
        
# ## Invoke the Process Invocation using the StartInfo object
# $Process = New-Object System.Diagnostics.Process
# $Process.StartInfo = $psi
        
# ## Define and Register Standard Output Handler
# $StdOutHandler = {
#     param([Object]$sender, [DataReceivedEventArgs]$e) 
#     if ($ProcessOutputCache.StdOut -notcontains $e) {
#         Write-Host $e
#         $ProcessOutputCache.StdOut += $e
#     }
# }
# Register-ObjectEvent -InputObject $Process -Action $StdOutHandler -EventName 'OutputDataReceived' # | Out-Null
        
# ## Define and Register Standard Error Handler
# $StdErrHandler = {
#     param([Object]$sender, [DataReceivedEventArgs]$e) 
#     if ($ProcessOutputCache.StdErr -notcontains $e) {
#         Write-Host $e
#         $ProcessOutputCache.StdErr += $e
#     }
# }
# Register-ObjectEvent -InputObject $Process -Action $StdErrHandler -EventName 'ErrorDataReceived' # | Out-Null


## Start the process, but don't return anything
# [void]$Process.Start()

## Invoke Output Handlers
# $Process.BeginOutputReadLine()
# $Process.BeginErrorReadLine()
    
## Wait until the process exits before returning control
# $Process.WaitForExit()

## Return Error Handling to the state it as in before this function ran
        
        
## PsExec exits with 'code 0.' as it's last line upon success.
# $LastLine = $FullStdOut | Select-Object -Last 1
# if ($LastLine.SubString($LastLine.length - 7, 7) -ne 'code 0.') {
#     Write-Progress -Id 30 -ParentId 0 -Activity 'Installation Complete' -PercentComplete 100 -Completed
#     Throw "PsExec Script Exited abnormally. Please review the log."
# }