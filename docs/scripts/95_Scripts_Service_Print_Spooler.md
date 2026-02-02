# Script 41: Restart Print Spooler

**Purpose:** Restart Print Spooler service when print jobs are stuck  
**Frequency:** On-demand / Alert-triggered  
**Runtime:** 5-10 seconds  
**Service(s):** Spooler  
**Fields Updated:** `svcSpoolerLastRestart`, `svcSpoolerStatus`

---

## PowerShell Code

```powershell
# Script 41: Restart Print Spooler
param()

try {
    Write-Output "Restarting Print Spooler service..."

    $service = Get-Service -Name Spooler -ErrorAction Stop
    $initialStatus = $service.Status

    if ($service.Status -eq "Running") {
        Stop-Service -Name Spooler -Force -ErrorAction Stop
        Start-Sleep -Seconds 3
    }

    Start-Service -Name Spooler -ErrorAction Stop
    Start-Sleep -Seconds 2

    $service = Get-Service -Name Spooler
    if ($service.Status -eq "Running") {
        Write-Output "SUCCESS: Print Spooler is running"
        Ninja-Property-Set svcSpoolerLastRestart (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Ninja-Property-Set svcSpoolerStatus "Running"
        exit 0
    } else {
        throw "Service failed to start"
    }

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set svcSpoolerStatus "Failed"
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
| `svcSpoolerLastRestart` | DateTime | Last restart timestamp |
| `svcSpoolerStatus` | Text | Current service status |

---

## Use Cases

- Print jobs stuck in queue (Script 41)
- Windows Update failures (Script 42)
- DNS resolution issues (Script 43)
- Network connectivity problems (Script 44)
- RDP connection failures (Script 45)

---

**File:** `41_Service_Restart_Restart_Print_Spooler.md`  
**Created:** February 1, 2026  
**Framework Version:** 1.0  
**Author:** NinjaRMM Custom Field Framework
