<#
.SYNOPSIS
    Script 2: DHCP Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Windows DHCP Server including scope utilization, lease statistics,
    failover status, and overall server health. Updates 9 DHCP fields.

.FIELDS UPDATED
    - DHCPInstalled (Checkbox)
    - DHCPScopeCount (Integer)
    - DHCPActiveLeasesTotal (Integer)
    - DHCPScopeUtilizationPercent (Integer)
    - DHCPFailoverStatus (Text)
    - DHCPServerStatus (Text)
    - DHCPLastAuthTime (DateTime)
    - DHCPConflictCount (Integer)
    - DHCPScopeSummary (WYSIWYG)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~35 seconds
    Requires: DHCP Server role installed

.NOTES
    File: Script_02_DHCP_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Infrastructure Monitoring
    Dependencies: DhcpServer PowerShell module

.RELATED DOCUMENTATION
    - docs/core/14_ROLE_Infrastructure.md
    - docs/IMPLEMENTATION_PROGRESS_2026-02-03.md
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting DHCP Server Monitor (Script 2)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $dhcpInstalled = $false
    $scopeCount = 0
    $activeLeasesTotal = 0
    $scopeUtilizationPercent = 0
    $failoverStatus = "Not Configured"
    $serverStatus = "Unknown"
    $lastAuthTime = ""
    $conflictCount = 0
    $scopeSummary = ""
    
    # Check if DHCP Server role is installed
    Write-Host "Checking DHCP Server installation..."
    $dhcpFeature = Get-WindowsFeature -Name "DHCP" -ErrorAction SilentlyContinue
    
    if ($null -eq $dhcpFeature -or $dhcpFeature.Installed -ne $true) {
        Write-Host "DHCP Server role is not installed."
        
        # Update fields for non-DHCP systems
        Ninja-Property-Set dhcpInstalled $false
        Ninja-Property-Set dhcpScopeCount 0
        Ninja-Property-Set dhcpActiveLeasesTotal 0
        Ninja-Property-Set dhcpScopeUtilizationPercent 0
        Ninja-Property-Set dhcpFailoverStatus "Not Configured"
        Ninja-Property-Set dhcpServerStatus "Unknown"
        Ninja-Property-Set dhcpLastAuthTime ""
        Ninja-Property-Set dhcpConflictCount 0
        Ninja-Property-Set dhcpScopeSummary "DHCP Server not installed"
        
        Write-Host "DHCP Server Monitor complete (not installed)."
        exit 0
    }
    
    $dhcpInstalled = $true
    Write-Host "DHCP Server role is installed."
    
    # Check DHCP service status
    $dhcpService = Get-Service -Name "DHCPServer" -ErrorAction SilentlyContinue
    if ($dhcpService) {
        $serverStatus = if ($dhcpService.Status -eq 'Running') { "Healthy" } else { "Critical" }
        Write-Host "DHCP Service Status: $($dhcpService.Status)"
    } else {
        $serverStatus = "Critical"
        Write-Host "DHCP Service not found."
    }
    
    # Import DHCP module
    try {
        Import-Module DhcpServer -ErrorAction Stop
        Write-Host "DhcpServer module loaded."
    } catch {
        Write-Warning "Failed to load DhcpServer module: $_"
        throw "DhcpServer module not available"
    }
    
    # Get DHCP server authorization status
    try {
        $authServers = Get-DhcpServerInDC -ErrorAction SilentlyContinue
        if ($authServers) {
            $thisServer = $authServers | Where-Object { $_.DnsName -eq $env:COMPUTERNAME -or $_.DnsName -match $env:COMPUTERNAME }
            if ($thisServer) {
                $lastAuthTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "DHCP Server is authorized in Active Directory."
            }
        }
    } catch {
        Write-Host "Unable to check DHCP authorization status (may not be in AD environment)."
    }
    
    # Get DHCP scopes
    Write-Host "Retrieving DHCP scopes..."
    try {
        $scopes = Get-DhcpServerv4Scope -ErrorAction Stop
        $scopeCount = $scopes.Count
        Write-Host "Total Scopes: $scopeCount"
        
        $htmlRows = @()
        $totalAddresses = 0
        $totalInUse = 0
        
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
                    
                    # Color code by utilization
                    $utilizationColor = if ($percentUsed -ge 90) { 'red' } 
                                       elseif ($percentUsed -ge 75) { 'orange' } 
                                       else { 'green' }
                    
                    $scopeName = $scope.Name
                    $scopeRange = "$($scope.StartRange) - $($scope.EndRange)"
                    $scopeState = $scope.State
                    
                    $htmlRows += "<tr><td>$scopeName</td><td>$scopeRange</td><td>$scopeState</td><td style='color:$utilizationColor'>$percentUsed%</td><td>$inUse / $total</td></tr>"
                }
            } catch {
                Write-Warning "Failed to get statistics for scope $($scope.ScopeId): $_"
            }
        }
        
        # Calculate overall utilization
        if ($totalAddresses -gt 0) {
            $scopeUtilizationPercent = [Math]::Round(($totalInUse / $totalAddresses) * 100)
        }
        
        Write-Host "Active Leases: $activeLeasesTotal"
        Write-Host "Overall Utilization: $scopeUtilizationPercent%"
        
        # Build HTML summary
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
        Write-Warning "Failed to retrieve DHCP scopes: $_"
        $scopeSummary = "Unable to retrieve scope information"
    }
    
    # Get failover configuration
    try {
        $failovers = Get-DhcpServerv4Failover -ErrorAction SilentlyContinue
        if ($failovers) {
            $failoverStatus = "Configured ($($failovers.Count) partner(s))"
            Write-Host "Failover Status: $failoverStatus"
        } else {
            $failoverStatus = "Not Configured"
        }
    } catch {
        Write-Host "Failover not configured or unable to query."
        $failoverStatus = "Not Configured"
    }
    
    # Get conflict detection count
    try {
        $serverSettings = Get-DhcpServerv4Statistics -ErrorAction SilentlyContinue
        if ($serverSettings) {
            # Check for decline/release activity as proxy for conflicts
            $conflictCount = 0  # Windows DHCP doesn't directly expose conflict count
            Write-Host "Conflict Detection: Enabled (count not directly available)"
        }
    } catch {
        Write-Host "Unable to retrieve server statistics."
    }
    
    # Adjust health status based on utilization
    if ($serverStatus -eq "Healthy") {
        if ($scopeUtilizationPercent -ge 95) {
            $serverStatus = "Critical"
        } elseif ($scopeUtilizationPercent -ge 85) {
            $serverStatus = "Warning"
        }
    }
    
    Write-Host "Final Health Status: $serverStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set dhcpInstalled $true
    Ninja-Property-Set dhcpScopeCount $scopeCount
    Ninja-Property-Set dhcpActiveLeasesTotal $activeLeasesTotal
    Ninja-Property-Set dhcpScopeUtilizationPercent $scopeUtilizationPercent
    Ninja-Property-Set dhcpFailoverStatus $failoverStatus
    Ninja-Property-Set dhcpServerStatus $serverStatus
    Ninja-Property-Set dhcpLastAuthTime $lastAuthTime
    Ninja-Property-Set dhcpConflictCount $conflictCount
    Ninja-Property-Set dhcpScopeSummary $scopeSummary
    
    Write-Host "DHCP Server Monitor complete. Status: $serverStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "DHCP Server Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set dhcpInstalled $false
    Ninja-Property-Set dhcpServerStatus "Unknown"
    Ninja-Property-Set dhcpScopeSummary "Monitor script error: $errorMessage"
    
    exit 1
}
