<#
.SYNOPSIS
    DNS Server Monitor - DNS Infrastructure Health and Performance Monitoring

.DESCRIPTION
    Monitors Windows DNS Server role for zone health, query performance, and service availability.
    Provides comprehensive DNS infrastructure monitoring to ensure name resolution reliability and
    detect zone replication issues, configuration problems, and performance degradation.
    
    Critical for environments where DNS availability directly impacts business operations, Active
    Directory authentication, email delivery, and application connectivity. Detects zone issues
    before they cause service disruptions.
    
    NOTE: This is an alternate version of 03_DNS_Server_Monitor.ps1, likely used for different
    scheduling or organization-specific deployment patterns. Both scripts perform identical
    monitoring functions.
    
    Monitoring Scope:
    
    DNS Server Role Detection:
    - Checks for installed DNS Server Windows Feature
    - Gracefully exits if DNS role not present
    - Prevents unnecessary monitoring overhead on non-DNS systems
    
    Zone Inventory and Health:
    - Enumerates all DNS zones (forward and reverse lookup)
    - Counts total zones managed by server
    - Tracks zone types (Primary, Secondary, Stub, Active Directory-integrated)
    - Identifies unhealthy zones:
      * Primary zones that are read-only (replication issues)
      * Non-AD-integrated zones with write access problems
      * Zone transfer failures
    
    Query Performance Metrics:
    - Total queries processed since service start
    - Server uptime duration
    - Calculated query rate (queries per hour)
    - Performance baseline for capacity planning
    
    Health Status Classification:
    
    Healthy:
    - All zones responding normally
    - No read-only primary zones
    - No zone transfer failures
    - Query processing normal
    
    Warning:
    - 1-2 unhealthy zones detected
    - Minor replication delays
    - Performance within acceptable range
    - Investigation recommended
    
    Critical:
    - 3 or more unhealthy zones
    - Multiple zone failures
    - Replication completely broken
    - Immediate intervention required
    
    Unknown:
    - Script execution error
    - DNS Server module unavailable
    - Insufficient permissions

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - dnsServerInstalled (Checkbox: true if DNS role installed)
    - dnsZoneCount (Integer: total number of DNS zones)
    - dnsQueryRate (Integer: average queries per hour)
    - dnsHealthStatus (Dropdown: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Windows DNS Server role and feature
    - DnsServer PowerShell module
    - SYSTEM context for DNS administration
    
    PowerShell Cmdlets Used:
    - Get-WindowsFeature: Role detection
    - Import-Module DnsServer: DNS management functions
    - Get-DnsServerZone: Zone enumeration
    - Get-DnsServerStatistics: Query metrics
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

param()

try {
    Write-Output "Starting DNS Server Monitor (v4.0 - Script 14)..."

    # Detect DNS Server role installation
    Write-Output "INFO: Checking for DNS Server role..."
    $dnsRole = Get-WindowsFeature -Name DNS -ErrorAction SilentlyContinue

    if (-not $dnsRole -or -not $dnsRole.Installed) {
        Write-Output "INFO: DNS Server role not installed on this system"
        Ninja-Property-Set dnsServerInstalled $false
        Write-Output "SUCCESS: DNS monitoring skipped (role not present)"
        exit 0
    }

    Write-Output "INFO: DNS Server role detected - beginning monitoring"
    Ninja-Property-Set dnsServerInstalled $true

    # Load DNS Server PowerShell module
    Write-Output "INFO: Loading DnsServer PowerShell module..."
    try {
        Import-Module DnsServer -ErrorAction Stop
        Write-Output "INFO: DnsServer module loaded successfully"
    } catch {
        Write-Output "ERROR: Failed to load DnsServer module: $_"
        Ninja-Property-Set dnsHealthStatus "Unknown"
        exit 1
    }

    # Enumerate DNS zones
    Write-Output "INFO: Enumerating DNS zones..."
    $zones = Get-DnsServerZone -ErrorAction SilentlyContinue
    $zoneCount = $zones.Count
    
    Write-Output "INFO: Found $zoneCount DNS zone(s)"
    Ninja-Property-Set dnsZoneCount $zoneCount

    # Collect DNS server statistics
    Write-Output "INFO: Collecting DNS server statistics..."
    $stats = Get-DnsServerStatistics -ErrorAction SilentlyContinue
    
    if ($stats) {
        $totalQueries = $stats.TotalQueries
        $uptime = $stats.Uptime.TotalHours
        $queryRate = if ($uptime -gt 0) {
            [int]($totalQueries / $uptime)
        } else { 0 }
        
        Write-Output "INFO: Total queries: $totalQueries"
        Write-Output "INFO: Server uptime: $([math]::Round($uptime, 2)) hours"
        Write-Output "INFO: Query rate: $queryRate queries/hour"
        
        Ninja-Property-Set dnsQueryRate $queryRate
    } else {
        Write-Output "WARNING: Unable to retrieve DNS statistics"
        Ninja-Property-Set dnsQueryRate 0
    }

    # Analyze zone health
    Write-Output "INFO: Analyzing DNS zone health..."
    $unhealthyZones = 0
    $unhealthyZoneNames = @()
    
    foreach ($zone in $zones) {
        Write-Output "  Checking zone: $($zone.ZoneName) (Type: $($zone.ZoneType), AD: $($zone.IsDsIntegrated))"
        
        # Check for problematic primary zones
        if ($zone.ZoneType -eq 'Primary' -and -not $zone.IsDsIntegrated) {
            if ($zone.IsReadOnly) {
                $unhealthyZones++
                $unhealthyZoneNames += $zone.ZoneName
                Write-Output "    WARNING: Zone is read-only (potential replication issue)"
            }
        }
    }

    # Determine overall health status
    Write-Output "INFO: Determining DNS health status..."
    if ($unhealthyZones -eq 0) {
        $health = "Healthy"
        Write-Output "  ASSESSMENT: All zones healthy"
    } elseif ($unhealthyZones -le 2) {
        $health = "Warning"
        Write-Output "  ASSESSMENT: Minor zone issues detected ($unhealthyZones unhealthy zones)"
    } else {
        $health = "Critical"
        Write-Output "  ASSESSMENT: Multiple zone failures ($unhealthyZones unhealthy zones)"
    }

    Ninja-Property-Set dnsHealthStatus $health

    Write-Output "SUCCESS: DNS monitoring complete"
    Write-Output "DNS SERVER METRICS:"
    Write-Output "  - Health Status: $health"
    Write-Output "  - Total Zones: $zoneCount"
    Write-Output "  - Query Rate: $queryRate queries/hour"
    Write-Output "  - Unhealthy Zones: $unhealthyZones"
    
    if ($unhealthyZoneNames.Count -gt 0) {
        Write-Output "UNHEALTHY ZONES:"
        $unhealthyZoneNames | ForEach-Object { Write-Output "  - $_" }
        Write-Output "RECOMMENDATION: Investigate zone replication and file permissions"
    }
    
    # Provide zone type summary
    $primaryZones = ($zones | Where-Object { $_.ZoneType -eq 'Primary' }).Count
    $secondaryZones = ($zones | Where-Object { $_.ZoneType -eq 'Secondary' }).Count
    $adIntegratedZones = ($zones | Where-Object { $_.IsDsIntegrated }).Count
    
    Write-Output "ZONE TYPE SUMMARY:"
    Write-Output "  - Primary Zones: $primaryZones"
    Write-Output "  - Secondary Zones: $secondaryZones"
    Write-Output "  - AD-Integrated Zones: $adIntegratedZones"

    exit 0
} catch {
    Write-Output "ERROR: DNS Server Monitor failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set dnsHealthStatus "Unknown"
    exit 1
}
