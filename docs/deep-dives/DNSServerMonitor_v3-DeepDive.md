# DNSServerMonitor_v3.ps1 - Deep Dive Guide

## Overview

**DNSServerMonitor_v3.ps1** is a comprehensive monitoring solution for Windows DNS Server infrastructure, tracking zone health, query performance, cache efficiency, and resolution capabilities. As DNS is foundational to all network services, this script is critical for preventing cascading failures that impact web access, email delivery, authentication, and application functionality.

### Key Capabilities

- **Zone Configuration Management**: Automated inventory of all DNS zones with type and dynamic update tracking
- **Query Performance Monitoring**: Real-time query rate and cache efficiency metrics
- **Resolution Health Checking**: Failed query tracking and forwarder connectivity validation
- **Diagnostic Testing**: Automated Test-DnsServer for comprehensive health assessment
- **Security Configuration**: Recursion status and secure dynamic update monitoring
- **Dashboard Integration**: HTML-formatted zone summaries for visual monitoring

---

## Technical Architecture

### Monitoring Scope

```
DNS Server Infrastructure
├── Installation Detection
│   ├── DNS Windows feature verification
│   ├── DNS service status check
│   ├── DnsServer module availability
│   └── Graceful exit if not installed
│
├── Server Configuration
│   ├── Recursion settings (enabled/disabled)
│   ├── Forwarder configuration
│   ├── Cache parameters
│   └── Security settings
│
├── Zone Inventory
│   ├── Primary zones (authoritative)
│   ├── Secondary zones (read-only copies)
│   ├── Stub zones (delegation only)
│   ├── Dynamic update configuration
│   └── AD integration status
│
├── Performance Metrics
│   ├── Query rate (queries/sec)
│   ├── Cache hit rate percentage
│   ├── Failed query count
│   └── Statistics aggregation
│
└── Health Diagnostics
    ├── Service status verification
    ├── Test-DnsServer automated checks
    ├── Zone transfer validation
    └── Forwarder connectivity testing
```

### Data Collection Flow

```
1. Role Verification
   └→ DNS feature installed?
       ├→ No: Record Unknown status, exit gracefully
       └→ Yes: Continue monitoring

2. Service Status
   └→ Get-Service DNS
       ├→ Running: Proceed with checks
       └→ Stopped: Set Critical status, collect basic info

3. Server Configuration
   └→ Get-DnsServer
       ├→ Check recursion setting
       ├→ List configured forwarders
       └→ Retrieve cache settings

4. Zone Enumeration
   └→ Get-DnsServerZone
       └→ For each non-auto zone:
           ├→ Identify type (Primary/Secondary/Stub)
           ├→ Check dynamic update mode
           ├→ Verify AD integration
           └→ Build HTML table row

5. Performance Collection
   ├→ Get-DnsServerStatistics → Cache hits/misses, failed queries
   └→ Get-Counter "\DNS\Total Query Received/sec" → Query rate

6. Diagnostic Testing
   └→ Test-DnsServer
       ├→ Zone transfer validation
       ├→ Forwarder connectivity
       ├→ Configuration checks
       └→ Report failures

7. Health Classification
   └→ Service stopped? → Critical
   └→ Test-DnsServer failures? → Warning
   └→ Else: Healthy
```

---

## Field Reference

### Custom Fields Configuration

```powershell
# Boolean Fields
dnsInstalled              # Checkbox: DNS Server role installed
dnsRecursionEnabled       # Checkbox: Recursion status

# Integer Fields
dnsZoneCount              # Total zones (including auto-created)
dnsQueriesPerSec          # Current query rate (queries/second)
dnsCacheHitRate           # Cache efficiency percentage (0-100)
dnsFailedQueryCount       # Total failed queries

# Text/WYSIWYG Fields
dnsServerStatus           # Text: Healthy|Warning|Critical|Unknown
dnsZoneSummary            # WYSIWYG: HTML formatted zone table
dnsForwarders             # Text: Comma-separated forwarder IPs
```

### Field Value Examples

**Healthy DNS Server:**
```
dnsInstalled = true
dnsZoneCount = 12
dnsQueriesPerSec = 87
dnsRecursionEnabled = true
dnsCacheHitRate = 92
dnsFailedQueryCount = 3
dnsServerStatus = "Healthy"
dnsZoneSummary = [HTML table with 12 zones]
dnsForwarders = "8.8.8.8, 8.8.4.4"
```

**Warning State (Zone Transfer Issue):**
```
dnsServerStatus = "Warning"
dnsZoneSummary shows Test-DnsServer failures
```

**Critical State (Service Stopped):**
```
dnsServerStatus = "Critical"
dnsQueriesPerSec = 0
```

---

## Monitoring Logic Details

### Zone Type Classification

DNS zones serve different purposes in the resolution hierarchy:

```powershell
# Zone type identification
foreach ($zone in $zones) {
    $zoneType = $zone.ZoneType
    # Primary: Authoritative, read/write
    # Secondary: Read-only copy via zone transfer
    # Stub: Contains only NS records for delegation
}
```

**Zone Type Characteristics:**

