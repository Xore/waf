# FileServerMonitor_v3.ps1 - Deep Dive Guide

## Overview

**FileServerMonitor_v3.ps1** is a comprehensive monitoring solution for Windows File Server infrastructure, tracking SMB share configuration, active usage patterns, quota compliance, and access issues. This script is essential for preventing storage exhaustion, detecting permission problems, and managing file server capacity in enterprise environments.

### Key Capabilities

- **Share Inventory Management**: Automated enumeration and size calculation for all SMB shares
- **Real-time Usage Monitoring**: Tracks open files and connected users for capacity planning
- **Quota Compliance**: FSRM integration to detect quota violations before users are blocked
- **Access Error Detection**: Monitors SMB protocol errors indicating permission or configuration issues
- **Health Status Assessment**: Multi-factor health scoring based on errors and quota violations
- **Dashboard Integration**: HTML-formatted share summaries for visual monitoring

---

## Technical Architecture

### Monitoring Scope

```
File Server Infrastructure
├── Role Detection
│   ├── FS-FileServer feature verification
│   ├── SMB PowerShell module availability
│   └── Graceful exit if role not installed
│
├── Share Inventory
│   ├── SMB share enumeration (non-administrative)
│   ├── Share path validation
│   ├── Recursive size calculation
│   └── HTML table generation
│
├── Usage Tracking
│   ├── Open file handle counting
│   ├── SMB session enumeration
│   └── Unique user identification
│
├── Quota Management (FSRM)
│   ├── FS-Resource-Manager detection
│   ├── Quota configuration enumeration
│   ├── Usage vs. limit comparison
│   └── Violation identification
│
└── Error Monitoring
    ├── System event log queries
    ├── SMBServer provider filtering
    ├── 24-hour error aggregation
    └── Critical/error level separation
```

### Data Collection Flow

```
1. Role Verification
   └─→ FS-FileServer installed?
       ├─→ No: Record Unknown status, exit gracefully
       └─→ Yes: Continue monitoring

2. Share Enumeration
   └─→ Get-SmbShare (exclude Special)
       └─→ For each share:
           ├─→ Validate path accessibility
           ├─→ Calculate folder tree size (Get-ChildItem -Recurse)
           ├─→ Build HTML table row
           └─→ Handle access denied gracefully

3. Usage Monitoring
   ├─→ Get-SmbOpenFile → Count active file handles
   └─→ Get-SmbSession → Count unique users

4. Quota Checking
   └─→ FS-Resource-Manager installed?
       ├─→ No: Skip quota monitoring
       └─→ Yes: Get-FsrmQuota → Identify violations (Usage > Limit)

5. Error Analysis
   └─→ Query System log
       ├─→ Provider: Microsoft-Windows-SMBServer
       ├─→ Level: 1 (Critical), 2 (Error)
       ├─→ Time: Last 24 hours
       └─→ Count total errors

6. Health Classification
   └─→ accessErrors24h > 50? → Critical
   └─→ quotaViolations > 0 OR accessErrors24h > 10? → Warning
   └─→ Else: Healthy
```

---

## Field Reference

### Custom Fields Configuration

```powershell
# Boolean Fields
fsFileServerRole          # Checkbox: File Server role installed

# Integer Fields
fsShareCount              # Count of non-administrative shares
fsOpenFilesCount          # Currently open file handles across all shares
fsConnectedUsers          # Unique active SMB sessions
fsQuotaViolations         # FSRM quotas where Usage > Limit
fsAccessErrors24h         # SMB errors in last 24 hours

# Text/WYSIWYG Fields
fsShareSummary            # WYSIWYG: HTML formatted share table
fsHealthStatus            # Text: Healthy|Warning|Critical|Unknown
```

### Field Value Examples

**Healthy File Server:**
```
fsFileServerRole = true
fsShareCount = 8
fsShareSummary = [HTML table with 8 shares, sizes calculated]
fsOpenFilesCount = 23
fsConnectedUsers = 12
fsQuotaViolations = 0
fsAccessErrors24h = 2
fsHealthStatus = "Healthy"
```

**Warning State (Quota Issue):**
```
fsQuotaViolations = 3
fsAccessErrors24h = 15
fsHealthStatus = "Warning"
```

