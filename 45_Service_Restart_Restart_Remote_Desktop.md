# Script 45: Restart Remote Desktop

**Purpose:** Restart Remote Desktop services  
**Frequency:** On-demand / Alert-triggered  
**Runtime:** 5-10 seconds  
**Service(s):** TermService, SessionEnv, UmRdpService  
**Fields Updated:** `svcRDPLastRestart`, `svcRDPStatus`

---

## PowerShell Code

```powershell
# Script 45: Restart Remote Desktop
param()

try {
    Write-Output "Restarting Remote Desktop services..."

    $services = @("TermService", "SessionEnv", "UmRdpService")
    $results = @()

    foreach ($svcName in $services) {
        $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($service) {
            Restart-Service -Name $svcName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            $service = Get-Service -Name $svcName
            if ($service.Status -eq "Running") {
                $results += "$svcName OK"
            } else {
                $results += "$svcName FAILED"
            }
        }
    }

    Write-Output "SUCCESS: RDP services restarted - $($results -join ', ')"
    Ninja-Property-Set svcRDPLastRestart (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Ninja-Property-Set svcRDPStatus "Running"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set svcRDPStatus "Failed"
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
| `svcRDPLastRestart` | DateTime | Last restart timestamp |
| `svcRDPStatus` | Text | Current service status |

---

## Use Cases

- Print jobs stuck in queue (Script 41)
- Windows Update failures (Script 42)
- DNS resolution issues (Script 43)
- Network connectivity problems (Script 44)
- RDP connection failures (Script 45)

---

**File:** `45_Service_Restart_Restart_Remote_Desktop.md`  
**Created:** February 1, 2026  
**Framework Version:** 4.0  
**Author:** NinjaRMM Custom Field Framework