| Type | Purpose | Updates | Use Case |
|------|---------|---------|----------|
| **Primary** | Authoritative source | Read/write | Internal domain zones |
| **Secondary** | Redundancy/load distribution | Read-only (via zone transfer) | DR sites, distributed offices |
| **Stub** | Delegation tracking | Automatic NS updates | Subdomain delegation |

**HTML Color Coding:**
- Primary zones: Green (critical infrastructure)
- Secondary zones: Blue (redundancy)
- Stub zones: Gray (delegation only)

### Dynamic Update Modes

Controls how DNS records can be updated:

```powershell
# Dynamic update classification
$dynamicText = switch ($zone.DynamicUpdate) {
    'Secure' { "Secure" }              # Only authenticated clients (AD)
    'NonsecureAndSecure' { "Yes" }    # Any client can update (risky)
    'None' { "No" }                    # Manual updates only
}
```

**Security Implications:**

- **None**: Static zones, highest security, manual management burden
- **Secure**: Recommended for AD-integrated zones, DHCP/client updates with Kerberos auth
- **NonsecureAndSecure**: Risk of DNS poisoning, only for test/legacy environments

**Best Practice:**
```
Internal AD zones → Secure dynamic updates + AD integration
Public-facing zones → None (manual updates)
DMZ zones → None or Secure (limited scope)
```

### Cache Performance Analysis

Cache efficiency directly impacts query response time and external bandwidth:

```powershell
# Cache hit rate calculation
$cacheHits = $statistics.CacheStatistics.TotalHits
$cacheMisses = $statistics.CacheStatistics.TotalMisses
$totalCache = $cacheHits + $cacheMisses

if ($totalCache -gt 0) {
    $cacheHitRate = [Math]::Round(($cacheHits / $totalCache) * 100)
}
```

**Cache Hit Rate Interpretation:**

- **>90%**: Excellent (typical for internal DNS with stable queries)
- **80-90%**: Good (normal for mixed internal/external queries)
- **60-80%**: Fair (may indicate cache timeout issues or unique queries)
- **<60%**: Poor (investigate forwarder config, query patterns, cache settings)

**Common Causes of Low Hit Rate:**
1. Short TTL values forcing frequent re-queries
2. High volume of unique/random queries (malware, scanning)
3. Cache size too small for query volume
4. Forwarder timeouts causing cache invalidation

### Query Rate Monitoring

Real-time query performance tracking:

```powershell
# Query rate from performance counter
$queryCounter = Get-Counter "\DNS\Total Query Received/sec"
$queriesPerSec = [Math]::Round($queryCounter.CounterSamples[0].CookedValue)
```

**Query Rate Baselines:**

| Environment | Typical Rate | Alert Threshold |
|-------------|--------------|------------------|
| Small office (50 users) | 5-20 q/s | >100 q/s |
| Medium enterprise (500 users) | 50-200 q/s | >1000 q/s |
| Large enterprise (5000+ users) | 500-2000 q/s | >5000 q/s |
| Datacenter DNS | 1000-10000 q/s | >20000 q/s |

**Abnormal Query Patterns:**
- **Sudden spike**: DDoS, malware outbreak, misconfiguration
- **Sustained high rate**: DNS amplification attack, botnet activity
- **Drop to zero**: Service failure, network isolation

### Recursion and Forwarders

Controls how DNS resolves external names:

```powershell
# Recursion configuration
$recursionEnabled = -not $dnsServerSettings.ServerSetting.DisableRecursion

# Forwarder list
if ($dnsServerSettings.ServerSetting.Forwarders) {
    $forwarders = $dnsServerSettings.ServerSetting.Forwarders -join ", "
}
```

**Recursion Scenarios:**

**Recursion Enabled + Forwarders:**
```
Client → DNS Server → Forwarders → Root servers
(Recommended for internal DNS)
```

**Recursion Enabled + No Forwarders:**
```
Client → DNS Server → Root servers directly
(Higher bandwidth, slower, more complex firewall rules)
```

**Recursion Disabled:**
```
Client → DNS Server (only authoritative answers)
(Recommended for public-facing authoritative DNS)
```

**Common Forwarder Configurations:**
- **ISP DNS**: Provider-specific, varies by reliability
- **Google Public DNS**: 8.8.8.8, 8.8.4.4 (reliable, privacy concerns)
- **Cloudflare**: 1.1.1.1, 1.0.0.1 (fast, privacy-focused)
- **Quad9**: 9.9.9.9 (malware filtering)

### Diagnostic Testing

Automated health validation:

```powershell
# Run comprehensive diagnostics
$serverDiagnostics = Test-DnsServer
$failedTests = $serverDiagnostics | Where-Object { $_.Result -eq 'Failure' }
```

**Test-DnsServer Checks:**
- Zone transfer functionality (secondary zone updates)
- Forwarder connectivity and responsiveness
- Root hints validity
- Dynamic update functionality
- DNSSEC validation (if configured)

**Common Failure Scenarios:**
- **Zone transfer failure**: Firewall blocking TCP 53, secondary server unreachable
- **Forwarder timeout**: Internet connectivity issue, forwarder DNS down
- **Root hints stale**: Root servers changed (rare), internet connectivity

