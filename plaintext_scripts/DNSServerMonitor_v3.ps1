<#
.SYNOPSIS
    DNS Server Monitor - Windows DNS Zone Health and Query Performance Monitoring

.DESCRIPTION
    Monitors Windows DNS Server infrastructure including zone configuration, query performance,
    cache efficiency, recursion settings, forwarders, and service health. Essential for ensuring
    name resolution availability and detecting DNS misconfigurations.
    
    Critical for preventing DNS outages that impact all network services, monitoring zone transfer
    health, cache performance, and query load. DNS is foundational - failures cascade to all
    dependent services (web, email, authentication, etc.).
    
    Monitoring Scope:
    
    DNS Installation Detection:
    - Checks DNS Windows feature
    - Verifies DNS service status
    - Imports DnsServer PowerShell module
    - Gracefully exits if DNS not installed
    
    Server Configuration:
    - Queries DNS server settings via Get-DnsServer
    - Checks recursion status (enabled/disabled)
    - Lists configured forwarders for external resolution
    - Recursion control for security and performance
    
    Zone Inventory:
    - Enumerates all DNS zones via Get-DnsServerZone
    - Filters out auto-created zones (cache, TrustAnchors)
    - Tracks zone type: Primary, Secondary, Stub
    - Monitors dynamic update settings: None, Secure, NonsecureAndSecure
    - Checks AD integration status
    
    Zone Summary Reporting:
    - Generates HTML formatted zone table
    - Includes zone name, type, dynamic updates, AD integration
    - Color-coded zone types: green (Primary), blue (Secondary), gray (Stub)
    - Stores in WYSIWYG field for dashboard visualization
    
    Query Performance Tracking:
    - Queries performance counter: DNS\Total Query Received/sec
    - Real-time query rate monitoring
    - Capacity planning for DNS load
    - High query rates may indicate DDoS or misconfiguration
    
    Cache Performance:
    - Retrieves cache statistics from Get-DnsServerStatistics
    - Calculates cache hit rate percentage
    - High hit rates (>80%) indicate efficient caching
    - Low hit rates suggest forwarder issues or unique queries
    
    Failed Query Tracking:
    - Counts failed queries from server statistics
    - Indicates zone misconfigurations or missing records
    - High failure rates suggest DNS resolution issues
    
    Server Diagnostics:
    - Runs Test-DnsServer for automated health checks
    - Detects zone transfer failures
    - Identifies forwarder connectivity issues
    - Discovers configuration problems
    
    Health Status Classification:
    
    Healthy:
    - DNS service running
    - No diagnostic failures detected
    - Zones operational
    
    Warning:
    - Service running but Test-DnsServer reports issues
    - Zone transfer problems
    - Forwarder connectivity degraded
    
    Critical:
    - DNS service stopped
    - Service failure
    - Complete resolution outage
    
    Unknown:
    - DNS not installed
    - Script execution error
    - Module unavailable

