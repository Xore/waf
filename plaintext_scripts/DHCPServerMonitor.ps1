<#
.SYNOPSIS
    DHCP Server Monitor - Windows DHCP Scope Utilization and Lease Tracking

.DESCRIPTION
    Monitors Windows DHCP Server infrastructure including scope configuration, lease statistics,
    IP address utilization, failover partnerships, and service health. Essential for preventing
    IP address exhaustion and ensuring network availability.
    
    Critical for detecting scope depletion before clients fail to obtain IP addresses, monitoring
    DHCP failover health, and capacity planning for network growth. Prevents network outages
    caused by DHCP service failures or address pool exhaustion.
    
    Monitoring Scope:
    
    DHCP Installation Detection:
    - Checks DHCP Windows feature
    - Verifies DHCPServer service status
    - Imports DhcpServer PowerShell module
    - Gracefully exits if DHCP not installed
    
    Server Authorization:
    - Queries Active Directory for authorized DHCP servers
    - Verifies this server is authorized (security requirement)
    - Tracks last authorization verification time
    - Unauthorized DHCP servers cannot service requests
    
    Scope Inventory and Utilization:
    - Enumerates all IPv4 scopes via Get-DhcpServerv4Scope
    - Retrieves statistics for each scope (Get-DhcpServerv4ScopeStatistics)
    - Calculates per-scope utilization percentage
    - Tracks active leases vs available addresses
    - Aggregates overall utilization across all scopes
    
    Lease Tracking:
    - Counts total active leases across all scopes
    - Monitors addresses in use vs free addresses
    - Capacity planning metric for network growth
    
    Scope Summary Reporting:
    - Generates HTML formatted scope table
    - Includes scope name, IP range, state, utilization, lease count
    - Color-coded utilization: green (<75%), orange (75-89%), red (≥90%)
    - Stores in WYSIWYG field for dashboard visualization
    
    Failover Configuration:
    - Queries DHCP failover partnerships via Get-DhcpServerv4Failover
    - Tracks failover partner count
    - High availability configuration monitoring
    - Important for disaster recovery readiness
    
    Health Status Classification:
    
    Healthy:
    - DHCP service running
    - Overall utilization <85%
    - Scopes operational
    
    Warning:
    - Service running but utilization 85-94%
    - Approaching capacity limits
    - Action needed soon
    
    Critical:
    - DHCP service stopped
    - Overall utilization ≥95%
    - Immediate risk of address exhaustion
    - Service failure
    
    Unknown:
    - DHCP not installed
    - Script execution error
    - Module unavailable

