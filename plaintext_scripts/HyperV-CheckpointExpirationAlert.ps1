#Requires -Version 5.1

<#
.SYNOPSIS
    Monitors Hyper-V VM checkpoints and alerts on old checkpoints.

.DESCRIPTION
    This script scans all Hyper-V virtual machines for checkpoints (snapshots) and identifies
    any that are older than a specified threshold. Old checkpoints can consume significant
    disk space and may indicate forgotten test environments or pending cleanup tasks.
    
    Checkpoints should typically be short-lived. Long-lasting checkpoints can impact VM
    performance, consume storage, and complicate backup operations.

.PARAMETER OlderThan
    Number of days to use as the age threshold for checkpoints.
    Default: 0 (reports all checkpoints)

.PARAMETER FromCustomField
    Name of an integer custom field containing the age threshold in days.
    Overrides the OlderThan parameter if provided.

.PARAMETER SaveToCustomField
    Name of custom field to save checkpoint report to.

.EXAMPLE
    HyperV-CheckpointExpirationAlert.ps1
    
    Reports all VM checkpoints on the system.

.EXAMPLE
    HyperV-CheckpointExpirationAlert.ps1 -OlderThan 7
    
    Alerts on VM checkpoints older than 7 days.

.EXAMPLE
    HyperV-CheckpointExpirationAlert.ps1 -FromCustomField "CheckpointAgeLimit"
    
    Retrieves age threshold from custom field and reports old checkpoints.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : HyperV-CheckpointExpirationAlert.ps1
    Prerequisite   : PowerShell 5.1 or higher, Hyper-V role installed
    Requires       : Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.1: Renamed script and added Script Variable support
    - 1.0: Initial release
    
.COMPONENT
    Hyper-V - Virtual machine checkpoint management
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/hyper-v/get-vmsnapshot

.FUNCTIONALITY
    - Scans all Hyper-V VMs for checkpoints
    - Identifies checkpoints older than specified threshold
    - Reports VM name, checkpoint name, and creation time
    - Can save report to custom fields
    - Exits with error code if old checkpoints found
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$OlderThan = 0,
    
    [Parameter()]
    [string]$FromCustomField,
    
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

    function Test-IsElevated {
        <#
        .SYNOPSIS
            Tests if script is running with administrator privileges.
        #>
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsSystem {
        <#
        .SYNOPSIS
            Tests if script is running as SYSTEM account.
        #>
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    if ($env:ageLimit -and $env:ageLimit -notlike 'null') {
        $OlderThan = [int]$env:ageLimit
    }
    
    if ($env:retrieveAgeLimitFromCustomField -and $env:retrieveAgeLimitFromCustomField -notlike 'null') {
        $FromCustomField = $env:retrieveAgeLimitFromCustomField
    }
    
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike 'null') {
        $SaveToCustomField = $env:saveToCustomField
    }
}

process {
    try {
        if (-not (Test-IsElevated) -and -not (Test-IsSystem)) {
            Write-Log 'Access Denied. Please run with Administrator privileges' -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        if (-not (Get-Command 'Get-VM' -ErrorAction SilentlyContinue)) {
            Write-Log 'Hyper-V module not found. Hyper-V role may not be installed' -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        if ($FromCustomField) {
            try {
                $CustomAge = Ninja-Property-Get $FromCustomField 2>$null
                if ($CustomAge) {
                    $OlderThan = [int]$CustomAge
                    Write-Log "Using age threshold from custom field: $OlderThan days"
                }
            }
            catch {
                Write-Log "Failed to retrieve threshold from custom field '$FromCustomField'" -Level 'WARNING'
            }
        }

        $Threshold = (Get-Date).AddDays(-$OlderThan)
        Write-Log "Scanning for VM checkpoints older than $Threshold"

        $VMs = Get-VM -ErrorAction Stop
        
        if (-not $VMs) {
            Write-Log 'No virtual machines found on this system'
            return
        }

        Write-Log "Found $($VMs.Count) virtual machine(s), checking for old checkpoints..."
        
        $Checkpoints = Get-VM | Get-VMSnapshot -ErrorAction SilentlyContinue | Where-Object {
            $_.CreationTime -lt $Threshold
        }

        if (-not $Checkpoints) {
            Write-Log "No checkpoints older than $Threshold found"
        }
        else {
            Write-Log "Found $($Checkpoints.Count) checkpoint(s) older than $Threshold" -Level 'WARNING'
            
            $Report = @()
            foreach ($CP in $Checkpoints) {
                $Info = "VM: $($CP.VMName) | Checkpoint: $($CP.Name) | Created: $($CP.CreationTime)"
                Write-Log $Info -Level 'WARNING'
                $Report += $Info
            }

            if ($SaveToCustomField) {
                try {
                    $Report -join "; " | Set-NinjaField -Name $SaveToCustomField
                    Write-Log "Report saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Log "Failed to save to custom field: $_" -Level 'ERROR'
                }
            }
            
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Log "Failed to check VM checkpoints: $_" -Level 'ERROR'
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
        Write-Output "Script: HyperV-CheckpointExpirationAlert.ps1"
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