**Critical State (Access Failures):**
```
fsAccessErrors24h = 78
fsHealthStatus = "Critical"
```

---

## Monitoring Logic Details

### Share Size Calculation

The script performs recursive folder enumeration to calculate share sizes, which can be time-consuming for large file structures:

```powershell
# Size calculation logic
if ($sharePath -and (Test-Path $sharePath)) {
    try {
        $folderSize = (Get-ChildItem -Path $sharePath -Recurse -File -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum
        $shareSizeGB = [Math]::Round($folderSize / 1GB, 2)
        $shareSize = "$shareSizeGB GB"
    } catch {
        $shareSize = "Unknown"
    }
}
```

**Performance Considerations:**
- **Small shares** (<10K files): ~2-5 seconds per share
- **Medium shares** (10K-100K files): ~10-30 seconds per share
- **Large shares** (>100K files): 30+ seconds, may timeout

**Optimization Options:**
1. Disable size calculation for specific shares
2. Cache sizes and update weekly instead of daily
3. Use FSRM reports instead of real-time calculation
4. Increase script timeout for environments with large shares

### Quota Violation Detection

FSRM integration provides proactive quota monitoring:

```powershell
# Quota monitoring requires FS-Resource-Manager
$fsrmFeature = Get-WindowsFeature -Name "FS-Resource-Manager"

if ($fsrmFeature -and $fsrmFeature.Installed) {
    $quotas = Get-FsrmQuota
    $quotaViolations = ($quotas | Where-Object { $_.Usage -gt $_.Limit }).Count
}
```

**Quota Types:**
- **Hard quotas**: Block writes when exceeded (immediate user impact)
- **Soft quotas**: Send warnings but allow writes (monitoring only)

**Violation Scenarios:**
- User home directories approaching limits
- Departmental shares exhausting allocation
- Temporary/staging folders not cleaned up

### Access Error Detection

SMB protocol errors indicate permission, authentication, or configuration problems:

```powershell
# Event log query for SMB errors
$fsErrors = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-SMBServer'
    Level = 1,2  # Critical and Error
    StartTime = (Get-Date).AddHours(-24)
}
```

**Common Error Event IDs:**
- **Event 1020**: Session setup failed (authentication issue)
- **Event 1006**: Client connection failed
- **Event 1014**: Access denied to share or file
- **Event 551**: Unexpected network error

**Severity Thresholds:**
- **0-10 errors/24h**: Normal (transient issues, scanning software)
- **10-50 errors/24h**: Warning (investigate permission issues)
- **>50 errors/24h**: Critical (widespread access problems)

### Health Status Logic

Multi-factor health assessment:

```
Health Status Decision Tree:

accessErrors24h > 50?
├─→ Yes: CRITICAL
└─→ No: Check next condition
    
    quotaViolations > 0 OR accessErrors24h > 10?
    ├─→ Yes: WARNING
    └─→ No: HEALTHY
```

**Status Meanings:**
- **Healthy**: Normal operations, minimal errors, quotas compliant
- **Warning**: Minor issues requiring attention (quota violations, elevated errors)
- **Critical**: Service degraded, high error rate affecting multiple users
- **Unknown**: Role not installed or monitoring failure

---

## Real-World Scenarios

### Scenario 1: Department Share Quota Exhaustion

**Symptom:**
```
fsQuotaViolations = 1
fsHealthStatus = "Warning"
fsShareSummary shows "Marketing" share at 98% capacity
```

**Investigation Steps:**

1. **Identify the violating quota:**
```powershell
Get-FsrmQuota | Where-Object { $_.Usage -gt $_.Limit } | Select-Object Path, Usage, Limit
```

2. **Find largest folders within share:**
```powershell
$sharePath = "E:\Shares\Marketing"
Get-ChildItem $sharePath -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum).Sum / 1GB
    [PSCustomObject]@{
        Folder = $_.Name
        SizeGB = [Math]::Round($size, 2)
    }
} | Sort-Object SizeGB -Descending | Select-Object -First 10
```

3. **Common causes:**
   - Old project archives not deleted
   - Users storing personal media files
   - Duplicated files/folders
   - Database backups saved to share

