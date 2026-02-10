#Requires -Version 5.1 -Modules WebAdministration

<#
.SYNOPSIS
    Restarts a specified IIS website.

.DESCRIPTION
    This script stops and starts an IIS website to force a complete restart. It provides detailed
    status reporting including current state verification, stop/start operations, and final state
    confirmation.
    
    Restarting IIS websites is useful for applying configuration changes, resolving connection
    issues, or clearing problematic sessions.

.PARAMETER SiteName
    Name of the IIS website to restart. Required.

.PARAMETER WaitSeconds
    Number of seconds to wait between stop and start operations. Default: 3 seconds

.PARAMETER VerifyState
    If specified, verifies the site is actually running after restart. Default: True

.EXAMPLE
    .\IIS-RestartSite.ps1 -SiteName "Default Web Site"
    
    Restarting IIS site 'Default Web Site'...
    Current state: Started
    Stopping site...
    Site stopped successfully
    Waiting 3 seconds...
    Starting site...
    Final state: Started

.EXAMPLE
    .\IIS-RestartSite.ps1 -SiteName "Contoso Web App" -WaitSeconds 5
    
    Waits 5 seconds between stop and start for thorough cleanup.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : IIS-RestartSite.ps1
    Prerequisite   : PowerShell 5.1 or higher, IIS role installed, WebAdministration module
    Requires       : Administrator privileges
    Minimum OS     : Windows Server 2012 R2 with IIS role
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
.COMPONENT
    WebAdministration - IIS management PowerShell module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/webadministration/

.FUNCTIONALITY
    - Restarts specified IIS website
    - Verifies current state before restart
    - Stops website gracefully
    - Waits specified time for cleanup
    - Starts website
    - Verifies final running state
    - Provides detailed operation status
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SiteName,
    
    [Parameter()]
    [int]$WaitSeconds = 3,
    
    [Parameter()]
    [switch]$VerifyState = $true
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Output $logMessage }
        }
    }

    if ($env:siteName -and $env:siteName -notlike "null") {
        $SiteName = $env:siteName
    }
    if ($env:waitSeconds -and $env:waitSeconds -notlike "null") {
        $WaitSeconds = [int]$env:waitSeconds
    }
    if ($env:verifyState -eq "false") {
        $VerifyState = $false
    }

    $ExitCode = 0
}

process {
    try {
        Write-Log "Restarting IIS site '$SiteName'..."
        
        Import-Module WebAdministration -ErrorAction Stop
        
        $Site = Get-Website -Name $SiteName -ErrorAction Stop
        
        if (-not $Site) {
            throw "Website '$SiteName' not found"
        }

        Write-Log "Current state: $($Site.State)"

        if ($Site.State -ne "Stopped") {
            Write-Log "Stopping site..."
            Stop-Website -Name $SiteName -ErrorAction Stop
            
            $Timeout = 30
            $Elapsed = 0
            while ((Get-Website -Name $SiteName).State -ne "Stopped" -and $Elapsed -lt $Timeout) {
                Start-Sleep -Seconds 1
                $Elapsed++
            }
            
            if ((Get-Website -Name $SiteName).State -eq "Stopped") {
                Write-Log "Site stopped successfully"
            } else {
                Write-Log "Site did not stop within timeout period" -Level ERROR
                $ExitCode = 1
            }
        }

        Write-Log "Waiting $WaitSeconds seconds..."
        Start-Sleep -Seconds $WaitSeconds

        Write-Log "Starting site..."
        Start-Website -Name $SiteName -ErrorAction Stop
        
        $Timeout = 30
        $Elapsed = 0
        while ((Get-Website -Name $SiteName).State -ne "Started" -and $Elapsed -lt $Timeout) {
            Start-Sleep -Seconds 1
            $Elapsed++
        }

        $FinalState = (Get-Website -Name $SiteName).State
        Write-Log "Final state: $FinalState"

        if ($VerifyState -and $FinalState -ne "Started") {
            Write-Log "Site is not running after restart" -Level ERROR
            $ExitCode = 1
        } else {
            Write-Log "Site restarted successfully"
        }
    }
    catch {
        Write-Log "Failed to restart site: $_" -Level ERROR
        $ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $Duration seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
