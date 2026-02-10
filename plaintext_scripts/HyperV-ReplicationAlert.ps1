#Requires -Version 5.1

<#
.SYNOPSIS
    Monitors Hyper-V replica virtual machines and alerts on replication issues.

.DESCRIPTION
    This script queries Hyper-V replica virtual machines to check replication health status. 
    It identifies VMs with replication errors, warnings, or failed replication and alerts 
    administrators to prevent data loss.
    
    Hyper-V Replica provides disaster recovery capabilities. Failed replication can result in 
    data loss during failover events, making proactive monitoring essential.

.PARAMETER AlertOnWarning
    If specified, alerts on warning status in addition to errors.

.PARAMETER SaveToCustomField
    Name of a custom field to save the replication status report.

.EXAMPLE
    HyperV-ReplicationAlert.ps1
    
    Monitoring Hyper-V replication status...
    Checking 3 replica VM(s)...
    VM: Server01 | Status: Normal | Last Replication: 02/10/2026 00:45:00
    VM: Server02 | Status: Error | Last Replication: 02/09/2026 14:30:00
    Replication errors detected on 1 VM(s)

.EXAMPLE
    HyperV-ReplicationAlert.ps1 -AlertOnWarning
    
    Alerts on both errors and warnings.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : HyperV-ReplicationAlert.ps1
    Prerequisite   : PowerShell 5.1 or higher, Hyper-V role installed
    Requires       : Hyper-V PowerShell module
    Minimum OS     : Windows Server 2012 R2 (Hyper-V Host)
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
.COMPONENT
    Hyper-V - Windows Hyper-V management module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/hyper-v/get-vmreplication

.FUNCTIONALITY
    - Queries all replica VMs on Hyper-V host
    - Checks replication health status
    - Reports last replication time
    - Identifies VMs with replication errors or warnings
    - Can save replication status to custom fields
    - Alerts administrators to replication failures
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$AlertOnWarning,
    
    [Parameter()]
    [string]$SaveToCustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        Write-Output $logMessage
        
        if ($Level -eq 'ERROR') { $script:ErrorCount++ }
        if ($Level -eq 'WARNING') { $script:WarningCount++ }
    }

    function Set-NinjaField {
        <#
        .SYNOPSIS
            Sets NinjaRMM custom field with CLI fallback.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [AllowEmptyString()]
            [string]$Value
        )
        
        try {
            if (Get-Command 'Ninja-Property-Set-Piped' -ErrorAction SilentlyContinue) {
                $Value | Ninja-Property-Set-Piped -Name $Name
            }
            else {
                Write-Log "CLI fallback - Would set field '$Name' to: $Value" -Level 'INFO'
            }
        }
        catch {
            Write-Log "Failed to set custom field '$Name': $_" -Level 'ERROR'
            throw
        }
    }

    if ($env:alertOnWarning -eq 'true') {
        $AlertOnWarning = $true
    }
    
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike 'null') {
        $SaveToCustomField = $env:saveToCustomField
    }
}

process {
    try {
        if (-not (Get-Command 'Get-VMReplication' -ErrorAction SilentlyContinue)) {
            Write-Log 'Hyper-V module not found. Hyper-V role may not be installed' -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        Write-Log 'Monitoring Hyper-V replication status...'
        
        $ReplicaVMs = Get-VMReplication -ErrorAction Stop

        if (-not $ReplicaVMs) {
            Write-Log 'No replica VMs configured on this host'
            return
        }

        Write-Log "Checking $($ReplicaVMs.Count) replica VM(s)..."
        
        $Report = @()
        $ReplicationErrors = 0
        $ReplicationWarnings = 0

        foreach ($VM in $ReplicaVMs) {
            $Status = $VM.Health
            $VMInfo = "VM: $($VM.VMName) | Status: $Status | Last Replication: $($VM.LastReplicationTime)"
            
            if ($Status -eq 'Critical' -or $Status -eq 'Error') {
                Write-Log $VMInfo -Level 'ERROR'
                $ReplicationErrors++
            }
            elseif ($Status -eq 'Warning') {
                if ($AlertOnWarning) {
                    Write-Log $VMInfo -Level 'WARNING'
                    $ReplicationWarnings++
                }
                else {
                    Write-Log $VMInfo
                }
            }
            else {
                Write-Log $VMInfo
            }
            
            $Report += $VMInfo
        }

        if ($ReplicationErrors -gt 0) {
            Write-Log "Replication errors detected on $ReplicationErrors VM(s)" -Level 'ERROR'
            $script:ExitCode = 1
        }
        elseif ($ReplicationWarnings -gt 0) {
            Write-Log "Replication warnings detected on $ReplicationWarnings VM(s)" -Level 'WARNING'
            $script:ExitCode = 1
        }
        else {
            Write-Log 'All replica VMs are healthy'
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaField -Name $SaveToCustomField
                Write-Log "Report saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Log "Failed to save to custom field: $_" -Level 'ERROR'
                $script:ExitCode = 1
            }
        }
    }
    catch {
        Write-Log "Failed to monitor Hyper-V replication: $_" -Level 'ERROR'
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output "`n========================================"
        Write-Output "Execution Summary"
        Write-Output "========================================"
        Write-Output "Script: HyperV-ReplicationAlert.ps1"
        Write-Output "Duration: $Duration seconds"
        Write-Output "Errors: $script:ErrorCount"
        Write-Output "Warnings: $script:WarningCount"
        Write-Output "Exit Code: $script:ExitCode"
        Write-Output "========================================"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
