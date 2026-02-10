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
    -SiteName "Default Web Site"

    [Info] Restarting IIS site 'Default Web Site'...
    [Info] Current state: Started
    [Info] Stopping site...
    [Info] Site stopped successfully
    [Info] Waiting 3 seconds...
    [Info] Starting site...
    [Info] Site started successfully
    [Info] Final state: Started

.EXAMPLE
    -SiteName "Contoso Web App" -WaitSeconds 5

    Waits 5 seconds between stop and start for thorough cleanup.

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2 with IIS role
    Release notes: Initial release for WAF v3.0
    Requires: WebAdministration PowerShell module, IIS role installed, administrator privileges
    
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
    
    [int]$WaitSeconds = 3,
    
    [switch]$VerifyState = $true
)

begin {
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
        Write-Host "[Info] Restarting IIS site '$SiteName'..."
        
        Import-Module WebAdministration -ErrorAction Stop
        
        $Site = Get-Website -Name $SiteName -ErrorAction Stop
        
        if (-not $Site) {
            Write-Host "[Error] Website '$SiteName' not found"
            exit 1
        }

        Write-Host "[Info] Current state: $($Site.State)"

        if ($Site.State -ne "Stopped") {
            Write-Host "[Info] Stopping site..."
            Stop-Website -Name $SiteName -ErrorAction Stop
            
            $Timeout = 30
            $Elapsed = 0
            while ((Get-Website -Name $SiteName).State -ne "Stopped" -and $Elapsed -lt $Timeout) {
                Start-Sleep -Seconds 1
                $Elapsed++
            }
            
            if ((Get-Website -Name $SiteName).State -eq "Stopped") {
                Write-Host "[Info] Site stopped successfully"
            } else {
                Write-Host "[Error] Site did not stop within timeout period"
                $ExitCode = 1
            }
        }

        Write-Host "[Info] Waiting $WaitSeconds seconds..."
        Start-Sleep -Seconds $WaitSeconds

        Write-Host "[Info] Starting site..."
        Start-Website -Name $SiteName -ErrorAction Stop
        
        $Timeout = 30
        $Elapsed = 0
        while ((Get-Website -Name $SiteName).State -ne "Started" -and $Elapsed -lt $Timeout) {
            Start-Sleep -Seconds 1
            $Elapsed++
        }

        $FinalState = (Get-Website -Name $SiteName).State
        Write-Host "[Info] Final state: $FinalState"

        if ($VerifyState -and $FinalState -ne "Started") {
            Write-Host "[Error] Site is not running after restart"
            $ExitCode = 1
        } else {
            Write-Host "[Info] Site restarted successfully"
        }
    }
    catch {
        Write-Host "[Error] Failed to restart site: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
