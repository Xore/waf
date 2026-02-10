# Hyper-V Monitoring Deployment Guide

**Target Audience:** System Administrators, RMM Operators  
**Estimated Time:** 30-60 minutes  
**Difficulty:** Intermediate

---

## Prerequisites

### System Requirements

**Hyper-V Host:**
- Windows Server 2016 or later
- Hyper-V role installed
- PowerShell 5.1 or later
- Minimum 2 GB free RAM
- NinjaRMM agent installed

**For Clustered Environments:**
- Failover Clustering feature installed
- All cluster nodes accessible
- Cluster service running

**Administrator Access:**
- Local administrator on Hyper-V hosts
- RMM administrator for NinjaOne
- Permissions to create custom fields

### Pre-Deployment Checklist

- [ ] Hyper-V role verified installed
- [ ] NinjaRMM agent installed and communicating
- [ ] PowerShell execution policy allows scripts
- [ ] Test Hyper-V cmdlets: `Get-VM`
- [ ] Test cluster cmdlets (if clustered): `Get-Cluster`
- [ ] Network connectivity verified
- [ ] Backup configuration documented

---

## Step 1: Create Custom Fields in NinjaRMM

### Script 1: Monitor Fields (14 fields)

**Navigate to:** Administration → Devices → Custom Fields → Add Field

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervInstalled` | Checkbox | Hyper-V role installed |
| `hypervVersion` | Text | Hyper-V version string |
| `hypervVMCount` | Integer | Total VMs configured |
| `hypervVMsRunning` | Integer | Running VMs |
| `hypervVMsStopped` | Integer | Stopped VMs |
| `hypervVMsOther` | Integer | Saved/Paused VMs |
| `hypervClustered` | Checkbox | Is cluster member |
| `hypervClusterName` | Text | Cluster name |
| `hypervClusterNodeCount` | Integer | Total cluster nodes |
| `hypervClusterStatus` | Text | Cluster health status |
| `hypervHostCPUPercent` | Integer | Host CPU usage % |
| `hypervHostMemoryPercent` | Integer | Host memory usage % |
| `hypervVMReport` | **WYSIWYG** | HTML VM status table |
| `hypervHealthStatus` | Text | Overall health status |

**Important:** The `hypervVMReport` field MUST be type **WYSIWYG** to render HTML tables.

### Script 2: Health Check Fields (14 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `hypervQuickHealth` | Text | HEALTHY/WARNING/CRITICAL/UNKNOWN |
| `hypervHealthSummary` | Text | Brief health summary |
| `hypervCriticalIssues` | Integer | Count of critical issues |
| `hypervWarningIssues` | Integer | Count of warning issues |
| `hypervLastHealthCheck` | DateTime | Last check timestamp |
| `hypervTopIssues` | Text | Top 5 issues list |
| `hypervEventErrors` | Integer | Critical events (24h) |
| `hypervClusterQuorumOK` | Checkbox | Cluster has quorum |
| `hypervCSVHealthy` | Checkbox | All CSVs healthy |
| `hypervCSVLowSpace` | Integer | CSVs with <20% free |
| `hypervVMsUnhealthy` | Integer | VMs with failed heartbeat |
| `hypervReplicationIssues` | Integer | Replication problems |
| `hypervStorageLatencyMS` | Integer | Avg storage latency |
| `hypervLastScanTime` | DateTime | Last scan timestamp |

**Note:** Some fields are shared between scripts (timestamps).

### Field Creation Script (Optional)

Use NinjaRMM API to batch create fields:

```powershell
# Example API call (adapt to your environment)
$Fields = @(
    @{ name = "hypervInstalled"; type = "CHECKBOX" }
    @{ name = "hypervVersion"; type = "TEXT" }
    # ... add all fields
)

foreach ($Field in $Fields) {
    # API call to create field
    Invoke-NinjaRMMAPI -Endpoint "customfields" -Method POST -Body $Field
}
```

---

## Step 2: Deploy Scripts to Hyper-V Hosts

### Option A: NinjaRMM Script Deployment (Recommended)

1. **Upload Scripts to NinjaRMM:**
   - Navigate to: Administration → Library → Automation → Scripts
   - Click "Add Script"
   - **Script 1 Name:** "Hyper-V Monitor 1.ps1"
   - **Script 2 Name:** "Hyper-V Health Check 2.ps1"
   - Paste script content
   - Language: PowerShell
   - Category: Monitoring

2. **Configure Script Parameters:**
   - Timeout: 120 seconds (Script 1), 60 seconds (Script 2)
   - Run as: SYSTEM
   - Platform: Windows

3. **Assign to Devices:**
   - Select Hyper-V hosts/organizational units
   - Apply scripts via policy or device assignment

### Option B: Manual Deployment

```powershell
# On Hyper-V host
# Create script directory
$ScriptPath = "C:\Program Files\NinjaRMMAgent\scripts\hyper-v"
New-Item -ItemType Directory -Path $ScriptPath -Force

