# Script 18: Baseline Refresh (Configuration Baseline)

**Purpose:** Update device configuration baseline for drift detection  
**Frequency:** Weekly or after major changes  
**Runtime:** 30-40 seconds  
**Fields Updated:** Multiple baseline fields (software, services, admins, performance)

---

## PowerShell Code

```powershell
# Script 18: Baseline Refresh - Update device configuration baseline

param()

try {
    Write-Output "Refreshing device baseline..."

    # 1. Capture installed software
    $software = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                                  "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object {$_.DisplayName} |
        Select-Object DisplayName, DisplayVersion, Publisher |
        Sort-Object DisplayName -Unique
    $softwareList = ($software | ForEach-Object {"$($_.DisplayName)|$($_.DisplayVersion)"}) -join ","
    Ninja-Property-Set baseSoftwareList $softwareList

    # 2. Capture running services
    $services = Get-Service | Where-Object {$_.Status -eq "Running"} | 
        Select-Object -ExpandProperty Name | Sort-Object
    Ninja-Property-Set baseServiceList ($services -join ",")

    # 3. Capture local administrators
    $admins = Get-LocalGroupMember -Group Administrators | 
        Select-Object -ExpandProperty Name
    Ninja-Property-Set baseLocalAdmins ($admins -join ",")

    # 4. Capture startup programs
    $startup = Get-CimInstance Win32_StartupCommand | 
        Select-Object -ExpandProperty Name
    Ninja-Property-Set baseStartupList ($startup -join ",")

    # 5. Capture current performance baseline
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3).CounterSamples | 
        Measure-Object -Property CookedValue -Average | 
        Select-Object -ExpandProperty Average
    $os = Get-CimInstance Win32_OperatingSystem
    $memPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)

    $perfBaseline = @{
        CPU = [math]::Round($cpu, 1)
        Memory = $memPercent
        Disk = $diskPercent
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json -Compress

    Ninja-Property-Set basePerformanceBaseline $perfBaseline
    Ninja-Property-Set baseLastRefresh (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Ninja-Property-Set baseBaselineCoveragePercent 100

    Write-Output "SUCCESS: Baseline refreshed"
    Write-Output "Software: $($software.Count) apps | Services: $($services.Count) | Admins: $($admins.Count)"
    Write-Output "Performance: CPU $([math]::Round($cpu, 1))% | RAM $memPercent% | Disk $diskPercent%"

    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Expected Results

Baseline established with:
- Complete software inventory
- Running services list
- Local administrator accounts
- Startup programs
- Performance metrics (CPU, RAM, Disk)

This baseline is used by drift detection scripts (14, 20, 21) to identify unauthorized changes.

---

## Custom Fields Required

| Field Name | Type | Purpose |
|-----------|------|---------|
| `baseSoftwareList` | Text (Large) | Installed software baseline |
| `baseServiceList` | Text (Large) | Running services baseline |
| `baseLocalAdmins` | Text | Local administrators baseline |
| `baseStartupList` | Text | Startup programs baseline |
| `basePerformanceBaseline` | Text (JSON) | Performance metrics baseline |
| `baseLastRefresh` | DateTime | Last baseline update |
| `baseBaselineCoveragePercent` | Integer | Baseline coverage quality |

---

## When to Run

1. **Initial deployment** - Establish first baseline
2. **After approved changes** - Update baseline after:
   - Software installations
   - Service configuration changes
   - Admin account modifications
3. **Weekly refresh** - Keep baseline current
4. **Before drift detection** - Ensure baseline is fresh

---

## Integration with Drift Detection

After running Script 18, the following scripts can detect drift:
- Script 14: Local Admin Drift Analyzer
- Script 20: Software Inventory Baseline and Shadow-IT Detector
- Script 21: Critical Service Configuration Drift Monitor

---

**File:** `18_Baseline_Refresh.md`  
**Created:** February 1, 2026  
**Framework Version:** 4.0  
**Author:** NinjaRMM Custom Field Framework