**Resolution Options:**
- Increase quota limit if growth is legitimate
- Archive old projects to secondary storage
- Implement file screening to block media types
- Enable duplicate file detection and removal
- Train users on storage policies

### Scenario 2: High SMB Access Errors

**Symptom:**
```
fsAccessErrors24h = 65
fsHealthStatus = "Critical"
Multiple "access denied" errors in event log
```

**Investigation Steps:**

1. **Review specific error events:**
```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-SMBServer'
    Level = 2
    StartTime = (Get-Date).AddHours(-24)
} | Select-Object TimeCreated, Id, Message | Format-Table -AutoSize
```

2. **Check for common issues:**
```powershell
# Review share permissions
Get-SmbShare | Select-Object Name, Path | ForEach-Object {
    $acl = Get-Acl $_.Path
    [PSCustomObject]@{
        Share = $_.Name
        Path = $_.Path
        Permissions = ($acl.Access | Select-Object -ExpandProperty IdentityReference) -join ', '
    }
}

# Check for disabled users with open sessions
Get-SmbSession | Select-Object ClientUserName | ForEach-Object {
    $user = Get-ADUser $_.ClientUserName -Properties Enabled -ErrorAction SilentlyContinue
    if ($user -and -not $user.Enabled) {
        Write-Output "WARNING: Disabled user $($_.ClientUserName) has active SMB session"
    }
}
```

**Common Root Causes:**
- Recent AD group membership changes affecting permissions
- Share permissions not synchronized with NTFS permissions
- Service accounts with expired passwords
- DFS namespace errors
- Antivirus software blocking file access

**Resolution:**
- Audit and align share/NTFS permissions
- Reset service account passwords
- Review recent group policy changes
- Check antivirus exclusions

### Scenario 3: File Locking Issues

**Symptom:**
```
fsOpenFilesCount = 347 (unusually high)
fsConnectedUsers = 12 (normal)
User complaints: "File in use by another user"
```

**Investigation Steps:**

1. **Identify locked files:**
```powershell
Get-SmbOpenFile | Select-Object ClientUserName, Path, 
    @{N='OpenDuration';E={(Get-Date) - $_.SessionId.CreationTime}} |
    Sort-Object OpenDuration -Descending | Format-Table -AutoSize
```

2. **Find users with excessive open files:**
```powershell
Get-SmbOpenFile | Group-Object ClientUserName | 
    Select-Object Name, Count | Sort-Object Count -Descending
```

3. **Check for stale locks:**
```powershell
# Files open > 24 hours (potential stale locks)
$staleThreshold = (Get-Date).AddHours(-24)
Get-SmbOpenFile | Where-Object { 
    $_.SessionId.CreationTime -lt $staleThreshold 
} | Select-Object ClientUserName, Path, SessionId
```

**Resolution Options:**
- Close specific stale file handles: `Close-SmbOpenFile -FileId <ID> -Force`
- Disconnect user sessions: `Close-SmbSession -SessionId <ID> -Force`
- Investigate application not releasing handles properly
- Implement OpLocks tuning for database applications

### Scenario 4: Shadow Copy Storage Exhaustion

**Symptom:**
```
fsShareSummary shows System Volume Information consuming 150 GB
Shadow copy errors in event log
```

**Investigation Steps:**

1. **Check shadow copy configuration:**
```powershell
vssadmin List ShadowStorage
vssadmin List Shadows
```

2. **Review shadow copy space allocation:**
```powershell
Get-WmiObject Win32_ShadowStorage | Select-Object AllocatedSpace, UsedSpace, MaxSpace
```

**Resolution:**
- Increase shadow copy storage allocation
- Reduce retention period
- Delete old shadow copies
- Move shadow storage to separate volume

---

## NinjaRMM Integration

### Automation Policy Setup

**Daily Configuration Monitoring:**
```yaml
Policy Name: File Server - Daily Configuration Check
Schedule: Daily at 2:00 AM
Script: FileServerMonitor_v3.ps1
Timeout: 120 seconds
Context: SYSTEM
Conditions: 
  - Device Role = File Server
  - OS Type = Windows Server
```

