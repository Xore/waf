# NinjaRMM Framework v4.0 - PowerShell Scripts

## Scripts Uploaded (Current Status)

### Core Infrastructure Monitoring ✅
- ✅ **Script 1**: Health Score Calculator (`01_Health_Score_Calculator.ps1`)
- ✅ **Script 3**: DNS Server Monitor (`03_DNS_Server_Monitor.ps1`)
- ✅ **Script 4**: Event Log Monitor (`04_Event_Log_Monitor.ps1`)
- ✅ **Script 5**: File Server Monitor (`05_File_Server_Monitor.ps1`)
- ✅ **Script 6**: Print Server Monitor (`06_Print_Server_Monitor.ps1`)
- ✅ **Script 7**: BitLocker Monitor (`07_BitLocker_Monitor.ps1`)
- ✅ **Script 8**: Hyper-V Host Monitor (`08_HyperV_Host_Monitor.ps1`)
- ✅ **Script 11**: MySQL Server Monitor (`11_MySQL_Server_Monitor.ps1`)
- ✅ **Script 12**: FlexLM License Monitor (`12_FlexLM_License_Monitor.ps1`)

### Service Restart Scripts ✅
- ✅ **Script 41**: Restart Print Spooler (`41_Restart_Print_Spooler.ps1`)
- ✅ **Script 42**: Restart Windows Update (`42_Restart_Windows_Update.ps1`)

### Emergency Response ✅
- ✅ **Script 50**: Emergency Disk Cleanup (`50_Emergency_Disk_Cleanup.ps1`)

### Advanced Telemetry ✅
- ✅ **Script 28**: Security Surface Telemetry (`28_Security_Surface_Telemetry.ps1`)

---

## Quick Deploy Guide

### Step 1: Download Scripts
```powershell
# Clone repository or download individual scripts
$baseUrl = "https://raw.githubusercontent.com/Xore/waf/main/scripts"
$scripts = @(
    "01_Health_Score_Calculator.ps1",
    "03_DNS_Server_Monitor.ps1",
    "04_Event_Log_Monitor.ps1",
    "05_File_Server_Monitor.ps1",
    "06_Print_Server_Monitor.ps1",
    "07_BitLocker_Monitor.ps1",
    "08_HyperV_Host_Monitor.ps1",
    "11_MySQL_Server_Monitor.ps1",
    "12_FlexLM_License_Monitor.ps1",
    "28_Security_Surface_Telemetry.ps1",
    "41_Restart_Print_Spooler.ps1",
    "42_Restart_Windows_Update.ps1",
    "50_Emergency_Disk_Cleanup.ps1"
)

foreach ($script in $scripts) {
    $url = "$baseUrl/$script"
    Invoke-WebRequest -Uri $url -OutFile "C:\NinjaScripts\$script"
}
```

### Step 2: Upload to NinjaRMM
1. Login to NinjaRMM → **Configuration** → **Scripting**
2. Click **+ New Script**
3. Copy-paste PowerShell code
4. Set **Context**: SYSTEM
5. Set **Timeout**: Per script documentation
6. Save script

### Step 3: Create Custom Fields
Before deploying scripts, create the required custom fields:

**For Script 1 (Health Score):**
- `OPSHealthScore` (Integer, 0-100)
- `OPSLastScoreUpdate` (DateTime)

**For Script 7 (BitLocker):**
- `secBitLockerEnabled` (Checkbox)
- `secBitLockerStatus` (Text)
- `blComplianceStatus` (Dropdown: Compliant, Partial, Non-Compliant, Unknown)
- `blVolumeCount` (Integer)
- `blFullyEncryptedCount` (Integer)
- `blEncryptionInProgress` (Checkbox)
- `blRecoveryKeyEscrowed` (Checkbox)
- `blVolumeSummary` (WYSIWYG)

**See full field definitions in:** [00_Custom_Fields.md](../00_Custom_Fields.md)

### Step 4: Schedule Scripts
1. Go to **Configuration** → **Policies**
2. Select target policy
3. Go to **Automation** tab
4. Add scripts with appropriate schedules:
   - **Every 4 hours**: Scripts 1, 3-6, 8, 11, 28
   - **Daily**: Scripts 7, 12
   - **On-demand**: Scripts 41, 42, 50

### Step 5: Create Alerts
Set up condition-based alerts:

**Example: Low Disk Space Alert**
```
Condition: cleanupSpaceFreedGB < 5 AND diskFreeGB < 10
Action: Run Script 50 (Emergency Disk Cleanup)
Notify: IT Team
```

**Example: BitLocker Non-Compliant**
```
Condition: blComplianceStatus = "Non-Compliant"
Action: Create Ticket
Notify: Security Team
```

---

## Script Execution Times

| Script | Runtime | Frequency | Priority |
|--------|---------|-----------|----------|
| 01 Health Score | 15s | 4 hours | High |
| 03 DNS Monitor | 30s | 4 hours | Medium |
| 04 Event Log | 25s | 4 hours | High |
| 05 File Server | 30s | 4 hours | Medium |
| 06 Print Server | 25s | 4 hours | Medium |
| 07 BitLocker | 20s | Daily | High |
| 08 Hyper-V | 40s | 4 hours | Medium |
| 11 MySQL | 30s | 4 hours | Low |
| 12 FlexLM | 30s | 4 hours | Low |
| 28 Security Surface | 40s | Daily | High |
| 41 Restart Spooler | 10s | On-demand | Critical |
| 42 Restart WU | 10s | On-demand | Critical |
| 50 Disk Cleanup | 90s | On-demand | Critical |

---

## Troubleshooting

### Script Fails with "Ninja-Property-Set not found"
**Solution**: Ensure script is executed via NinjaRMM agent, not manually.

### Custom fields not updating
**Solution**: 
1. Verify custom field names match exactly (case-sensitive)
2. Check field type matches (Integer, Text, Checkbox, etc.)
3. Review script output in Activity Log

### Permission errors
**Solution**: 
1. Verify script runs as SYSTEM
2. Check if Windows features/roles are installed
3. Review UAC settings

---

## Next Steps

### Still To Upload:
- Scripts 14-27 (Extended Automation)
- Scripts 29-36 (Advanced Telemetry)
- Scripts PR1-P4 (Patching Automation)
- Scripts 43-45 (Additional Service Restarts)

### Documentation:
- See [`00_Custom_Fields.md`](../00_Custom_Fields.md) for complete field definitions
- See individual `.md` files for detailed script documentation
- See [`SCRIPTS_DOWNLOAD_GUIDE.md`](../SCRIPTS_DOWNLOAD_GUIDE.md) for full deployment guide

---

## Support

**Repository**: https://github.com/Xore/waf  
**Framework Version**: 4.0  
**Last Updated**: February 2, 2026

**Questions?** Open an issue on GitHub.