.NOTES
    Frequency: Every 4 hours
    Runtime: ~35 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - DNSInstalled (Checkbox)
    - DNSZoneCount (Integer: total zones including auto-created)
    - DNSQueriesPerSec (Integer: current query rate)
    - DNSRecursionEnabled (Checkbox: recursion status)
    - DNSCacheHitRate (Integer: cache efficiency %)
    - DNSFailedQueryCount (Integer: failed query total)
    - DNSServerStatus (Text: Healthy, Warning, Critical, Unknown)
    - DNSZoneSummary (WYSIWYG: HTML formatted zone table)
    - DNSForwarders (Text: comma-separated forwarder IPs)
    
    Dependencies:
    - DNS Windows feature installed
    - DnsServer PowerShell module
    - Administrator privileges
    - Performance counter access
    
    Common Zone Types:
    - Primary: Authoritative, read/write
    - Secondary: Read-only copy via zone transfer
    - Stub: Contains only NS records for delegation
    
    Dynamic Update Modes:
    - None: Static zone, manual updates only
    - Secure: DHCP/AD integrated updates (recommended)
    - NonsecureAndSecure: Allows any client updates (risky)
    
    Common Issues:
    - Service stopped: Check Event Viewer for crash details
    - Zone transfer failed: Verify secondary server connectivity
    - Forwarder timeout: Check firewall rules, external DNS
    - Low cache hit: Review forwarder configuration
    - High failed queries: Check zone records and delegation
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting DNS Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $dnsInstalled = $false
    $zoneCount = 0
    $queriesPerSec = 0
    $recursionEnabled = $false
    $cacheHitRate = 0
    $failedQueryCount = 0
    $serverStatus = "Unknown"
    $zoneSummary = ""
    $forwarders = "None"
    
    Write-Output "INFO: Checking for DNS Server role..."
    $dnsFeature = Get-WindowsFeature -Name "DNS" -ErrorAction SilentlyContinue
    
    if ($null -eq $dnsFeature -or $dnsFeature.Installed -ne $true) {
        Write-Output "INFO: DNS Server role not installed"
        
        Ninja-Property-Set dnsInstalled $false
        Ninja-Property-Set dnsZoneCount 0
        Ninja-Property-Set dnsQueriesPerSec 0
        Ninja-Property-Set dnsRecursionEnabled $false
        Ninja-Property-Set dnsCacheHitRate 0
        Ninja-Property-Set dnsFailedQueryCount 0
        Ninja-Property-Set dnsServerStatus "Unknown"
        Ninja-Property-Set dnsZoneSummary "DNS Server not installed"
        Ninja-Property-Set dnsForwarders "None"
        
        Write-Output "SUCCESS: DNS monitoring skipped (not installed)"
        exit 0
    }
    
    $dnsInstalled = $true
    Write-Output "INFO: DNS Server role detected"
    
    Write-Output "INFO: Checking DNS service status..."
    $dnsService = Get-Service -Name "DNS" -ErrorAction SilentlyContinue
    if ($dnsService) {
        $serverStatus = if ($dnsService.Status -eq 'Running') { "Healthy" } else { "Critical" }
        Write-Output "INFO: DNS service: $($dnsService.Status)"
    } else {
        $serverStatus = "Critical"
        Write-Output "WARNING: DNS service not found"
    }
    
    Write-Output "INFO: Loading DnsServer module..."
    try {
        Import-Module DnsServer -ErrorAction Stop
        Write-Output "INFO: DnsServer module loaded"
    } catch {
        Write-Output "ERROR: Failed to load DnsServer module: $_"
        throw "DnsServer module unavailable"
    }
    
    Write-Output "INFO: Retrieving DNS server configuration..."
    try {
        $dnsServerSettings = Get-DnsServer -ErrorAction Stop
        
        $recursionEnabled = -not $dnsServerSettings.ServerSetting.DisableRecursion
        Write-Output "INFO: Recursion enabled: $recursionEnabled"
        
        if ($dnsServerSettings.ServerSetting.Forwarders) {
            $forwarderList = $dnsServerSettings.ServerSetting.Forwarders -join ", "
            $forwarders = $forwarderList
            Write-Output "INFO: Forwarders: $forwarders"
        } else {
            $forwarders = "None"
            Write-Output "INFO: No forwarders configured"
        }
        
    } catch {
        Write-Output "WARNING: Failed to get DNS server settings: $_"
    }
    
    Write-Output "INFO: Enumerating DNS zones..."
    try {
        $zones = Get-DnsServerZone -ErrorAction Stop
        $zoneCount = $zones.Count
        Write-Output "INFO: Total zones: $zoneCount"
        
        $htmlRows = @()
        
        foreach ($zone in $zones | Where-Object { $_.IsAutoCreated -eq $false }) {
            try {
                $zoneName = $zone.ZoneName
                $zoneType = $zone.ZoneType
                $isDynamic = $zone.DynamicUpdate
                $isSigned = $zone.IsDsIntegrated
                
                $typeColor = switch ($zoneType) {
                    'Primary' { 'green' }
                    'Secondary' { 'blue' }
                    'Stub' { 'gray' }
                    default { 'black' }
                }
                
                $dynamicText = if ($isDynamic -eq 'Secure') { "Secure" } 
                              elseif ($isDynamic -eq 'NonsecureAndSecure') { "Yes" } 
                              else { "No" }
                
                Write-Output "  Zone: $zoneName ($zoneType)"
                
                $htmlRows += "<tr><td>$zoneName</td><td style='color:$typeColor'>$zoneType</td><td>$dynamicText</td><td>$isSigned</td></tr>"
            } catch {
                Write-Output "WARNING: Failed to process zone $zoneName: $_"
            }
        }
        
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
        Write-Output "WARNING: Failed to retrieve DNS zones: $_"
        $zoneSummary = "Unable to retrieve zone information"
    }
    
    Write-Output "INFO: Retrieving DNS statistics..."
    try {
        $statistics = Get-DnsServerStatistics -ErrorAction SilentlyContinue
        
        if ($statistics) {
            $totalQueries = $statistics.TotalQueries
            Write-Output "INFO: Total queries: $totalQueries"
            
            if ($statistics.CacheStatistics) {
                $cacheHits = $statistics.CacheStatistics.TotalHits
                $cacheMisses = $statistics.CacheStatistics.TotalMisses
                $totalCache = $cacheHits + $cacheMisses
                
                if ($totalCache -gt 0) {
                    $cacheHitRate = [Math]::Round(($cacheHits / $totalCache) * 100)
                    Write-Output "INFO: Cache hit rate: $cacheHitRate%"
                }
            }
            
            if ($statistics.QueryStatistics) {
                $failedQueryCount = $statistics.QueryStatistics.Failure
                Write-Output "INFO: Failed queries: $failedQueryCount"
            }
        }
    } catch {
        Write-Output "WARNING: Failed to retrieve DNS statistics: $_"
    }
    
    Write-Output "INFO: Querying performance counters..."
    try {
        $queryCounter = Get-Counter "\DNS\Total Query Received/sec" -ErrorAction SilentlyContinue
        if ($queryCounter) {
            $queriesPerSec = [Math]::Round($queryCounter.CounterSamples[0].CookedValue)
            Write-Output "INFO: Query rate: $queriesPerSec/sec"
        }
    } catch {
        Write-Output "INFO: Performance counters not accessible"
    }
    
    Write-Output "INFO: Running DNS diagnostics..."
    try {
        $serverDiagnostics = Test-DnsServer -ErrorAction SilentlyContinue
        if ($serverDiagnostics) {
            $failedTests = $serverDiagnostics | Where-Object { $_.Result -eq 'Failure' }
            if ($failedTests) {
                $serverStatus = "Warning"
                Write-Output "  WARNING: DNS diagnostics detected issues"
                foreach ($test in $failedTests) {
                    Write-Output "    - $($test.Name): $($test.Result)"
                }
            } else {
                Write-Output "  All diagnostic tests passed"
            }
        }
    } catch {
        Write-Output "INFO: DNS diagnostics not available"
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set dnsInstalled $true
    Ninja-Property-Set dnsZoneCount $zoneCount
    Ninja-Property-Set dnsQueriesPerSec $queriesPerSec
    Ninja-Property-Set dnsRecursionEnabled $recursionEnabled
    Ninja-Property-Set dnsCacheHitRate $cacheHitRate
    Ninja-Property-Set dnsFailedQueryCount $failedQueryCount
    Ninja-Property-Set dnsServerStatus $serverStatus
    Ninja-Property-Set dnsZoneSummary $zoneSummary
    Ninja-Property-Set dnsForwarders $forwarders
    
    Write-Output "SUCCESS: DNS Server monitoring complete"
    Write-Output "DNS SERVER METRICS:"
    Write-Output "  - Health Status: $serverStatus"
    Write-Output "  - Zones: $zoneCount"
    Write-Output "  - Query Rate: $queriesPerSec/sec"
    Write-Output "  - Cache Hit Rate: $cacheHitRate%"
    Write-Output "  - Failed Queries: $failedQueryCount"
    Write-Output "  - Recursion: $recursionEnabled"
    Write-Output "  - Forwarders: $forwarders"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: DNS Server Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set dnsInstalled $false
    Ninja-Property-Set dnsServerStatus "Unknown"
    Ninja-Property-Set dnsZoneSummary "Monitor script error: $errorMessage"
    
    exit 1
}