**Usage Monitoring (Every 4 Hours):**
```yaml
Policy Name: File Server - Usage Tracking
Schedule: Every 4 hours (6 AM, 10 AM, 2 PM, 6 PM, 10 PM)
Script: FileServerMonitor_v3.ps1
Timeout: 120 seconds
Context: SYSTEM
Purpose: Track open files and connected users
```

### Alert Conditions

**Critical Alert - High Error Rate:**
```
Condition: fsAccessErrors24h > 50
Alert: Email + Ticket
Subject: CRITICAL: File Server Access Failures - {{device.name}}
Body: |
  File server experiencing high access error rate.
  
  Errors (24h): {{custom.fsAccessErrors24h}}
  Status: {{custom.fsHealthStatus}}
  Shares: {{custom.fsShareCount}}
  
  Immediate investigation required - users may be unable to access files.
```

**Warning Alert - Quota Violations:**
```
Condition: fsQuotaViolations > 0
Alert: Email
Subject: WARNING: Storage Quota Violations - {{device.name}}
Body: |
  Users are being blocked from writing files due to quota violations.
  
  Quota Violations: {{custom.fsQuotaViolations}}
  
  Action required to increase quotas or free up space.
```

**Capacity Alert - High Usage:**
```
Condition: fsOpenFilesCount > 500
Alert: Email
Subject: INFO: High File Server Load - {{device.name}}
Body: |
  File server experiencing high usage.
  
  Open Files: {{custom.fsOpenFilesCount}}
  Connected Users: {{custom.fsConnectedUsers}}
  
  Monitor performance and consider load balancing.
```

### Dashboard Widgets

**Share Summary Widget:**
```
Widget Type: Custom Field Display
Field: fsShareSummary (WYSIWYG)
Title: File Shares Inventory
Description: Current SMB share configuration and sizes
Refresh: On field update
```

**File Server Health Widget:**
```
Widget Type: Status Indicator
Field: fsHealthStatus
Title: File Server Health
Colors:
  Healthy: Green
  Warning: Yellow
  Critical: Red
  Unknown: Gray
```

**Usage Metrics Widget:**
```
Widget Type: Multi-Metric Display
Fields:
  - fsShareCount (Shares)
  - fsOpenFilesCount (Open Files)
  - fsConnectedUsers (Active Users)
  - fsQuotaViolations (Quota Issues)
Title: File Server Activity
```

---

## Advanced Customization

### Example 1: Size Calculation Exclusions

Skip size calculation for specific shares to improve performance:

```powershell
# Define shares to skip size calculation
$skipSizeShares = @('LargeArchive', 'BackupDestination', 'ISOLibrary')

foreach ($share in $shares) {
    $sharePath = $share.Path
    $shareSize = "N/A"
    
    # Skip size calculation for excluded shares
    if ($share.Name -notin $skipSizeShares) {
        if ($sharePath -and (Test-Path $sharePath)) {
            try {
                $folderSize = (Get-ChildItem -Path $sharePath -Recurse -File -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
                $shareSizeGB = [Math]::Round($folderSize / 1GB, 2)
                $shareSize = "$shareSizeGB GB"
            } catch {
                $shareSize = "Unknown"
            }
        }
    } else {
        $shareSize = "Skipped (performance optimization)"
    }
    
    $htmlRows += "<tr><td>$($share.Name)</td><td>$sharePath</td><td>$shareSize</td></tr>"
}
```

### Example 2: Enhanced Quota Reporting

Add quota details to dashboard:

```powershell
# After quota violation check, add detailed reporting
if ($fsrmFeature -and $fsrmFeature.Installed) {
    $quotas = Get-FsrmQuota -ErrorAction SilentlyContinue
    
    if ($quotas) {
        $violatingQuotas = $quotas | Where-Object { $_.Usage -gt $_.Limit }
        $quotaViolations = $violatingQuotas.Count
        
        # Build quota violation details
        if ($violatingQuotas) {
            $quotaDetails = @()
            foreach ($quota in $violatingQuotas) {
                $usagePercent = [Math]::Round(($quota.Usage / $quota.Limit) * 100, 1)
                $quotaDetails += "• $($quota.Path): $usagePercent% ($($quota.Usage)GB / $($quota.Limit)GB)"
            }
            
            # Store in additional custom field
            $quotaViolationDetails = $quotaDetails -join "<br>"
            Ninja-Property-Set fsQuotaDetails $quotaViolationDetails
        }
    }
}
```

