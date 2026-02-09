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
    -ThresholdPercent 10

    [Info] Monitoring DHCP scopes for utilization threshold: 10%
    [Alert] Scope 192.168.1.0: 5% available (245/250 addresses in use)
    [Info] Scope 192.168.2.0: 35% available (65/100 addresses in use)

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2
    Release notes: Initial release for WAF v3.0
    Requires: DHCP Server role and DhcpServer PowerShell module
    
.COMPONENT
    DhcpServer - Windows DHCP Server management module
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/dhcpserver/

.FUNCTIONALITY
    - Queries DHCP server scope statistics
    - Calculates percentage of available IP addresses
    - Alerts when utilization exceeds threshold
    - Reports scope ID, total addresses, used addresses, percentage available
    - Can save utilization report to custom fields
    - Supports monitoring all scopes or specific scope by ID
#>

[CmdletBinding()]
param(
    [int]$ThresholdPercent = 10,
    [string]$ScopeId,
    [string]$SaveToCustomField
)

begin {
    if ($env:thresholdPercent -and $env:thresholdPercent -notlike "null") {
        $ThresholdPercent = [int]$env:thresholdPercent
    }
    if ($env:scopeId -and $env:scopeId -notlike "null") {
        $ScopeId = $env:scopeId
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
        Write-Host "[Info] Monitoring DHCP scopes for utilization threshold: $ThresholdPercent%"
        
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
                Write-Host "[Alert] $ScopeInfo"
                $AlertTriggered = $true
            }
            else {
                Write-Host "[Info] $ScopeInfo"
            }
            
            $Report += $ScopeInfo
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

        if ($AlertTriggered) {
            $ExitCode = 1
        }
    }
    catch {
        Write-Host "[Error] Failed to monitor DHCP scopes: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
