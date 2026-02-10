#Requires -Version 5.1 -Modules DhcpServer

<#
.SYNOPSIS
    Monitors DHCP scope utilization and alerts when available leases are low.

.DESCRIPTION
    This script queries DHCP server scopes to determine current IP address utilization and alerts 
    administrators when the percentage of available addresses falls below a specified threshold. 
    This proactive monitoring prevents DHCP exhaustion issues.
    
    DHCP scope exhaustion can prevent new devices from obtaining IP addresses, causing network 
    connectivity failures. Early warning allows administrators to expand scopes or reclaim unused 
    addresses before service disruption occurs.

.PARAMETER ThresholdPercent
    Alert threshold percentage for available addresses. Default: 10 (alert when < 10% available)

.PARAMETER ScopeId
    Specific DHCP scope ID to monitor. If not specified, monitors all scopes.

.PARAMETER SaveToCustomField
    Name of a custom field to save the DHCP utilization report.

.EXAMPLE
    .\DHCP-AlertOnLeaseLow.ps1 -ThresholdPercent 10
    
    Monitoring DHCP scopes for utilization threshold: 10%
    Scope 192.168.1.0: 5% available (245/250 addresses in use)

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : DHCP-AlertOnLeaseLow.ps1
    Prerequisite   : PowerShell 5.1 or higher, DHCP Server role, DhcpServer module
    Minimum OS     : Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3.0.0 standards (script-scoped exit code)
    - 1.0: Initial release
    
.COMPONENT
    DhcpServer - Windows DHCP Server management module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/dhcpserver/
#>

[CmdletBinding()]
param(
    [Parameter()]
    [int]$ThresholdPercent = 10,
    
    [Parameter()]
    [string]$ScopeId,
    
    [Parameter()]
    [string]$SaveToCustomField
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

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        
        try {
            $CustomField = $Value | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            Write-Log "Failed to set custom field: $_" -Level ERROR
            throw
        }
    }

    if ($env:thresholdPercent -and $env:thresholdPercent -notlike "null") {
        $ThresholdPercent = [int]$env:thresholdPercent
    }
    if ($env:scopeId -and $env:scopeId -notlike "null") {
        $ScopeId = $env:scopeId
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    $script:ExitCode = 0
}

process {
    try {
        Write-Log "Monitoring DHCP scopes for utilization threshold: $ThresholdPercent%"
        
        if ($ScopeId) {
            $Scopes = Get-DhcpServerv4Scope -ScopeId $ScopeId -ErrorAction Stop
        }
        else {
            $Scopes = Get-DhcpServerv4Scope -ErrorAction Stop
        }

        $Report = @()
        $AlertTriggered = $false

        foreach ($Scope in $Scopes) {
            $Stats = Get-DhcpServerv4ScopeStatistics -ScopeId $Scope.ScopeId -ErrorAction Stop
            
            $TotalAddresses = $Stats.AddressesFree + $Stats.AddressesInUse
            if ($TotalAddresses -gt 0) {
                $PercentAvailable = [Math]::Round(($Stats.AddressesFree / $TotalAddresses) * 100, 2)
            }
            else {
                $PercentAvailable = 0
            }

            $ScopeInfo = "Scope $($Scope.ScopeId): $PercentAvailable% available ($($Stats.AddressesInUse)/$TotalAddresses addresses in use)"
            
            if ($PercentAvailable -lt $ThresholdPercent) {
                Write-Log $ScopeInfo -Level WARNING
                $AlertTriggered = $true
            }
            else {
                Write-Log $ScopeInfo
            }
            
            $Report += $ScopeInfo
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Log "Report saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Log "Failed to save to custom field: $_" -Level ERROR
                $script:ExitCode = 1
            }
        }

        if ($AlertTriggered) {
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Log "Failed to monitor DHCP scopes: $_" -Level ERROR
        $script:ExitCode = 1
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
        exit $script:ExitCode
    }
}