### Example 3: Top File Consumers Report

Identify users consuming the most storage:

```powershell
# Add this after share enumeration
Write-Output "INFO: Analyzing top storage consumers..."

$topConsumers = @()
foreach ($share in $shares) {
    if ($share.Path -and (Test-Path $share.Path)) {
        try {
            # Get folders in share root (typically user folders)
            $folders = Get-ChildItem -Path $share.Path -Directory -ErrorAction SilentlyContinue
            
            foreach ($folder in $folders) {
                try {
                    $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | 
                        Measure-Object -Property Length -Sum).Sum / 1GB
                    
                    $topConsumers += [PSCustomObject]@{
                        Share = $share.Name
                        Folder = $folder.Name
                        SizeGB = [Math]::Round($size, 2)
                    }
                } catch {
                    # Skip inaccessible folders
                }
            }
        } catch {
            # Skip inaccessible shares
        }
    }
}

# Get top 10 consumers
$top10 = $topConsumers | Sort-Object SizeGB -Descending | Select-Object -First 10

# Build HTML report
$consumerRows = $top10 | ForEach-Object {
    "<tr><td>$($_.Share)</td><td>$($_.Folder)</td><td>$($_.SizeGB) GB</td></tr>"
}

$consumerReport = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Share</th><th>Folder</th><th>Size</th></tr>
$($consumerRows -join "`n")
</table>
"@

Ninja-Property-Set fsTopConsumers $consumerReport
```

### Example 4: DFS Integration

Monitor DFS namespace health alongside shares:

```powershell
# Add DFS monitoring after share enumeration
Write-Output "INFO: Checking DFS namespace health..."

try {
    # Check if DFS role is installed
    $dfsRole = Get-WindowsFeature -Name "FS-DFS-Namespace" -ErrorAction SilentlyContinue
    
    if ($dfsRole -and $dfsRole.Installed) {
        $dfsRoots = Get-DfsnRoot -ErrorAction SilentlyContinue
        $dfsRootCount = if ($dfsRoots) { $dfsRoots.Count } else { 0 }
        
        Write-Output "INFO: DFS roots found: $dfsRootCount"
        
        # Check for offline folder targets
        $offlineTargets = 0
        foreach ($root in $dfsRoots) {
            $folders = Get-DfsnFolder -Path "$($root.Path)\*" -ErrorAction SilentlyContinue
            
            foreach ($folder in $folders) {
                $targets = Get-DfsnFolderTarget -Path $folder.Path -ErrorAction SilentlyContinue
                $offlineTargets += ($targets | Where-Object { $_.State -ne 'Online' }).Count
            }
        }
        
        Write-Output "INFO: DFS offline targets: $offlineTargets"
        
        # Store DFS metrics
        Ninja-Property-Set fsDfsRootCount $dfsRootCount
        Ninja-Property-Set fsDfsOfflineTargets $offlineTargets
        
        # Adjust health status if DFS issues detected
        if ($offlineTargets -gt 0 -and $healthStatus -eq "Healthy") {
            $healthStatus = "Warning"
            Write-Output "  ASSESSMENT: Warning - DFS targets offline"
        }
    }
} catch {
    Write-Output "WARNING: Failed to check DFS health: $_"
}
```

### Example 5: Access-Based Enumeration (ABE) Verification

Ensure ABE is enabled for security-sensitive shares:

```powershell
# Add ABE check after share enumeration
Write-Output "INFO: Verifying Access-Based Enumeration (ABE) configuration..."

$abeIssues = @()
$abeSensitiveShares = @('Finance', 'HR', 'Legal', 'Executive')

foreach ($share in $shares) {
    if ($share.Name -in $abeSensitiveShares) {
        $abeEnabled = $share.FolderEnumerationMode -eq 'AccessBased'
        
        if (-not $abeEnabled) {
            $abeIssues += "Share '$($share.Name)' should have ABE enabled"
            Write-Output "  WARNING: ABE not enabled on $($share.Name)"
        }
    }
}