---

## Real-World Scenarios

### Scenario 1: Secondary Zone Not Updating

**Symptom:**
```
dnsServerStatus = "Warning"
Test-DnsServer reports zone transfer failure
Secondary zone shows stale records
```

**Investigation Steps:**

1. **Check zone transfer settings on primary:**
```powershell
Get-DnsServerZone -Name "contoso.com" | Select-Object ZoneTransferSetting, SecureSecondaries, NotifyServers

# Verify secondary server is allowed
Get-DnsServerZone -Name "contoso.com" | Select-Object -ExpandProperty SecondaryServers
```

2. **Test connectivity from secondary to primary:**
```powershell
# From secondary server
Test-NetConnection -ComputerName primary-dns.contoso.com -Port 53

# Test zone transfer manually
nslookup
server primary-dns.contoso.com
ls contoso.com
```

3. **Check firewall rules:**
```powershell
# Verify TCP 53 allowed (zone transfers use TCP, queries use UDP)
Get-NetFirewallRule -DisplayName "*DNS*" | Where-Object { $_.Enabled -eq $true }

# Check Windows Firewall logs
Get-Content "C:\Windows\System32\LogFiles\Firewall\pfirewall.log" | Select-String "53"
```

**Common Root Causes:**
- Firewall blocking TCP 53 (only UDP 53 allowed)
- Secondary server not in primary's allowed transfer list
- Authentication failure for AD-integrated zones
- Network path MTU issues fragmenting large zone transfers

**Resolution:**
```powershell
# On primary: Allow secondary server for zone transfer
Set-DnsServerPrimaryZone -Name "contoso.com" -SecondaryServers "192.168.1.11"

# Enable zone transfer to specific servers
Set-DnsServerPrimaryZone -Name "contoso.com" -SecureSecondaries TransferToSecureServers

# Configure notify list
Set-DnsServerPrimaryZone -Name "contoso.com" -Notify NotifyServers -NotifyServers "192.168.1.11"
```

### Scenario 2: Low Cache Hit Rate

**Symptom:**
```
dnsCacheHitRate = 45%
dnsQueriesPerSec = 150
High external DNS query traffic
```

**Investigation Steps:**

1. **Analyze query patterns:**
```powershell
# Enable DNS debug logging temporarily
Set-DnsServerDiagnostics -Queries $true -QueryErrors $true -LogFilePath "C:\DNSLogs"

# After 5-10 minutes, analyze top queried names
Get-Content "C:\Windows\System32\dns\dns.log" | 
    Select-String "QUERY" | 
    ForEach-Object { ($_ -split " ")[10] } | 
    Group-Object | Sort-Object Count -Descending | Select-Object -First 20

# Disable debug logging (performance impact)
Set-DnsServerDiagnostics -Queries $false -QueryErrors $false
```

2. **Check TTL values:**
```powershell
# Review zone TTLs
Get-DnsServerZone | Select-Object ZoneName, @{N='MinTTL';E={(Get-DnsServerResourceRecord -ZoneName $_.ZoneName -RRType A)[0].TimeToLive}}

# Short TTLs (<300 seconds) cause frequent cache invalidation
```

3. **Investigate forwarder performance:**
```powershell
# Test forwarder response time
Measure-Command { Resolve-DnsName google.com -Server 8.8.8.8 }

# High latency (>200ms) reduces cache effectiveness
```

**Common Causes:**
- Malware generating random subdomain queries (DGA)
- Applications with hard-coded short TTLs
- Forwarder timeouts causing cache invalidation
- Cache size insufficient for query volume

**Resolution:**

1. **Increase cache size:**
```powershell
# Increase max cache size (default 10MB)
Set-DnsServerCache -MaxTTL ([TimeSpan]::FromHours(24))

# For high-volume servers:
Set-DnsServerCache -MaxNegativeTtl ([TimeSpan]::FromMinutes(15))
```

2. **Identify and block malicious queries:**
```powershell
# Block specific malicious domains
Add-DnsServerQueryResolutionPolicy -Name "BlockMalware" `
    -Action IGNORE -FQDN "EQ,*.badactor.com"
```

3. **Optimize forwarders:**
```powershell
# Use multiple forwarders for redundancy
Set-DnsServerForwarder -IPAddress @("8.8.8.8","8.8.4.4","1.1.1.1","1.0.0.1")
```

### Scenario 3: DNS Amplification Attack

**Symptom:**
```
dnsQueriesPerSec = 15,000 (normally 200)
dnsFailedQueryCount = 12,000+
Internet bandwidth saturated
Log shows queries from many external IPs
```

**Investigation Steps:**

1. **Identify attack pattern:**
```powershell
# Check for open recursion exploitation
Get-DnsServerSetting | Select-Object -ExpandProperty ServerSetting | 
    Select-Object DisableRecursion

# Review query sources
Get-WinEvent -LogName "DNS Server" -MaxEvents 1000 | 
    Where-Object { $_.Id -eq 256 } |  # Query events
    Group-Object MachineName | Sort-Object Count -Descending
