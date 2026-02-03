<#
.SYNOPSIS
    Script 3: DNS Server Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Windows DNS Server including zone health, query statistics, recursion status,
    and overall server health. Updates 9 DNS fields.

.FIELDS UPDATED
    - DNSInstalled (Checkbox)
    - DNSZoneCount (Integer)
    - DNSQueriesPerSec (Integer)
    - DNSRecursionEnabled (Checkbox)
    - DNSCacheHitRate (Integer)
    - DNSFailedQueryCount (Integer)
    - DNSServerStatus (Dropdown)
    - DNSZoneSummary (WYSIWYG)
    - DNSForwarders (Text)

.EXECUTION
    Frequency: Every 4 hours
    Runtime: ~35 seconds
    Requires: DNS Server role installed

.NOTES
    File: Script_03_DNS_Server_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Infrastructure Monitoring
    Dependencies: DnsServer PowerShell module

.RELATED DOCUMENTATION
    - docs/core/14_ROLE_Infrastructure.md
    - docs/IMPLEMENTATION_PROGRESS_2026-02-03.md
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting DNS Server Monitor (Script 3)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $dnsInstalled = $false
    $zoneCount = 0
    $queriesPerSec = 0
    $recursionEnabled = $false
    $cacheHitRate = 0
    $failedQueryCount = 0
    $serverStatus = "Unknown"
    $zoneSummary = ""
    $forwarders = "None"
    
    # Check if DNS Server role is installed
    Write-Host "Checking DNS Server installation..."
    $dnsFeature = Get-WindowsFeature -Name "DNS" -ErrorAction SilentlyContinue
    
    if ($null -eq $dnsFeature -or $dnsFeature.Installed -ne $true) {
        Write-Host "DNS Server role is not installed."
        
        # Update fields for non-DNS systems
        Ninja-Property-Set dnsInstalled $false
        Ninja-Property-Set dnsZoneCount 0
        Ninja-Property-Set dnsQueriesPerSec 0
        Ninja-Property-Set dnsRecursionEnabled $false
        Ninja-Property-Set dnsCacheHitRate 0
        Ninja-Property-Set dnsFailedQueryCount 0
        Ninja-Property-Set dnsServerStatus "Unknown"
        Ninja-Property-Set dnsZoneSummary "DNS Server not installed"
        Ninja-Property-Set dnsForwarders "None"
        
        Write-Host "DNS Server Monitor complete (not installed)."
        exit 0
    }
    
    $dnsInstalled = $true
    Write-Host "DNS Server role is installed."
    
    # Check DNS service status
    $dnsService = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    if ($dnsService) {
        $serverStatus = if ($dnsService.Status -eq 'Running') { "Healthy" } else { "Critical" }
        Write-Host "DNS Service Status: $($dnsService.Status)"
    } else {
        $serverStatus = "Critical"
        Write-Host "DNS Service not found."
    }
    
    # Import DNS module
    try {
        Import-Module DnsServer -ErrorAction Stop
        Write-Host "DnsServer module loaded."
    } catch {
        Write-Warning "Failed to load DnsServer module: $_"
        throw "DnsServer module not available"
    }
    
    # Get DNS server configuration
    try {
        $dnsServerSettings = Get-DnsServer -ErrorAction Stop
        
        # Check recursion status
        $recursionEnabled = -not $dnsServerSettings.ServerSetting.DisableRecursion
        Write-Host "Recursion Enabled: $recursionEnabled"
        
        # Get forwarders
        if ($dnsServerSettings.ServerSetting.Forwarders) {
            $forwarderList = $dnsServerSettings.ServerSetting.Forwarders -join ", "
            $forwarders = $forwarderList
            Write-Host "Forwarders: $forwarders"
        } else {
            $forwarders = "None"
            Write-Host "No forwarders configured."
        }
        
    } catch {
        Write-Warning "Failed to get DNS server settings: $_"
    }
    
    # Get DNS zones
    Write-Host "Retrieving DNS zones..."
    try {
        $zones = Get-DnsServerZone -ErrorAction Stop
        $zoneCount = $zones.Count
        Write-Host "Total Zones: $zoneCount"
        
        $htmlRows = @()
        
        foreach ($zone in $zones | Where-Object { $_.IsAutoCreated -eq $false }) {
            try {
                $zoneName = $zone.ZoneName
                $zoneType = $zone.ZoneType
                $isDynamic = $zone.DynamicUpdate
                $isSigned = $zone.IsDsIntegrated
                
                # Color code by zone type
                $typeColor = switch ($zoneType) {
                    'Primary' { 'green' }
                    'Secondary' { 'blue' }
                    'Stub' { 'gray' }
                    default { 'black' }
                }
                
                $dynamicText = if ($isDynamic -eq 'Secure') { "Secure" } 
                              elseif ($isDynamic -eq 'NonsecureAndSecure') { "Yes" } 
                              else { "No" }
                
                $htmlRows += "<tr><td>$zoneName</td><td style='color:$typeColor'>$zoneType</td><td>$dynamicText</td><td>$isSigned</td></tr>"
            } catch {
                Write-Warning "Failed to process zone $zoneName: $_"
            }
        }
        
        # Build HTML summary
        if ($htmlRows.Count -gt 0) {
            $zoneSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Zone Name</th><th>Type</th><th>Dynamic</th><th>AD Integrated</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary:</strong> $zoneCount total zones (including auto-created)
</p>
"@
        } else {
            $zoneSummary = "No DNS zones configured"
        }
        
    } catch {
        Write-Warning "Failed to retrieve DNS zones: $_"
        $zoneSummary = "Unable to retrieve zone information"
    }
    
    # Get DNS statistics
    try {
        $statistics = Get-DnsServerStatistics -ErrorAction SilentlyContinue
        
        if ($statistics) {
            # Queries per second (approximate from recent activity)
            $totalQueries = $statistics.TotalQueries
            $queriesPerSec = 0  # Would need time-based sampling for accurate rate
            
            # Cache statistics
            if ($statistics.CacheStatistics) {
                $cacheHits = $statistics.CacheStatistics.TotalHits
                $cacheMisses = $statistics.CacheStatistics.TotalMisses
                $totalCache = $cacheHits + $cacheMisses
                
                if ($totalCache -gt 0) {
                    $cacheHitRate = [Math]::Round(($cacheHits / $totalCache) * 100)
                    Write-Host "Cache Hit Rate: $cacheHitRate%"
                }
            }
            
            # Failed queries
            if ($statistics.QueryStatistics) {
                $failedQueryCount = $statistics.QueryStatistics.Failure
                Write-Host "Failed Queries: $failedQueryCount"
            }
            
            Write-Host "Total Queries: $totalQueries"
        }
    } catch {
        Write-Warning "Failed to retrieve DNS statistics: $_"
    }
    
    # Alternative statistics from performance counters
    try {
        $queryCounter = Get-Counter "\DNS\Total Query Received/sec" -ErrorAction SilentlyContinue
        if ($queryCounter) {
            $queriesPerSec = [Math]::Round($queryCounter.CounterSamples[0].CookedValue)
            Write-Host "Queries/sec (from counter): $queriesPerSec"
        }
    } catch {
        Write-Host "Performance counters not accessible."
    }
    
    # Check for zone transfer issues or other problems
    try {
        $serverDiagnostics = Test-DnsServer -ErrorAction SilentlyContinue
        if ($serverDiagnostics) {
            $failedTests = $serverDiagnostics | Where-Object { $_.Result -eq 'Failure' }
            if ($failedTests) {
                $serverStatus = "Warning"
                Write-Host "DNS diagnostics detected issues."
            }
        }
    } catch {
        Write-Host "DNS diagnostics not available."
    }
    
    Write-Host "Final Health Status: $serverStatus"
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set dnsInstalled $true
    Ninja-Property-Set dnsZoneCount $zoneCount
    Ninja-Property-Set dnsQueriesPerSec $queriesPerSec
    Ninja-Property-Set dnsRecursionEnabled $recursionEnabled
    Ninja-Property-Set dnsCacheHitRate $cacheHitRate
    Ninja-Property-Set dnsFailedQueryCount $failedQueryCount
    Ninja-Property-Set dnsServerStatus $serverStatus
    Ninja-Property-Set dnsZoneSummary $zoneSummary
    Ninja-Property-Set dnsForwarders $forwarders
    
    Write-Host "DNS Server Monitor complete. Status: $serverStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "DNS Server Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set dnsInstalled $false
    Ninja-Property-Set dnsServerStatus "Unknown"
    Ninja-Property-Set dnsZoneSummary "Monitor script error: $errorMessage"
    
    exit 1
}
