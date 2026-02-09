#Requires -Version 5.1 -Modules Hyper-V

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
    No Parameters

    [Info] Monitoring Hyper-V replication status...
    [Info] Checking 3 replica VM(s)...
    VM: Server01 | Status: Normal | Last Replication: 02/10/2026 00:45:00
    VM: Server02 | Status: Error | Last Replication: 02/09/2026 14:30:00
    [Alert] Replication errors detected on 1 VM(s)

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2 (Hyper-V Host)
    Release notes: Initial release for WAF v3.0
    Requires: Hyper-V role and Hyper-V PowerShell module
    
.COMPONENT
    Hyper-V - Windows Hyper-V management module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/hyper-v/

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
    [switch]$AlertOnWarning,
    [string]$SaveToCustomField
)

begin {
    if ($env:alertOnWarning -eq "true") {
        $AlertOnWarning = $true
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
}

process {
    try {
        Write-Host "[Info] Monitoring Hyper-V replication status..."
        
        $ReplicaVMs = Get-VMReplication -ErrorAction Stop

        if (-not $ReplicaVMs) {
            Write-Host "[Info] No replica VMs configured on this host"
            exit 0
        }

        Write-Host "[Info] Checking $($ReplicaVMs.Count) replica VM(s)...`n"
        
        $Report = @()
        $ErrorCount = 0
        $WarningCount = 0

        foreach ($VM in $ReplicaVMs) {
            $Status = $VM.Health
            $VMInfo = "VM: $($VM.VMName) | Status: $Status | Last Replication: $($VM.LastReplicationTime)"
            Write-Host $VMInfo
            $Report += $VMInfo

            if ($Status -eq "Critical" -or $Status -eq "Error") {
                $ErrorCount++
            }
            elseif ($Status -eq "Warning" -and $AlertOnWarning) {
                $WarningCount++
            }
        }

        if ($ErrorCount -gt 0) {
            Write-Host "`n[Alert] Replication errors detected on $ErrorCount VM(s)"
            $ExitCode = 1
        }
        elseif ($WarningCount -gt 0) {
            Write-Host "`n[Warn] Replication warnings detected on $WarningCount VM(s)"
            $ExitCode = 1
        }
        else {
            Write-Host "`n[Info] All replica VMs are healthy"
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Report saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to monitor Hyper-V replication: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