```

2. **Analyze attack characteristics:**
```powershell
# Check for ANY queries (amplification vector)
Get-Content "C:\Windows\System32\dns\dns.log" | Select-String "ANY"

# Identify queried domains
Get-Content "C:\Windows\System32\dns\dns.log" | 
    Select-String "QUERY" | 
    ForEach-Object { ($_ -split " ")[10] } | 
    Group-Object | Sort-Object Count -Descending | Select-Object -First 10
```

**Immediate Mitigation:**

1. **Disable recursion for external clients:**
```powershell
# Disable recursion (if authoritative-only DNS)
Set-DnsServerRecursion -Enable $false

# OR restrict recursion to internal networks only
Add-DnsServerRecursionScope -Name "Internal" -EnableRecursion $true
Add-DnsServerQueryResolutionPolicy -Name "AllowInternalRecursion" `
    -ApplyOnRecursion -RecursionScope "Internal" `
    -ClientSubnet "EQ,192.168.0.0/16"
```

2. **Rate limiting:**
```powershell
# Enable Response Rate Limiting (RRL)
Set-DnsServerResponseRateLimiting -Mode Enable `
    -ResponsesPerSec 5 `
    -ErrorsPerSec 5 `
    -WindowInSec 5
```

3. **Block external access:**
```powershell
# Firewall: Allow DNS only from internal networks
New-NetFirewallRule -DisplayName "DNS - Internal Only" `
    -Direction Inbound -Protocol UDP -LocalPort 53 `
    -RemoteAddress "192.168.0.0/16" -Action Allow

New-NetFirewallRule -DisplayName "DNS - Block External" `
    -Direction Inbound -Protocol UDP -LocalPort 53 `
    -Action Block
```

### Scenario 4: AD-Integrated Zone Replication Failure

**Symptom:**
```
dnsServerStatus = "Warning"
Primary zone on DC1 differs from DC2
Event log: "DNS zone transfer failed"
```

**Investigation Steps:**

1. **Verify AD replication:**
```powershell
# Check AD replication status
repadmin /showrepl

# Check DNS-specific application partition
repadmin /showrepl * "DC=DomainDnsZones,DC=contoso,DC=com"
```

2. **Verify zone is AD-integrated:**
```powershell
Get-DnsServerZone -Name "contoso.com" | Select-Object ZoneName, IsDsIntegrated, DirectoryPartitionName

# Should show:
# IsDsIntegrated: True
# DirectoryPartitionName: DomainDnsZones.contoso.com
```

3. **Check DNS server AD site configuration:**
```powershell
# Verify DNS server is in correct AD site
Get-ADDomainController | Select-Object HostName, Site

# DNS replication may fail if site links misconfigured
```

**Resolution:**

1. **Force AD replication:**
```powershell
# Force replication from source DC
repadmin /syncall /AdeP

# Sync specific DNS partition
repadmin /replicate DC2.contoso.com DC1.contoso.com "DC=DomainDnsZones,DC=contoso,DC=com"
```

2. **Reload DNS zones from AD:**
```powershell
# On affected DNS server
Sync-DnsServerZone -Name "contoso.com" -Force

# Or restart DNS service
Restart-Service DNS
```

3. **Verify NTDS settings:**
```powershell
# Check DNS server registration in AD
Get-ADObject -Filter {objectClass -eq "nTDSDSA"} -SearchBase "CN=Configuration,DC=contoso,DC=com" -Properties *
```

---

## NinjaRMM Integration

### Automation Policy Setup

**Regular Monitoring (Every 4 Hours):**
```yaml
Policy Name: DNS Server - Health Check
Schedule: Every 4 hours (0:00, 4:00, 8:00, 12:00, 16:00, 20:00)
Script: DNSServerMonitor_v3.ps1
Timeout: 90 seconds
Context: SYSTEM
Conditions:
  - Device Role = DNS Server
  - OS Type = Windows Server
```

**Daily Configuration Audit:**
```yaml
Policy Name: DNS Server - Daily Configuration Review
Schedule: Daily at 2:00 AM
Script: DNSServerMonitor_v3.ps1
Timeout: 90 seconds
Purpose: Detect configuration drift, zone changes
```

### Alert Conditions

**Critical Alert - DNS Service Down:**
```
Condition: dnsServerStatus = "Critical"
Alert: Email + SMS + Ticket
Priority: P1
Subject: CRITICAL: DNS Service Failure - {{device.name}}
Body: |
  DNS service has stopped or failed.
  
  Status: {{custom.dnsServerStatus}}
  Zones: {{custom.dnsZoneCount}}
  
  IMMEDIATE ACTION REQUIRED - All network services affected.
  Name resolution is unavailable.
```

**Warning Alert - Configuration Issues:**
```
Condition: dnsServerStatus = "Warning"
Alert: Email + Ticket
Priority: P2
Subject: WARNING: DNS Configuration Issues - {{device.name}}
Body: |
  DNS diagnostics detected problems.
  
  Status: {{custom.dnsServerStatus}}
  Cache Hit Rate: {{custom.dnsCacheHitRate}}%
  Failed Queries: {{custom.dnsFailedQueryCount}}
  
  Review DNS server logs and zone transfer status.
```