# Copy scripts
Copy-Item "Hyper-V Monitor 1.ps1" -Destination $ScriptPath
Copy-Item "Hyper-V Health Check 2.ps1" -Destination $ScriptPath

# Test execution
PowerShell.exe -ExecutionPolicy Bypass -File "$ScriptPath\Hyper-V Monitor 1.ps1"
PowerShell.exe -ExecutionPolicy Bypass -File "$ScriptPath\Hyper-V Health Check 2.ps1"
```

---

## Step 3: Configure Scheduled Execution

### NinjaRMM Scheduled Tasks

**Script 1: Monitor**
- **Frequency:** Every 15 minutes
- **Start Time:** :00, :15, :30, :45
- **Timeout:** 120 seconds
- **Conditions:** None
- **Priority:** Normal

**Script 2: Health Check**
- **Frequency:** Every 5 minutes
- **Start Time:** :00, :05, :10, :15, :20, :25, :30, :35, :40, :45, :50, :55
- **Timeout:** 60 seconds
- **Conditions:** None
- **Priority:** Normal

### Configuration Steps

1. **Navigate to:** Administration → Policies → Monitoring
2. **Create Policy:** "Hyper-V Monitoring"
3. **Add Condition:** "Hyper-V role installed" (use `hypervInstalled` field)
4. **Add Script 1:**
   - Script: Hyper-V Monitor 1.ps1
   - Schedule: Every 15 minutes
   - Timeout: 120 seconds
5. **Add Script 2:**
   - Script: Hyper-V Health Check 2.ps1
   - Schedule: Every 5 minutes
   - Timeout: 60 seconds
6. **Apply Policy** to Hyper-V hosts

### Manual Scheduled Tasks (Alternative)

```powershell
# Script 1 - Every 15 minutes
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File 'C:\Program Files\NinjaRMMAgent\scripts\hyper-v\Hyper-V Monitor 1.ps1'"
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Seconds 120)

Register-ScheduledTask -TaskName "Hyper-V Monitor" `
    -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings

# Script 2 - Every 5 minutes
$Action2 = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File 'C:\Program Files\NinjaRMMAgent\scripts\hyper-v\Hyper-V Health Check 2.ps1'"
$Trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
$Settings2 = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Seconds 60)

Register-ScheduledTask -TaskName "Hyper-V Health Check" `
    -Action $Action2 -Trigger $Trigger2 -Principal $Principal -Settings $Settings2
