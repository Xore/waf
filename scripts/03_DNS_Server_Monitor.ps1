<#
.SYNOPSIS
    NinjaRMM Script 3: DNS Server Monitor

.DESCRIPTION
    Monitors DNS server health, zones, and query performance.
    Part of Infrastructure Monitoring suite.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - dnsServerInstalled (Checkbox)
    - dnsZoneCount (Integer)
    - dnsQueryRate (Integer)
    - dnsHealthStatus (Dropdown)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    # Check if DNS Server role is installed
    $dnsRole = Get-WindowsFeature -Name DNS -ErrorAction SilentlyContinue

    if (-not $dnsRole -or -not $dnsRole.Installed) {
        Ninja-Property-Set dnsServerInstalled $false
        Write-Output "DNS Server role not installed"
        exit 0
    }

    Ninja-Property-Set dnsServerInstalled $true

    # Import DNS module
    Import-Module DnsServer -ErrorAction Stop

    # Get DNS zones
    $zones = Get-DnsServerZone -ErrorAction SilentlyContinue
    $zoneCount = $zones.Count

    Ninja-Property-Set dnsZoneCount $zoneCount

    # Get DNS statistics
    $stats = Get-DnsServerStatistics -ErrorAction SilentlyContinue
    $queryRate = if ($stats) {
        [int]($stats.TotalQueries / ([math]::Max(1, $stats.Uptime.TotalHours)))
    } else { 0 }

    Ninja-Property-Set dnsQueryRate $queryRate

    # Check zone health
    $unhealthyZones = 0
    foreach ($zone in $zones) {
        if ($zone.ZoneType -eq 'Primary' -and -not $zone.IsDsIntegrated) {
            if ($zone.IsReadOnly) {
                $unhealthyZones++
            }
        }
    }

    # Determine health status
    if ($unhealthyZones -eq 0) {
        $health = "Healthy"
    } elseif ($unhealthyZones -le 2) {
        $health = "Warning"
    } else {
        $health = "Critical"
    }

    Ninja-Property-Set dnsHealthStatus $health

    Write-Output "DNS Health: $health | Zones: $zoneCount | Queries/hour: $queryRate"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set dnsHealthStatus "Unknown"
    exit 1
}