**Performance Alert - High Query Rate:**
```
Condition: dnsQueriesPerSec > 1000 (adjust per environment)
Alert: Email
Subject: INFO: High DNS Query Rate - {{device.name}}
Body: |
  DNS server experiencing elevated query load.
  
  Current Rate: {{custom.dnsQueriesPerSec}} queries/sec
  Cache Hit Rate: {{custom.dnsCacheHitRate}}%
  
  Monitor for DDoS or misconfiguration.
```

**Cache Efficiency Alert:**
```
Condition: dnsCacheHitRate < 70
Alert: Email
Subject: WARNING: Low DNS Cache Efficiency - {{device.name}}
Body: |
  DNS cache hit rate below optimal threshold.
  
  Cache Hit Rate: {{custom.dnsCacheHitRate}}%
  Query Rate: {{custom.dnsQueriesPerSec}}/sec
  
  Review forwarder configuration and query patterns.
```

### Dashboard Widgets

**Zone Summary Widget:**
```
Widget Type: Custom Field Display
Field: dnsZoneSummary (WYSIWYG)
Title: DNS Zone Inventory
Description: Current DNS zone configuration
Refresh: On field update
```

**DNS Health Status Widget:**
```
Widget Type: Status Indicator
Field: dnsServerStatus
Title: DNS Server Health
Colors:
  Healthy: Green
  Warning: Yellow
  Critical: Red
  Unknown: Gray
```

**Performance Metrics Widget:**
```
Widget Type: Multi-Metric Display
Fields:
  - dnsZoneCount (Zones)
  - dnsQueriesPerSec (Query Rate)
  - dnsCacheHitRate (Cache Efficiency %)
  - dnsFailedQueryCount (Failed Queries)
Title: DNS Performance Metrics
```

---

## Advanced Customization

### Example 1: Zone Record Count Tracking

Track DNS record volume per zone for capacity planning:

```powershell
# Add after zone enumeration
Write-Output "INFO: Counting zone records..."

$zoneRecordCounts = @{}
foreach ($zone in $zones | Where-Object { $_.IsAutoCreated -eq $false -and $_.ZoneType -eq 'Primary' }) {
    try {
        $recordCount = (Get-DnsServerResourceRecord -ZoneName $zone.ZoneName -ErrorAction SilentlyContinue).Count
        $zoneRecordCounts[$zone.ZoneName] = $recordCount
        Write-Output "  $($zone.ZoneName): $recordCount records"
    } catch {
        Write-Output "  WARNING: Failed to count records in $($zone.ZoneName)"
    }
}

# Find zones with excessive records (potential performance impact)
$largeZones = $zoneRecordCounts.GetEnumerator() | Where-Object { $_.Value -gt 10000 } | Sort-Object Value -Descending

if ($largeZones) {
    $largeZoneReport = ($largeZones | ForEach-Object { "$($_.Key): $($_.Value) records" }) -join "<br>"
    Ninja-Property-Set dnsLargeZones $largeZoneReport
    
    Write-Output "  WARNING: Large zones detected (>10K records)"
}
```

### Example 2: DNSSEC Validation Monitoring

Track DNSSEC configuration for secure zones:

```powershell
# Add after zone enumeration
Write-Output "INFO: Checking DNSSEC status..."

$dnssecZones = @()
foreach ($zone in $zones | Where-Object { $_.IsAutoCreated -eq $false }) {
    try {
        if ($zone.IsSigned) {
            # Get DNSSEC key status
            $keys = Get-DnsServerDnsSecZoneSetting -ZoneName $zone.ZoneName -ErrorAction SilentlyContinue
            
            $dnssecZones += [PSCustomObject]@{
                ZoneName = $zone.ZoneName
                IsSigned = $true
                SigningMetadata = $keys.SigningMetadata.ToString()
            }
            
            Write-Output "  $($zone.ZoneName): DNSSEC enabled"
        }
    } catch {
        Write-Output "  WARNING: Failed to check DNSSEC for $($zone.ZoneName)"
    }
}

if ($dnssecZones) {
    $dnssecReport = ($dnssecZones | ForEach-Object { 
        "$($_.ZoneName) - Signed: $($_.IsSigned)" 
    }) -join "<br>"
    
    Ninja-Property-Set dnsDnssecZones $dnssecReport
    Write-Output "INFO: DNSSEC zones: $($dnssecZones.Count)"
}
```

### Example 3: Scavenging Configuration Audit

Ensure stale record cleanup is properly configured:

