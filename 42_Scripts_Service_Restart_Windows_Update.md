# Script 42: Restart Windows Update

**Purpose:** Restart Windows Update service when updates fail  
**Frequency:** On-demand / Alert-triggered  
**Runtime:** 5-10 seconds  
**Service(s):** wuauserv, BITS  
**Fields Updated:** `svcWULastRestart`, `svcWUStatus`

---

## PowerShell Code

```powershell
# Script 42: Restart Windows Update
param()

try {
    Write-Output "Restarting Windows Update service..."

    Stop-Service -Name wuauserv -Force -ErrorAction Stop
    Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    Start-Service -Name wuauserv -ErrorAction Stop
    Start-Service -Name BITS -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $service = Get-Service -Name wuauserv
    if ($service.Status -eq "Running") {
        Write-Output "SUCCESS: Windows Update service is running"
        Ninja-Property-Set svcWULastRestart (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Ninja-Property-Set svcWUStatus "Running"
        exit 0
    } else {
        throw "Windows Update failed to start"
    }

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set svcWUStatus "Failed"
    exit 1
}
```

---

## Expected Results

- Service status changes to "Running"
- Custom fields updated with timestamp and status
- Exit code 0 on success, 1 on failure

---

## Custom Fields Required

| Field Name | Type | Purpose |
|-----------|------|---------|
| `svcWULastRestart` | DateTime | Last restart timestamp |
| `svcWUStatus` | Text | Current service status |

---

## Use Cases

- Print jobs stuck in queue (Script 41)
- Windows Update failures (Script 42)
- DNS resolution issues (Script 43)
- Network connectivity problems (Script 44)
- RDP connection failures (Script 45)

---

**File:** `42_Service_Restart_Restart_Windows_Update.md`  
**Created:** February 1, 2026  
**Framework Version:** 1.0  
**Author:** NinjaRMM Custom Field Framework
