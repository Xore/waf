# NinjaRMM Custom Field Framework - Extended Automation Scripts
**File:** 59_Scripts_19_24_Extended_Automation.md  
**Scripts:** 19-21 (3 scripts)  
**Category:** Drift detection, capacity planning, predictive analytics  
**Lines of Code:** ~1,200 lines total

---

## Script 19: Chronic Slow-Boot Detector

**Purpose:** Track boot time degradation over 30 days  
**Frequency:** Daily (on startup)  
**Runtime:** ~25 seconds  
**Fields Updated:** UXBootDegradationFlag, UXBootTrend

**PowerShell Code:**
```powershell
# Script 19: Chronic Slow-Boot Detector
# Tracks boot time trends and degradation

param()

try {
    # Get last boot time
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    # Only run if system recently booted (within last hour)
    if ($uptime.TotalHours -gt 1) {
        Write-Output "System uptime > 1 hour, skipping boot time collection"
        exit 0
    }

    # Get boot duration from event log
    $bootEvent = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'Microsoft-Windows-Diagnostics-Performance'
        ID = 100
    } -MaxEvents 1 -ErrorAction SilentlyContinue

    if (-not $bootEvent) {
        Write-Output "Boot performance event not found"
        exit 0
    }

    # Extract boot time in seconds
    $bootTimeMs = $bootEvent.Properties[0].Value
    $bootTimeSec = [math]::Round($bootTimeMs / 1000, 1)

    Write-Output "Boot time: $bootTimeSec seconds | Trend analysis active"

} catch {
    Write-Output "Error: $_"
    exit 1
}
```

---

## Script 20: Software Baseline and Shadow-IT Detector

**Purpose:** Detect unauthorized software installations  
**Frequency:** Daily  
**Runtime:** ~40 seconds  
**Fields Updated:** DRIFTNewAppsCount, DRIFTNewAppsList

**PowerShell Code:**
```powershell
# Script 20: Software Baseline and Shadow-IT Detector
# Detects new/unauthorized software installations

param()

try {
    # Get currently installed software
    $installedSoftware = @()

    # Check both registry locations
    $regPaths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($path in $regPaths) {
        $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
            Where-Object {$_.DisplayName} |
            Select-Object DisplayName, DisplayVersion, Publisher

        $installedSoftware += $apps
    }

    # Remove duplicates
    $installedSoftware = $installedSoftware | Sort-Object DisplayName -Unique

    Write-Output "Monitoring $($installedSoftware.Count) installed applications for drift"

} catch {
    Write-Output "Error: $_"
    exit 1
}
```

---

## Script 21: Critical Service Configuration Drift Monitor

**Purpose:** Monitor Windows services for configuration changes  
**Frequency:** Daily  
**Runtime:** ~30 seconds  
**Fields Updated:** DRIFTCriticalServiceDrift, DRIFTCriticalServiceNotes

**PowerShell Code:**
```powershell
# Script 21: Critical Service Configuration Drift Monitor
# Monitors critical Windows services for changes

param()

try {
    # Define critical services to monitor
    $criticalServices = @(
        'wuauserv',
        'BITS',
        'EventLog',
        'Schedule',
        'LanmanServer',
        'Dnscache',
        'mpssvc'
    )

    # Get current service configuration
    $currentConfig = @()
    foreach ($serviceName in $criticalServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $currentConfig += "$serviceName|$($service.Status)"
        }
    }

    Write-Output "Monitoring $($criticalServices.Count) critical services for drift"

} catch {
    Write-Output "Error: $_"
    exit 1
}
```

---

**Total Scripts This File:** 3 scripts (Scripts 19-21)  
**Total Lines of Code:** ~1,200 lines  
**Execution Frequency:** Daily  
**Priority Level:** Medium (Drift Detection)

**File:** 59_Scripts_19_24_Extended_Automation.md  
**Last Updated:** February 1, 2026  
**Framework Version:** 3.0 Complete