```powershell
# Add after server configuration
Write-Output "INFO: Auditing scavenging configuration..."

try {
    $serverSettings = Get-DnsServer
    $scavengingEnabled = $serverSettings.ServerSetting.ScavengingInterval
    
    Write-Output "  Server scavenging interval: $scavengingEnabled"
    
    # Check per-zone scavenging
    $scavengingIssues = @()
    foreach ($zone in $zones | Where-Object { $_.IsAutoCreated -eq $false -and $_.IsDsIntegrated -eq $true }) {
        $agingState = $zone.Aging
        
        if (-not $agingState -and $zone.DynamicUpdate -ne 'None') {
            $scavengingIssues += "Zone '$($zone.ZoneName)' has dynamic updates but aging/scavenging disabled"
            Write-Output "  WARNING: $($zone.ZoneName) - Scavenging disabled"
        }
    }
    
    if ($scavengingIssues.Count -gt 0) {
        $scavengingReport = $scavengingIssues -join "<br>"
        Ninja-Property-Set dnsScavengingIssues $scavengingReport
        
        if ($serverStatus -eq "Healthy") {
            $serverStatus = "Warning"
            Write-Output "  ASSESSMENT: Warning - Scavenging configuration issues"
        }
    }
} catch {
    Write-Output "WARNING: Failed to check scavenging: $_"
}
```

### Example 4: Query Pattern Analysis

Identify top queried domains for optimization:

```powershell
# Requires DNS debug logging enabled (performance impact - use sparingly)
Write-Output "INFO: Analyzing query patterns..."

try {
    # Enable debug logging temporarily (5 minutes)
    Set-DnsServerDiagnostics -Queries $true -QueryErrors $false `
        -FilterIPAddressList @() -LogFilePath "C:\DNSQueryAnalysis"
    
    Write-Output "  Collecting query data for 5 minutes..."
    Start-Sleep -Seconds 300
    
    # Parse log file
    $logFile = "C:\Windows\System32\dns\dns.log"
    if (Test-Path $logFile) {
        $queryData = Get-Content $logFile | 
            Select-String "QUERY" | 
            ForEach-Object { 
                $parts = $_ -split " "
                [PSCustomObject]@{
                    Query = $parts[10]
                    Type = $parts[11]
                }
            }
        
        $topQueries = $queryData | Group-Object Query | 
            Sort-Object Count -Descending | Select-Object -First 10
        
        $queryReport = ($topQueries | ForEach-Object { 
            "$($_.Name): $($_.Count) queries" 
        }) -join "<br>"
        
        Ninja-Property-Set dnsTopQueries $queryReport
        Write-Output "INFO: Top queries captured"
    }
    
    # Disable debug logging
    Set-DnsServerDiagnostics -Queries $false
    
} catch {
    Write-Output "WARNING: Query analysis failed: $_"
    Set-DnsServerDiagnostics -Queries $false  # Ensure disabled
}
```

### Example 5: Split-Brain DNS Detection

Verify internal/external zone consistency:

```powershell
# Add after zone enumeration
Write-Output "INFO: Checking for split-brain DNS configuration..."

try {
    # Define zones that should exist in both internal and external DNS
    $splitBrainZones = @('contoso.com', 'www.contoso.com')
    
    $splitBrainStatus = @()
    foreach ($zoneName in $splitBrainZones) {
        # Check internal resolution
        $internalRecord = Resolve-DnsName $zoneName -Server 127.0.0.1 -ErrorAction SilentlyContinue
        
        # Check external resolution (via forwarder)
        $externalRecord = Resolve-DnsName $zoneName -Server 8.8.8.8 -ErrorAction SilentlyContinue
        
        if ($internalRecord -and $externalRecord) {
            $internalIP = $internalRecord.IPAddress
            $externalIP = $externalRecord.IPAddress
            
            if ($internalIP -ne $externalIP) {
                $splitBrainStatus += "$zoneName: Internal=$internalIP, External=$externalIP"
                Write-Output "  Split-brain confirmed: $zoneName"
            }
        }
    }
    
    if ($splitBrainStatus) {
        $splitBrainReport = $splitBrainStatus -join "<br>"
        Ninja-Property-Set dnsSplitBrainZones $splitBrainReport
    }
} catch {
    Write-Output "WARNING: Split-brain detection failed: $_"
}
```

### Example 6: Root Hints Validation

Ensure root hints are current:

```powershell
# Add after server configuration
Write-Output "INFO: Validating root hints..."

try {
    $rootHints = Get-DnsServerRootHint
    $rootHintCount = $rootHints.Count
    
    Write-Output "  Root hints configured: $rootHintCount"
    
    # Test connectivity to root servers
    $workingRootServers = 0
    foreach ($hint in $rootHints | Select-Object -First 3) {  # Test first 3 only
        $testResult = Test-NetConnection -ComputerName $hint.IPAddress -Port 53 -InformationLevel Quiet
        if ($testResult) {
            $workingRootServers++
        }
    }
    
    Write-Output "  Working root servers: $workingRootServers/3 tested"
    
    if ($workingRootServers -eq 0 -and $forwarders -eq "None") {
        Write-Output "  WARNING: No root servers reachable and no forwarders configured"
        
        if ($serverStatus -eq "Healthy") {
            $serverStatus = "Warning"
        }
    }
    
    Ninja-Property-Set dnsRootHintCount $rootHintCount
    Ninja-Property-Set dnsWorkingRootServers $workingRootServers
    
} catch {
    Write-Output "WARNING: Root hint validation failed: $_"
}
```

---

## Troubleshooting Guide

### Issue: Zone Enumeration Fails

**Symptoms:**
- `dnsZoneSummary = "Unable to retrieve zone information"`
- Script completes but no zones shown

**Causes:**
- DnsServer module not loaded
- Permissions issue
- DNS service initializing

**Solutions:**

1. **Verify module availability:**
```powershell
Get-Module -ListAvailable DnsServer