if ($abeIssues.Count -gt 0) {
    $abeReport = $abeIssues -join "<br>"
    Ninja-Property-Set fsAbeIssues $abeReport
    
    if ($healthStatus -eq "Healthy") {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - ABE configuration issues"
    }
}
```

### Example 6: SMB Protocol Version Audit

Ensure SMB1 is disabled for security:

```powershell
# Add SMB protocol version check
Write-Output "INFO: Auditing SMB protocol versions..."

try {
    $smbConfig = Get-SmbServerConfiguration
    
    $smb1Enabled = $smbConfig.EnableSMB1Protocol
    $smb2Enabled = $smbConfig.EnableSMB2Protocol
    
    Write-Output "  SMB1 Enabled: $smb1Enabled"
    Write-Output "  SMB2/3 Enabled: $smb2Enabled"
    
    Ninja-Property-Set fsSmb1Enabled $smb1Enabled
    
    if ($smb1Enabled) {
        Write-Output "  WARNING: SMB1 is enabled (security risk)"
        
        if ($healthStatus -eq "Healthy") {
            $healthStatus = "Warning"
            Write-Output "  ASSESSMENT: Warning - SMB1 security risk"
        }
    }
} catch {
    Write-Output "WARNING: Failed to check SMB configuration: $_"
}
```

---

## Troubleshooting Guide

### Issue: Script Times Out

**Symptoms:**
- Script exceeds 120-second timeout
- Partial data collected
- NinjaRMM reports "Script timeout"

**Causes:**
- Large shares with millions of files
- Slow storage (network shares, USB drives)
- Multiple large shares on single server

**Solutions:**

1. **Increase script timeout:**
```yaml
NinjaRMM Policy Settings:
  Timeout: 300 seconds (5 minutes)
```

2. **Disable size calculation:**
```powershell
# Skip size calculation entirely
$shareSize = "Size calculation disabled"
```

3. **Run size calculation separately:**
   - Daily config check: Skip sizes
   - Weekly capacity report: Include sizes

4. **Implement caching:**
```powershell
# Cache share sizes for 7 days
$cacheFile = "C:\ProgramData\FileServerMonitor\ShareSizes.xml"
$cacheAge = (Get-Item $cacheFile -ErrorAction SilentlyContinue).LastWriteTime

if ($cacheAge -and $cacheAge -gt (Get-Date).AddDays(-7)) {
    # Use cached sizes
    $cachedSizes = Import-Clixml $cacheFile
} else {
    # Calculate and cache
    # ... size calculation logic ...
    $sizesObject | Export-Clixml $cacheFile
}
```

### Issue: Access Denied Errors

**Symptoms:**
- Share sizes show "Unknown"
- Event log errors during script execution
- Incomplete share enumeration

**Causes:**
- SYSTEM account lacks permissions
- Share path inaccessible
- Network path delays

**Solutions:**

1. **Grant SYSTEM read access:**
```powershell
# Add SYSTEM to share path ACL
$acl = Get-Acl "E:\Shares\Finance"
$permission = "NT AUTHORITY\SYSTEM","Read","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "E:\Shares\Finance" $acl
```

2. **Run as domain admin (not recommended for production):**
```yaml
NinjaRMM Script Settings:
  Run As: Domain Admin Service Account
  (Only for troubleshooting)
