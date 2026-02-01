# Script 55: Memory Optimization

**Purpose:** Improve RAM usage and free up memory during performance degradation  
**Frequency:** On-demand / Alert-triggered  
**Runtime:** 30-45 seconds  
**Expected Result:** Improved RAM utilization, 500MB-2GB freed  
**Fields Updated:** `memOptLastRun`, `memOptFreedMB`, `memOptMemoryUsagePercent`

---

## PowerShell Code

```powershell
# Script 55: Memory Optimization - Improve RAM Usage

param()

try {
    Write-Output "Starting Memory Optimization..."

    $beforeMem = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
    $actions = @()

    # 1. Clear working sets (trim memory)
    Write-Output "Trimming process working sets..."
    $processes = Get-Process | Where-Object {$_.WorkingSet64 -gt 50MB} | Sort-Object WorkingSet64 -Descending
    foreach ($proc in $processes) {
        try {
            $proc.MinWorkingSet = [int]$proc.MinWorkingSet
            $actions += "Trimmed $($proc.Name)"
        } catch {}
    }

    # 2. Clear standby memory list
    Write-Output "Clearing standby memory list..."
    if (-not ([System.Management.Automation.PSTypeName]'MemoryManagement').Type) {
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class MemoryManagement {
                [DllImport("kernel32.dll")]
                public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);

                public static void EmptyWorkingSet() {
                    SetProcessWorkingSetSize(System.Diagnostics.Process.GetCurrentProcess().Handle, -1, -1);
                }
            }
"@
    }
    [MemoryManagement]::EmptyWorkingSet()
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    # 3. Recycle memory-intensive services
    Write-Output "Checking for memory-intensive services..."
    $heavyServices = @("wuauserv", "BITS")
    foreach ($svc in $heavyServices) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running" -and $service.StartType -ne "Disabled") {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            $actions += "Recycled $svc"
        }
    }

    # 4. Clear DNS cache
    Write-Output "Flushing DNS cache..."
    ipconfig /flushdns | Out-Null
    $actions += "DNS cache flushed"

    # 5. Clear event logs if over 100MB
    Write-Output "Checking event log sizes..."
    $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | 
        Where-Object {$_.FileSize -gt 100MB -and $_.IsEnabled -eq $true}
    foreach ($log in $logs) {
        try {
            wevtutil.exe cl $log.LogName
            $actions += "Cleared $($log.LogName)"
        } catch {}
    }

    Start-Sleep -Seconds 3

    $afterMem = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
    $freedMB = [math]::Round(($afterMem - $beforeMem), 2)

    $os = Get-CimInstance Win32_OperatingSystem
    $totalMem = $os.TotalVisibleMemorySize / 1MB
    $freeMem = $os.FreePhysicalMemory / 1MB
    $usedPercent = [math]::Round((($totalMem - $freeMem) / $totalMem) * 100, 1)

    Ninja-Property-Set memOptLastRun (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Ninja-Property-Set memOptFreedMB $freedMB
    Ninja-Property-Set memOptMemoryUsagePercent $usedPercent

    Write-Output "SUCCESS: Freed $freedMB MB | Memory usage: $usedPercent%"
    Write-Output "Actions: $($actions -join ' | ')"

    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set memOptLastResult "Failed"
    exit 1
}
```

---

## Expected Results

- **Target:** Free 500MB-2GB RAM
- **Memory usage:** Reduced by 10-20%
- **Actions performed:**
  - Process working sets trimmed
  - Standby memory cleared
  - Memory-intensive services recycled
  - DNS cache flushed
  - Large event logs cleared

---

## Custom Fields Required

| Field Name | Type | Purpose |
|-----------|------|---------|
| `memOptLastRun` | DateTime | Last execution timestamp |
| `memOptFreedMB` | Integer | Amount of RAM freed in MB |
| `memOptMemoryUsagePercent` | Integer | Current memory usage percentage |
| `memOptLastResult` | Text | Success or failure message |

---

## Trigger Conditions

Run this script when:
- Memory utilization > 90%
- Memory utilization > 85% for 15+ minutes
- Application performance degradation detected
- User reports system slowness

---

## Safety Notes

- Safe for production systems
- Does not terminate user applications
- Services are recycled (stopped then restarted), not terminated
- No data loss risk
- Can run during business hours

---

**File:** `55_Memory_Optimization.md`  
**Created:** February 1, 2026  
**Framework Version:** 1.0  
**Author:** NinjaRMM Custom Field Framework