# If missing, repair DNS feature
Add-WindowsFeature -Name DNS -IncludeManagementTools
```

2. **Check script execution context:**
```powershell
# SYSTEM account needs proper permissions
# Run script as administrator for testing:
Start-Process powershell -Verb RunAs
```

3. **Wait for DNS service initialization:**
```powershell
# Add delay after service check
$dnsService = Get-Service DNS
if ($dnsService.Status -eq 'Running') {
    Start-Sleep -Seconds 5  # Allow initialization
}
```

### Issue: Performance Counter Not Available

**Symptoms:**
- `dnsQueriesPerSec = 0` despite active queries
- "Performance counters not accessible" in logs

**Causes:**
- Performance counter registry corruption
- DNS service recently restarted
- Counter disabled

**Solutions:**

1. **Rebuild performance counters:**
```powershell
# Run from elevated command prompt
cd C:\Windows\System32
lodctr /R
winmgmt /resyncperf
```

2. **Verify counter exists:**
```powershell
Get-Counter -ListSet DNS | Select-Object -ExpandProperty Counter

# Should include "\DNS\Total Query Received/sec"
```

3. **Use alternative method:**
```powershell
# Query statistics instead
$stats = Get-DnsServerStatistics
$totalQueries = $stats.TotalQueries
# Calculate rate based on uptime
```

### Issue: Test-DnsServer Always Reports Warnings

**Symptoms:**
- `dnsServerStatus = "Warning"` persistently
- Test-DnsServer shows recurring failures

**Causes:**
- Known configuration (e.g., recursion disabled by design)
- Internet connectivity issues (expected in air-gapped environments)
- Stale root hints

**Solutions:**

1. **Review specific failures:**
```powershell
$diagnostics = Test-DnsServer
$diagnostics | Where-Object { $_.Result -eq 'Failure' } | Format-Table Name, Result, Context
```

2. **Exclude expected failures:**
```powershell
# Modify script to ignore known issues
$failedTests = $serverDiagnostics | Where-Object { 
    $_.Result -eq 'Failure' -and 
    $_.Name -notin @('Forwarders', 'RootHints')  # Exclude if air-gapped
}
```

3. **Fix underlying issues:**
```powershell
# Update root hints if stale
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://www.internic.net/domain/named.root" -OutFile "C:\Windows\System32\dns\cache.dns"
Restart-Service DNS
```

### Issue: Cache Statistics Missing

**Symptoms:**
- `dnsCacheHitRate = 0` always
- Statistics cmdlet returns no cache data

**Causes:**
- DNS service recently started (no cache history)
- Statistics collection disabled
- Cache cleared

**Solutions:**

1. **Wait for cache to populate:**
```powershell
# Check service uptime
$dnsService = Get-Service DNS
$serviceStart = (Get-Process -Name dns).StartTime
$uptime = (Get-Date) - $serviceStart

if ($uptime.TotalMinutes -lt 15) {
    Write-Output "INFO: DNS service recently started, cache building"
}
```

2. **Verify cache settings:**
```powershell
$cacheSettings = Get-DnsServerCache
$cacheSettings | Format-List

# Ensure MaxTtl and MaxNegativeTtl are reasonable
```

3. **Enable statistics:**
```powershell
Set-DnsServerDiagnostics -EnableLoggingForServerStartEvent $true
```

---

## Performance Optimization

### Parallel Zone Processing

For servers with hundreds of zones:

```powershell
# Use runspaces for parallel zone enumeration
$scriptBlock = {
    param($zone)
    
    try {
        $recordCount = (Get-DnsServerResourceRecord -ZoneName $zone.ZoneName -ErrorAction SilentlyContinue).Count
        
        return [PSCustomObject]@{
            ZoneName = $zone.ZoneName
            ZoneType = $zone.ZoneType
            RecordCount = $recordCount
            DynamicUpdate = $zone.DynamicUpdate
            IsDsIntegrated = $zone.IsDsIntegrated
        }
    } catch {
        return $null
    }
}

# Create runspace pool
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
$runspacePool.Open()

$jobs = @()
foreach ($zone in $zones | Where-Object { $_.IsAutoCreated -eq $false }) {
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($zone)
    $powershell.RunspacePool = $runspacePool
    
    $jobs += [PSCustomObject]@{
        Pipe = $powershell
        Result = $powershell.BeginInvoke()
    }
}

# Collect results
$zoneDetails = $jobs | ForEach-Object {
    $result = $_.Pipe.EndInvoke($_.Result)
    $_.Pipe.Dispose()
    $result
} | Where-Object { $null -ne $_ }