```

3. **Skip inaccessible shares:**
```powershell
# Already implemented in script with -ErrorAction SilentlyContinue
```

### Issue: FSRM Quota Data Missing

**Symptoms:**
- `fsQuotaViolations = 0` despite known issues
- No quota data in logs

**Causes:**
- FS-Resource-Manager not installed
- FSRM service not running
- Quota cmdlets not available

**Solutions:**

1. **Install FSRM:**
```powershell
Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools
```

2. **Verify service:**
```powershell
Get-Service srmsvc | Start-Service
```

3. **Test quota cmdlets:**
```powershell
Get-FsrmQuota
# Should return configured quotas
```

### Issue: Incorrect Connected User Count

**Symptoms:**
- `fsConnectedUsers` is 0 despite active users
- Count doesn't match observed usage

**Causes:**
- Sessions established through DFS (not direct SMB)
- Cached credentials
- Session enumeration timing

**Solutions:**

1. **Include DFS sessions:**
```powershell
# Get sessions from DFS as well
$smbSessions = Get-SmbSession
$dfsSessions = Get-DfsnServerConfiguration | Get-DfsnRootTarget
$totalSessions = $smbSessions.Count + $dfsSessions.Count
```

2. **Check session cache:**
```powershell
# Sessions may be cached - verify with network statistics
Get-NetTCPConnection -LocalPort 445 -State Established | Group-Object RemoteAddress
```

### Issue: Event Log Query Performance

**Symptoms:**
- Script slow during error checking
- High CPU during event log queries

**Causes:**
- Large System event log (>100 MB)
- Excessive SMB events

**Solutions:**

1. **Limit event query scope:**
```powershell
# Query only last 6 hours instead of 24
$startTime = (Get-Date).AddHours(-6)
$fsErrors = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-SMBServer'
    Level = 1,2
    StartTime = $startTime
    MaxEvents = 100  # Limit results
}
```

2. **Archive old event logs:**
```powershell
wevtutil.exe cl System /bu:C:\EventArchive\System.evtx
```

3. **Use event forwarding:**
   - Configure event forwarding to SIEM
   - Query SIEM instead of local logs

---

## Performance Optimization

### Parallel Share Processing

For servers with many shares, use parallel processing:

```powershell
# Parallel share enumeration using runspaces
$scriptBlock = {
    param($share)
    
    $sharePath = $share.Path
    $shareSize = "N/A"
    
    if ($sharePath -and (Test-Path $sharePath)) {
        try {
            $folderSize = (Get-ChildItem -Path $sharePath -Recurse -File -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum
            $shareSize = [Math]::Round($folderSize / 1GB, 2)
        } catch {
            $shareSize = "Unknown"
        }
    }
    
    return [PSCustomObject]@{
        Name = $share.Name
        Path = $sharePath
        Size = $shareSize
    }
}

# Create runspace pool
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
$runspacePool.Open()

$jobs = @()
foreach ($share in $shares) {
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($share)
    $powershell.RunspacePool = $runspacePool
    
    $jobs += [PSCustomObject]@{
        Pipe = $powershell
        Result = $powershell.BeginInvoke()
    }
}

# Wait for completion
$results = $jobs | ForEach-Object {
    $_.Pipe.EndInvoke($_.Result)
    $_.Pipe.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()

# Build HTML from results
foreach ($result in $results) {
    $htmlRows += "<tr><td>$($result.Name)</td><td>$($result.Path)</td><td>$($result.Size) GB</td></tr>"
}
```

### Incremental Monitoring

Separate frequent and infrequent checks:

```powershell
# Determine monitoring mode based on parameter
param(
    [ValidateSet('Full', 'Usage')]
    [string]$Mode = 'Full'
)

if ($Mode -eq 'Usage') {
    # Quick checks only (every 4 hours)
    # - Skip share size calculation
    # - Skip quota check
    # - Monitor open files, connected users, errors only
    
} else {
    # Full monitoring (daily)
    # - All checks including share sizes
}
```

**NinjaRMM Configuration:**
```yaml
Policy 1: File Server - Full Monitoring
  Schedule: Daily at 2 AM
  Parameters: -Mode Full

Policy 2: File Server - Usage Tracking
  Schedule: Every 4 hours
  Parameters: -Mode Usage
```

---

## Integration Examples

### Example 1: Microsoft Teams Notification

Send share capacity alerts to Teams channel:

```powershell
# After health status determination
if ($healthStatus -eq "Warning" -or $healthStatus -eq "Critical") {
    
    $teamsWebhook = "https://outlook.office.com/webhook/YOUR_WEBHOOK_URL"
    
    $teamsMessage = @{
        "@type" = "MessageCard"
        "@context" = "https://schema.org/extensions"
        "summary" = "File Server Alert: $healthStatus"
        "themeColor" = if ($healthStatus -eq "Critical") { "FF0000" } else { "FFA500" }
        "sections" = @(
            @{
                "activityTitle" = "File Server Health Alert"
                "activitySubtitle" = $env:COMPUTERNAME
                "facts" = @(
                    @{ "name" = "Status"; "value" = $healthStatus }
                    @{ "name" = "Shares"; "value" = $shareCount }
                    @{ "name" = "Open Files"; "value" = $openFilesCount }
                    @{ "name" = "Connected Users"; "value" = $connectedUsers }
                    @{ "name" = "Quota Violations"; "value" = $quotaViolations }
                    @{ "name" = "Access Errors (24h)"; "value" = $accessErrors24h }
                )
            }
        )
    }
    
    $jsonBody = $teamsMessage | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Method Post -Uri $teamsWebhook -Body $jsonBody -ContentType "application/json"
}
```

### Example 2: ServiceNow Ticket Creation

Create incidents for critical file server issues:

```powershell
# ServiceNow integration for critical alerts
if ($healthStatus -eq "Critical") {
    
    $snowInstance = "your-instance.service-now.com"
    $snowUser = "integration-user"
    $snowPass = ConvertTo-SecureString "password" -AsPlainText -Force
    $snowCred = New-Object System.Management.Automation.PSCredential ($snowUser, $snowPass)
    
    $incidentBody = @{
        short_description = "File Server Critical: High Access Error Rate"
        description = @"
File Server: $env:COMPUTERNAME
Status: $healthStatus
Access Errors (24h): $accessErrors24h
Open Files: $openFilesCount
Connected Users: $connectedUsers

Immediate investigation required - users may be unable to access files.
"@
        urgency = "1"
        impact = "1"
        category = "Infrastructure"
        assignment_group = "Storage Team"
    } | ConvertTo-Json
    
    $snowUri = "https://$snowInstance/api/now/table/incident"
    
    Invoke-RestMethod -Method Post -Uri $snowUri -Credential $snowCred `
        -Body $incidentBody -ContentType "application/json"
}
```

### Example 3: Grafana Dashboard Integration

Export metrics for time-series visualization:

```powershell
# Export metrics to InfluxDB (Grafana backend)
$influxServer = "http://influxdb:8086"
$influxDB = "fileserver_metrics"
$influxMeasurement = "fileserver_health"

$metricsData = @(
    "share_count=$shareCount"
    "open_files=$openFilesCount"
    "connected_users=$connectedUsers"
    "quota_violations=$quotaViolations"
    "access_errors_24h=$accessErrors24h"
    "health_status_numeric=$($healthStatus -eq 'Healthy' ? 0 : $healthStatus -eq 'Warning' ? 1 : 2)"
) -join ","

$influxLine = "$influxMeasurement,host=$env:COMPUTERNAME $metricsData"

Invoke-RestMethod -Method Post -Uri "$influxServer/write?db=$influxDB" `
    -Body $influxLine -ContentType "text/plain"
```

---

## Summary

**FileServerMonitor_v3.ps1** provides enterprise-grade monitoring for Windows File Server infrastructure, offering comprehensive visibility into share configuration, usage patterns, quota compliance, and access issues. The script's multi-layered health assessment helps prevent storage exhaustion, detect permission problems, and maintain optimal file server performance.

### Key Takeaways

1. **Proactive Capacity Management**: Share size tracking and quota monitoring prevent user-blocking storage exhaustion
2. **Access Issue Detection**: SMB error monitoring identifies permission and configuration problems before widespread impact
3. **Performance Visibility**: Open file and session tracking helps capacity planning and load balancing
4. **Security Compliance**: Protocol version auditing and ABE verification ensure security best practices
5. **Flexible Deployment**: Customizable monitoring intervals and selective checks optimize performance

### Recommended Implementation

- **Daily Full Monitoring**: 2:00 AM - Complete inventory with size calculations
- **Usage Tracking**: Every 4 hours - Real-time activity monitoring
- **Critical Alerts**: Immediate notification for >50 errors/24h
- **Warning Alerts**: Email for quota violations or elevated errors
- **Dashboard Integration**: Visual share inventory and health status

---

**Script Location:** [`plaintext_scripts/FileServerMonitor_v3.ps1`](https://github.com/Xore/waf/blob/main/plaintext_scripts/FileServerMonitor_v3.ps1)

**Related Documentation:**
- [Monitoring Overview](../Monitoring-Overview.md)
- [NinjaRMM Custom Fields Guide](../NinjaRMM-CustomFields.md)
- [Alert Configuration Guide](../Alert-Configuration.md)

**Last Updated:** February 11, 2026  
**Framework Version:** 4.0