```

---

## Step 4: Configure Alerts

### Critical Alerts

**Navigate to:** Administration → Alerts → Conditions → Add Condition

#### Alert 1: Critical Health Status
```yaml
Name: "Hyper-V Critical Health"
Condition: hypervQuickHealth = "CRITICAL"
Severity: Critical
Notification: Immediate
Action: Email, SMS, Ticket
```

#### Alert 2: Cluster Quorum Lost
```yaml
Name: "Hyper-V Cluster Quorum Lost"
Condition: hypervClusterQuorumOK = False
Severity: Critical
Notification: Immediate
Action: Email, SMS, Ticket, Escalation
```

#### Alert 3: Unhealthy VMs
```yaml
Name: "Hyper-V VMs Unhealthy"
Condition: hypervVMsUnhealthy > 0
Severity: Critical
Notification: Within 5 minutes
Action: Email, Ticket
```

#### Alert 4: High Resource Usage
```yaml
Name: "Hyper-V Host Resources Critical"
Condition: hypervHostCPUPercent > 95 OR hypervHostMemoryPercent > 95
Severity: Critical
Notification: Within 10 minutes
Action: Email, Ticket
```

### Warning Alerts

#### Alert 5: Warning Health Status
```yaml
Name: "Hyper-V Warning Health"
Condition: hypervQuickHealth = "WARNING"
Severity: Warning
Notification: Within 15 minutes
Action: Email
```

#### Alert 6: Elevated Resource Usage
```yaml
Name: "Hyper-V Host Resources Warning"
Condition: hypervHostCPUPercent > 85 OR hypervHostMemoryPercent > 85
Severity: Warning
Notification: Within 30 minutes
Action: Email
```

#### Alert 7: CSV Low Space
```yaml
Name: "Hyper-V CSV Low Space"
Condition: hypervCSVLowSpace > 0
Severity: Warning
Notification: Within 1 hour
Action: Email, Ticket
```

#### Alert 8: Storage Latency
```yaml
Name: "Hyper-V Storage Latency High"
Condition: hypervStorageLatencyMS > 50
Severity: Warning
Notification: Within 30 minutes
Action: Email
```

### Informational Tracking

```yaml
Name: "Hyper-V VM Count Changed"
Condition: hypervVMCount changes
Severity: Info
Notification: Daily summary
Action: Log only
```

---

## Step 5: Dashboard Configuration

### Create Hyper-V Dashboard Widget

1. **Navigate to:** Dashboard → Add Widget
2. **Widget Type:** Custom Fields
3. **Widget Name:** "Hyper-V Status"
4. **Fields to Display:**
   - `hypervVMReport` (WYSIWYG - primary display)
   - `hypervQuickHealth` (text indicator)
   - `hypervVMsRunning` / `hypervVMCount`
   - `hypervHealthStatus`
   - `hypervClusterStatus` (if clustered)
   - `hypervHostCPUPercent` / `hypervHostMemoryPercent`

5. **Layout:** Grid or list view
6. **Refresh:** Auto (5-minute intervals)
7. **Filter:** Device role = "Hyper-V Host"

### Example Dashboard Layout

```
+----------------------------------+
|   Hyper-V Infrastructure Status  |
+----------------------------------+
| Host: HV01                       |
| Quick Health: [HEALTHY]          |
| VMs: 12 Running / 15 Total       |
| CPU: 65% | Memory: 72%            |
| Cluster: 3 Nodes | Healthy       |
|                                  |
| [Color-coded VM Table (HTML)]    |
| VM Name | State | Health | CPU   |
| --------|-------|--------|----   |
| DC01    | Run   | ✓      | 15%   |
| SQL01   | Run   | ✓      | 42%   |
| ...                              |
+----------------------------------+
```

---

## Step 6: Validation and Testing

### Initial Validation

**1. Verify Script Execution:**
```powershell
# Check NinjaRMM activity log
Get-EventLog -LogName Application -Source NinjaRMMAgent -Newest 50

# Verify custom fields populated
# Check in NinjaRMM dashboard
```

**2. Test Alert Conditions:**
```powershell
# Temporarily set test values
Set-NinjaField -Name "hypervQuickHealth" -Value "CRITICAL"
# Verify alert triggers
# Reset to actual value
```

**3. Validate HTML Report:**
- Open device details in NinjaRMM
- Navigate to custom fields
- Check `hypervVMReport` renders HTML table
- Verify color coding visible

### Cluster-Specific Validation

**1. Cluster Detection:**
```powershell
# Verify cluster fields populated
# hypervClustered = True
# hypervClusterName = actual cluster name
# hypervClusterNodeCount = correct count
```

**2. CSV Monitoring:**
```powershell
# Verify CSV fields
# hypervCSVHealthy should reflect actual state
# hypervCSVLowSpace should show count if any low
```

**3. Quorum Status:**
```powershell
# Check quorum field
# hypervClusterQuorumOK = True (normally)
```

### Performance Validation

**1. Execution Time:**
```powershell
# Monitor script duration in NinjaRMM logs
# Script 1: Should complete in <60s
# Script 2: Should complete in <30s
```

**2. Resource Impact:**
```powershell
# Monitor during execution
Get-Process -Name powershell | Select-Object CPU, WorkingSet
# Should be <1% CPU, <100 MB memory
```

**3. No VM Impact:**
```powershell
# Verify VMs unaffected
Get-VM | Measure-Object -Property CPUUsage -Average
# No increase during monitoring
```

---

## Step 7: Documentation and Handoff

### Create Runbook Entry

**Document the following:**
- Custom field names and purposes
- Alert conditions and escalation paths
- Troubleshooting steps
- Known issues and workarounds
- Contact information

### Train Operations Team

**Topics to Cover:**
- Dashboard interpretation
- Alert response procedures
- Health status meanings
- Common troubleshooting scenarios
- Escalation criteria

---

## Troubleshooting

### Script Not Executing

**Symptoms:** No custom fields populated

**Checks:**
1. Verify NinjaRMM agent running:
   ```powershell
   Get-Service NinjaRMMAgent
   ```

2. Check execution policy:
   ```powershell
   Get-ExecutionPolicy
   # Should be RemoteSigned or Unrestricted
   ```

3. Test script manually:
   ```powershell
   PowerShell.exe -ExecutionPolicy Bypass -File "path\to\script.ps1"
   ```

4. Review NinjaRMM logs:
   ```powershell
   Get-Content "C:\ProgramData\NinjaRMMAgent\ninjarmm-agent.log" -Tail 50
   ```

### Hyper-V Module Not Found

**Symptoms:** Error about Hyper-V module

**Solution:**
```powershell
# Install Hyper-V PowerShell module
Install-WindowsFeature -Name Hyper-V-PowerShell

