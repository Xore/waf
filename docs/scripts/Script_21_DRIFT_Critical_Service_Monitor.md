# Script 21: DRIFT Critical Service Configuration Monitor

**File:** Script_21_DRIFT_Critical_Service_Monitor.md  
**Version:** v1.0  
**Script Number:** 21  
**Category:** Extended Automation - Service Drift Detection  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor critical Windows services for configuration changes and unexpected modifications.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [DRIFTCriticalServiceDrift](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (Checkbox)
- DRIFTCriticalServiceNotes (Text)

---

## PowerShell Implementation

```powershell
# Script 21: Critical Service Configuration Drift Monitor
# Monitors critical Windows services for changes

param()

try {
    Write-Output "Starting Critical Service Configuration Monitor (v1.0)"

    # Define critical services to monitor
    $criticalServices = @(
        "wuauserv",      # Windows Update
        "MpsSvc",        # Windows Defender Firewall
        "WinDefend",     # Windows Defender Antivirus
        "Dnscache",      # DNS Client
        "LanmanServer",  # Server
        "LanmanWorkstation", # Workstation
        "RpcSs",         # Remote Procedure Call
        "EventLog"       # Windows Event Log
    )

    $driftDetected = $false
    $driftNotes = @()

    foreach ($serviceName in $criticalServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
        if (-not $service) {
            $driftNotes += "$serviceName: SERVICE MISSING"
            $driftDetected = $true
            continue
        }

        # Get service configuration
        $serviceConfig = Get-CimInstance Win32_Service -Filter "Name='$serviceName'" -ErrorAction SilentlyContinue
        
        if ($serviceConfig) {
            # Check for critical services that should be running
            if ($serviceName -in @("Dnscache", "RpcSs", "EventLog")) {
                if ($service.Status -ne "Running") {
                    $driftNotes += "$serviceName: NOT RUNNING (Status: $($service.Status))"
                    $driftDetected = $true
                }
            }

            # Check for disabled critical services
            if ($serviceConfig.StartMode -eq "Disabled") {
                if ($serviceName -in @("wuauserv", "MpsSvc", "WinDefend")) {
                    $driftNotes += "$serviceName: DISABLED"
                    $driftDetected = $true
                }
            }
        }
    }

    # Compile notes
    $notesText = if ($driftNotes.Count -gt 0) {
        $driftNotes -join "; "
    } else {
        "All critical services normal"
    }

    # Update custom fields
    Ninja-Property-Set driftCriticalServiceDrift $driftDetected
    Ninja-Property-Set driftCriticalServiceNotes $notesText

    if ($driftDetected) {
        Write-Output "DRIFT DETECTED: Critical service configuration changes"
        foreach ($note in $driftNotes) {
            Write-Output "  - $note"
        }
    } else {
        Write-Output "SUCCESS: All critical services normal"
    }

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [DRIFT Drift Detection Fields](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md)
- [Script 13: Drift Detector](Script_13_DRIFT_Detector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_21_DRIFT_Critical_Service_Monitor.md  
**Version:** v1.0  
**Status:** Production Ready