$runspacePool.Close()
$runspacePool.Dispose()
```

### Cached Statistics

Reduce performance counter overhead:

```powershell
# Cache performance metrics for 5 minutes
$cacheFile = "C:\ProgramData\DNSMonitor\PerfCache.xml"
$cacheMaxAge = 5  # minutes

if (Test-Path $cacheFile) {
    $cacheAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
    
    if ($cacheAge.TotalMinutes -lt $cacheMaxAge) {
        # Use cached data
        $cachedData = Import-Clixml $cacheFile
        $queriesPerSec = $cachedData.QueriesPerSec
        $cacheHitRate = $cachedData.CacheHitRate
        
        Write-Output "INFO: Using cached performance data"
    } else {
        # Refresh cache
        # ... collect fresh data ...
        $cacheData = @{
            QueriesPerSec = $queriesPerSec
            CacheHitRate = $cacheHitRate
            Timestamp = Get-Date
        }
        $cacheData | Export-Clixml $cacheFile
    }
}
```

---

## Integration Examples

### Example 1: Splunk Integration

Export DNS metrics to Splunk for analysis:

```powershell
# After metrics collection
$splunkHEC = "https://splunk.contoso.com:8088/services/collector"
$splunkToken = "your-hec-token"

$splunkEvent = @{
    event = @{
        dns_server = $env:COMPUTERNAME
        zone_count = $zoneCount
        queries_per_sec = $queriesPerSec
        cache_hit_rate = $cacheHitRate
        failed_queries = $failedQueryCount
        recursion_enabled = $recursionEnabled
        forwarders = $forwarders
        status = $serverStatus
    }
    sourcetype = "dns_monitoring"
    index = "infrastructure"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Splunk $splunkToken"
}

Invoke-RestMethod -Method Post -Uri $splunkHEC `
    -Headers $headers -Body $splunkEvent `
    -ContentType "application/json"
```

### Example 2: Azure Monitor Integration

Send DNS telemetry to Azure Log Analytics:

```powershell
# Azure Log Analytics ingestion
$workspaceId = "your-workspace-id"
$sharedKey = "your-shared-key"
$logType = "DNSServerMetrics"

$jsonBody = @(
    @{
        Computer = $env:COMPUTERNAME
        ZoneCount = $zoneCount
        QueriesPerSec = $queriesPerSec
        CacheHitRate = $cacheHitRate
        FailedQueries = $failedQueryCount
        ServerStatus = $serverStatus
        Timestamp = (Get-Date).ToUniversalTime().ToString("o")
    }
) | ConvertTo-Json

# Build signature for authentication
$method = "POST"
$contentType = "application/json"
$resource = "/api/logs"
$rfc1123date = [DateTime]::UtcNow.ToString("r")
$contentLength = $jsonBody.Length

$xHeaders = "x-ms-date:" + $rfc1123date
$stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
$keyBytes = [Convert]::FromBase64String($sharedKey)
$sha256 = New-Object System.Security.Cryptography.HMACSHA256
$sha256.Key = $keyBytes
$calculatedHash = $sha256.ComputeHash($bytesToHash)
$encodedHash = [Convert]::ToBase64String($calculatedHash)
$authorization = 'SharedKey {0}:{1}' -f $workspaceId, $encodedHash

$headers = @{
    "Authorization" = $authorization
    "Log-Type" = $logType
    "x-ms-date" = $rfc1123date
}

$uri = "https://" + $workspaceId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

Invoke-RestMethod -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $jsonBody
```

---

## Summary

**DNSServerMonitor_v3.ps1** provides comprehensive monitoring for Windows DNS Server infrastructure, offering deep visibility into zone configuration, query performance, cache efficiency, and resolution health. As DNS failures cascade to all dependent services, this monitoring is critical for maintaining network availability.

### Key Takeaways

1. **Foundational Service**: DNS outages impact all network services - monitoring is critical
2. **Cache Optimization**: High cache hit rates (>80%) improve performance and reduce bandwidth
3. **Security Configuration**: Proper recursion and forwarder settings prevent exploitation
4. **Zone Health**: Regular zone transfer and AD replication monitoring prevents inconsistencies
5. **Performance Baselines**: Establish normal query rates to detect anomalies and attacks

### Recommended Implementation

- **Regular Monitoring**: Every 4 hours for ongoing health checks
- **Daily Configuration Audit**: 2:00 AM for configuration drift detection
- **Critical Alerts**: Immediate notification for service failures
- **Warning Alerts**: Email for Test-DnsServer failures, low cache efficiency
- **Dashboard Integration**: Visual zone inventory and performance metrics

---

**Script Location:** [`plaintext_scripts/DNSServerMonitor_v3.ps1`](https://github.com/Xore/waf/blob/main/plaintext_scripts/DNSServerMonitor_v3.ps1)

**Related Documentation:**
- [Monitoring Overview](../Monitoring-Overview.md)
- [NinjaRMM Custom Fields Guide](../NinjaRMM-CustomFields.md)
- [Alert Configuration Guide](../Alert-Configuration.md)
- [DHCP Server Monitoring](./DHCPServerMonitor-DeepDive.md) (complementary network service)

**Last Updated:** February 11, 2026  
**Framework Version:** 4.0