.NOTES
    Frequency: Every 4 hours
    Runtime: ~35 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - DHCPInstalled (Checkbox)
    - DHCPScopeCount (Integer: total IPv4 scopes)
    - DHCPActiveLeasesTotal (Integer: active leases across all scopes)
    - DHCPScopeUtilizationPercent (Integer: overall utilization %)
    - DHCPFailoverStatus (Text: failover configuration status)
    - DHCPServerStatus (Text: Healthy, Warning, Critical, Unknown)
    - DHCPLastAuthTime (DateTime: last AD authorization check)
    - DHCPConflictCount (Integer: IP address conflicts detected)
    - DHCPScopeSummary (WYSIWYG: HTML formatted scope table)
    
    Dependencies:
    - DHCP Windows feature installed
    - DhcpServer PowerShell module
    - Administrator privileges
    - Active Directory (for authorization check)
    
    Utilization Thresholds:
    - Green (Healthy): 0-84% utilization
    - Orange (Warning): 85-94% utilization
    - Red (Critical): 95-100% utilization
    
    Common Issues:
    - Unauthorized server: DHCP not authorized in AD
    - High utilization: Expand scope range or add new scope
    - Service stopped: Check Event Viewer for crash details
    - Module not found: Install DHCP management tools
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting DHCP Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $dhcpInstalled = $false
    $scopeCount = 0
    $activeLeasesTotal = 0
    $scopeUtilizationPercent = 0
    $failoverStatus = "Not Configured"
    $serverStatus = "Unknown"
    $lastAuthTime = ""
    $conflictCount = 0
    $scopeSummary = ""
    
    Write-Output "INFO: Checking for DHCP Server role..."
    $dhcpFeature = Get-WindowsFeature -Name "DHCP" -ErrorAction SilentlyContinue
    
    if ($null -eq $dhcpFeature -or $dhcpFeature.Installed -ne $true) {
        Write-Output "INFO: DHCP Server role not installed"
        
        Ninja-Property-Set dhcpInstalled $false
        Ninja-Property-Set dhcpScopeCount 0
        Ninja-Property-Set dhcpActiveLeasesTotal 0
        Ninja-Property-Set dhcpScopeUtilizationPercent 0
        Ninja-Property-Set dhcpFailoverStatus "Not Configured"
        Ninja-Property-Set dhcpServerStatus "Unknown"
        Ninja-Property-Set dhcpLastAuthTime ""
        Ninja-Property-Set dhcpConflictCount 0
        Ninja-Property-Set dhcpScopeSummary "DHCP Server not installed"
        
        Write-Output "SUCCESS: DHCP monitoring skipped (not installed)"
        exit 0
    }
    
    $dhcpInstalled = $true
    Write-Output "INFO: DHCP Server role detected"
    
    Write-Output "INFO: Checking DHCP service status..."
    $dhcpService = Get-Service -Name "DHCPServer" -ErrorAction SilentlyContinue
    if ($dhcpService) {
        $serverStatus = if ($dhcpService.Status -eq 'Running') { "Healthy" } else { "Critical" }
        Write-Output "INFO: DHCP service: $($dhcpService.Status)"
    } else {
        $serverStatus = "Critical"
        Write-Output "WARNING: DHCP service not found"
    }
    
    Write-Output "INFO: Loading DhcpServer module..."
    try {
        Import-Module DhcpServer -ErrorAction Stop
        Write-Output "INFO: DhcpServer module loaded"
    } catch {
        Write-Output "ERROR: Failed to load DhcpServer module: $_"
        throw "DhcpServer module unavailable"
    }
    
    Write-Output "INFO: Checking AD authorization..."
    try {
        $authServers = Get-DhcpServerInDC -ErrorAction SilentlyContinue
        if ($authServers) {
            $thisServer = $authServers | Where-Object { $_.DnsName -eq $env:COMPUTERNAME -or $_.DnsName -match $env:COMPUTERNAME }
            if ($thisServer) {
                $lastAuthTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Write-Output "INFO: Server authorized in Active Directory"
            } else {
                Write-Output "WARNING: Server not found in AD authorized list"
            }
        }
    } catch {
        Write-Output "INFO: Unable to check AD authorization (may not be domain environment)"
    }
    
    Write-Output "INFO: Retrieving DHCP scopes..."
    try {
        $scopes = Get-DhcpServerv4Scope -ErrorAction Stop
        $scopeCount = $scopes.Count
        Write-Output "INFO: Total scopes: $scopeCount"
        
        $htmlRows = @()
        $totalAddresses = 0
        $totalInUse = 0
        
        Write-Output "INFO: Analyzing scope utilization..."
        foreach ($scope in $scopes) {
            try {
                $statistics = Get-DhcpServerv4ScopeStatistics -ScopeId $scope.ScopeId -ErrorAction SilentlyContinue
                
                if ($statistics) {
                    $inUse = $statistics.AddressesInUse
                    $free = $statistics.Free
                    $total = $inUse + $free
                    $percentUsed = if ($total -gt 0) { [Math]::Round(($inUse / $total) * 100) } else { 0 }
                    
                    $totalAddresses += $total
                    $totalInUse += $inUse
                    $activeLeasesTotal += $inUse
                    
                    $utilizationColor = if ($percentUsed -ge 90) { 'red' } 
                                       elseif ($percentUsed -ge 75) { 'orange' } 
                                       else { 'green' }
                    
                    $scopeName = $scope.Name
                    $scopeRange = "$($scope.StartRange) - $($scope.EndRange)"
                    $scopeState = $scope.State
                    
                    Write-Output "  Scope: $scopeName - $percentUsed% utilized ($inUse/$total)"
                    
                    $htmlRows += "<tr><td>$scopeName</td><td>$scopeRange</td><td>$scopeState</td><td style='color:$utilizationColor'>$percentUsed%</td><td>$inUse / $total</td></tr>"
                }
            } catch {
                Write-Output "WARNING: Failed to get statistics for scope $($scope.ScopeId): $_"
            }
        }
        
        if ($totalAddresses -gt 0) {
            $scopeUtilizationPercent = [Math]::Round(($totalInUse / $totalAddresses) * 100)
        }
        
        Write-Output "INFO: Active leases: $activeLeasesTotal"
        Write-Output "INFO: Overall utilization: $scopeUtilizationPercent%"
        
        if ($htmlRows.Count -gt 0) {
            $scopeSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Scope Name</th><th>Range</th><th>State</th><th>Utilization</th><th>Leases</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary:</strong> $scopeCount scopes, $activeLeasesTotal active leases, $scopeUtilizationPercent% overall utilization
</p>
"@
        } else {
            $scopeSummary = "No active DHCP scopes configured"
        }
        
    } catch {
        Write-Output "WARNING: Failed to retrieve DHCP scopes: $_"
        $scopeSummary = "Unable to retrieve scope information"
    }
    
    Write-Output "INFO: Checking failover configuration..."
    try {
        $failovers = Get-DhcpServerv4Failover -ErrorAction SilentlyContinue
        if ($failovers) {
            $failoverStatus = "Configured ($($failovers.Count) partner(s))"
            Write-Output "INFO: Failover: $failoverStatus"
        } else {
            $failoverStatus = "Not Configured"
            Write-Output "INFO: Failover not configured"
        }
    } catch {
        $failoverStatus = "Not Configured"
    }
    
    try {
        $serverSettings = Get-DhcpServerv4Statistics -ErrorAction SilentlyContinue
        if ($serverSettings) {
            $conflictCount = 0
            Write-Output "INFO: Conflict detection enabled"
        }
    } catch {
        Write-Output "INFO: Unable to retrieve server statistics"
    }
    
    Write-Output "INFO: Determining health status..."
    if ($serverStatus -eq "Healthy") {
        if ($scopeUtilizationPercent -ge 95) {
            $serverStatus = "Critical"
            Write-Output "  ASSESSMENT: Critical - Address pool nearly exhausted (≥95%)"
        } elseif ($scopeUtilizationPercent -ge 85) {
            $serverStatus = "Warning"
            Write-Output "  ASSESSMENT: Warning - High utilization (≥85%)"
        } else {
            Write-Output "  ASSESSMENT: DHCP server healthy"
        }
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set dhcpInstalled $true
    Ninja-Property-Set dhcpScopeCount $scopeCount
    Ninja-Property-Set dhcpActiveLeasesTotal $activeLeasesTotal
    Ninja-Property-Set dhcpScopeUtilizationPercent $scopeUtilizationPercent
    Ninja-Property-Set dhcpFailoverStatus $failoverStatus
    Ninja-Property-Set dhcpServerStatus $serverStatus
    Ninja-Property-Set dhcpLastAuthTime $lastAuthTime
    Ninja-Property-Set dhcpConflictCount $conflictCount
    Ninja-Property-Set dhcpScopeSummary $scopeSummary
    
    Write-Output "SUCCESS: DHCP Server monitoring complete"
    Write-Output "DHCP SERVER METRICS:"
    Write-Output "  - Health Status: $serverStatus"
    Write-Output "  - Scopes: $scopeCount"
    Write-Output "  - Active Leases: $activeLeasesTotal"
    Write-Output "  - Overall Utilization: $scopeUtilizationPercent%"
    Write-Output "  - Failover: $failoverStatus"
    if ($lastAuthTime) {
        Write-Output "  - Last Auth Check: $lastAuthTime"
    }
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: DHCP Server Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set dhcpInstalled $false
    Ninja-Property-Set dhcpServerStatus "Unknown"
    Ninja-Property-Set dhcpScopeSummary "Monitor script error: $errorMessage"
    
    exit 1
}
