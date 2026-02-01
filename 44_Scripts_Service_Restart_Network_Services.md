# Script 44: Restart Network Services

**Purpose:** Restart all core network services and renew IP  
**Frequency:** On-demand / Alert-triggered  
**Runtime:** 5-10 seconds  
**Service(s):** Dhcp, Dnscache, LanmanWorkstation, LanmanServer  
**Fields Updated:** `svcNetworkLastRestart`, `svcNetworkStatus`

---

## PowerShell Code

```powershell
# Script 44: Restart Network Services
param()

try {
    Write-Output "Restarting network services..."

    $services = @("Dhcp", "Dnscache", "LanmanWorkstation", "LanmanServer")
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

    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null

    Write-Output "SUCCESS: Network services restarted - $($results -join ', ')"
    Ninja-Property-Set svcNetworkLastRestart (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Ninja-Property-Set svcNetworkStatus "Running"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set svcNetworkStatus "Failed"
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
| `svcNetworkLastRestart` | DateTime | Last restart timestamp |
| `svcNetworkStatus` | Text | Current service status |

---

## Use Cases

- Print jobs stuck in queue (Script 41)
- Windows Update failures (Script 42)
- DNS resolution issues (Script 43)
- Network connectivity problems (Script 44)
- RDP connection failures (Script 45)

---

**File:** `44_Service_Restart_Restart_Network_Services.md`  
**Created:** February 1, 2026  
**Framework Version:** 1.0  
**Author:** NinjaRMM Custom Field Framework