# Verify installation
Get-Module -ListAvailable -Name Hyper-V
```

### Cluster Information Shows "Error"

**Symptoms:** Cluster fields show error or empty

**Checks:**
1. Verify cluster service:
   ```powershell
   Get-Service clussvc
   # Should be Running
   ```

2. Test cluster cmdlets:
   ```powershell
   Get-Cluster
   Get-ClusterNode
   ```

3. Check permissions:
   - Script runs as SYSTEM
   - SYSTEM needs cluster admin rights

### HTML Report Not Rendering

**Symptoms:** HTML code visible instead of table

**Solution:**
1. Verify field type is **WYSIWYG** (not Text)
2. Recreate field if wrong type
3. Re-run script to populate

### High Execution Time

**Symptoms:** Script times out or takes >60s

**Solutions:**
1. Check VM count (large environments may need higher timeout)
2. Verify storage performance (slow storage delays queries)
3. Consider adjusting frequency:
   - Script 1: Increase to 20-30 minutes
   - Script 2: Keep at 5 minutes (lightweight)

### False Alerts

**Symptoms:** Alerts triggered incorrectly

**Adjustments:**
1. Review threshold values
2. Add alert suppression during maintenance
3. Adjust alert delay periods
4. Fine-tune conditions for environment

---

## Multi-Site Deployment

### Considerations

**Network:**
- Each site needs NinjaRMM connectivity
- Cluster sites need inter-site connectivity
- Bandwidth requirements minimal (<1 Mbps)

**Timing:**
- Stagger execution across sites
- Avoid all hosts running simultaneously
- Use site-specific schedules if needed

**Centralization:**
- All data centralized in NinjaRMM
- Single dashboard for all sites
- Site-specific filtering available

### Deployment Strategy

**Phase 1: Pilot Site**
- Deploy to 1-2 hosts
- Validate functionality
- Tune thresholds
- Confirm alerting

**Phase 2: Primary Sites**
- Deploy to critical sites
- Monitor for issues
- Adjust as needed

**Phase 3: Full Rollout**
- Deploy to all remaining sites
- Document site-specific configurations
- Establish support procedures

---

## Maintenance

### Regular Tasks

**Weekly:**
- Review dashboard for anomalies
- Verify all hosts reporting
- Check alert accuracy

**Monthly:**
- Review execution times
- Analyze resource impact
- Update documentation
- Review alert thresholds

**Quarterly:**
- Script version updates
- Test failover scenarios (clustered)
- Review custom field usage
- Optimize configurations

### Updates and Upgrades

**Script Updates:**
1. Test in non-production
2. Deploy to pilot group
3. Monitor for issues
4. Roll out to production

**Custom Field Changes:**
1. Document changes
2. Update alert conditions
3. Update dashboards
4. Notify operations team

---

## Next Steps

### Immediate
- [ ] Complete custom field creation
- [ ] Deploy scripts to pilot hosts
- [ ] Configure basic alerts
- [ ] Create dashboard widget

### Short-term (1-2 weeks)
- [ ] Validate in pilot environment
- [ ] Fine-tune thresholds
- [ ] Train operations team
- [ ] Document site-specific configs

### Long-term (1-3 months)
- [ ] Full production deployment
- [ ] Establish baseline metrics
- [ ] Optimize alert conditions
- [ ] Plan for v2.0 scripts

---

## Support

**Internal Support:**
- Windows Automation Framework team
- RMM administrators
- Hyper-V infrastructure team

**External Resources:**
- [NinjaRMM Documentation](https://www.ninjarmm.com/docs/)
- [Microsoft Hyper-V Docs](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/)
- [WAF GitHub Repository](https://github.com/Xore/waf)

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-11  
**Next Review:** After v1.1 release
