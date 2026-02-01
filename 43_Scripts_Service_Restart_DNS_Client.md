# Script 43: Restart DNS Client

**Purpose:** Restart DNS Client service and flush DNS cache  
**Frequency:** On-demand / Alert-triggered  
**Runtime:** 5-10 seconds  
**Service(s):** Dnscache  
**Fields Updated:** `svcDNSLastRestart`, `svcDNSStatus`

---

## PowerShell Code

```powershell
# Script 43: Restart DNS Client
param()

try {
    Write-Output "Restarting DNS Client service..."

    Stop-Service -Name Dnscache -Force -ErrorAction Stop
    Start-Sleep -Seconds 2

    Start-Service -Name Dnscache -ErrorAction Stop
    Start-Sleep -Seconds 2

    ipconfig /flushdns | Out-Null

    $service = Get-Service -Name Dnscache
    if ($service.Status -eq "Running") {
        Write-Output "SUCCESS: DNS Client is running, cache flushed"
        Ninja-Property-Set svcDNSLastRestart (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Ninja-Property-Set svcDNSStatus "Running"
        exit 0
    } else {
        throw "DNS Client failed to start"
    }

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set svcDNSStatus "Failed"
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
| `svcDNSLastRestart` | DateTime | Last restart timestamp |
| `svcDNSStatus` | Text | Current service status |

---

## Use Cases

- Print jobs stuck in queue (Script 41)
- Windows Update failures (Script 42)
- DNS resolution issues (Script 43)
- Network connectivity problems (Script 44)
- RDP connection failures (Script 45)

---

**File:** `43_Service_Restart_Restart_DNS_Client.md`  
**Created:** February 1, 2026  
**Framework Version:** 4.0  
**Author:** NinjaRMM Custom Field Framework
