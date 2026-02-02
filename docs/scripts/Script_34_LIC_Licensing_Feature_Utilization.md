# Script 34: LIC Licensing and Feature Utilization Telemetry

**File:** Script_34_LIC_Licensing_Feature_Utilization.md  
**Version:** v1.0  
**Script Number:** 34  
**Category:** Advanced Telemetry - Licensing  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor Windows and Office activation status and version tracking.

---

## Execution Details

- **Frequency:** Weekly
- **Runtime:** ~25 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- LICOSActivationStatus (Dropdown: Activated, Grace Period, Not Activated, Unknown)
- LICOfficeActivationStatus (Dropdown: Activated, Grace Period, Not Activated, Not Installed)
- APPOfficeVersion (Text)

---

## PowerShell Implementation

```powershell
# Script 34: Licensing and Feature Utilization Telemetry
# Monitor Windows and Office licensing

param()

try {
    Write-Output "Starting Licensing Telemetry (v1.0)"

    # Check Windows activation status
    $osLicense = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND LicenseStatus > 0"
    
    if ($osLicense) {
        switch ($osLicense.LicenseStatus) {
            1 { $osActivation = "Activated" }
            2 { $osActivation = "Grace Period" }
            3 { $osActivation = "Grace Period" }
            4 { $osActivation = "Grace Period" }
            5 { $osActivation = "Not Activated" }
            6 { $osActivation = "Not Activated" }
            default { $osActivation = "Unknown" }
        }
    } else {
        $osActivation = "Unknown"
    }

    # Check Office installation and activation
    $officeRegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration",
        "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Common\InstallRoot"
    )

    $officeInstalled = $false
    $officeVersion = "Not Installed"

    foreach ($regPath in $officeRegPaths) {
        if (Test-Path $regPath) {
            $versionInfo = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($versionInfo) {
                $officeInstalled = $true
                if ($versionInfo.VersionToReport) {
                    $officeVersion = "Microsoft 365 $($versionInfo.VersionToReport)"
                } elseif ($versionInfo.ProductReleaseIds) {
                    $officeVersion = "Office $($versionInfo.ProductReleaseIds)"
                } else {
                    $officeVersion = "Office Installed"
                }
                break
            }
        }
    }

    # Check Office activation if installed
    if ($officeInstalled) {
        $officeLicense = Get-CimInstance -ClassName OfficeSoftwareProtectionProduct -ErrorAction SilentlyContinue | 
            Where-Object { $_.ApplicationID -eq '0ff1ce15-a989-479d-af46-f275c6370663' -and $_.LicenseStatus -gt 0 } | 
            Select-Object -First 1

        if ($officeLicense) {
            switch ($officeLicense.LicenseStatus) {
                1 { $officeActivation = "Activated" }
                2 { $officeActivation = "Grace Period" }
                3 { $officeActivation = "Grace Period" }
                5 { $officeActivation = "Not Activated" }
                default { $officeActivation = "Not Activated" }
            }
        } else {
            $officeActivation = "Not Activated"
        }
    } else {
        $officeActivation = "Not Installed"
    }

    # Update custom fields
    Ninja-Property-Set licOSActivationStatus $osActivation
    Ninja-Property-Set licOfficeActivationStatus $officeActivation
    Ninja-Property-Set appOfficeVersion $officeVersion

    Write-Output "SUCCESS: Licensing telemetry completed"
    Write-Output "  Windows Activation: $osActivation"
    Write-Output "  Office Activation: $officeActivation"
    Write-Output "  Office Version: $officeVersion"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_34_LIC_Licensing_Feature_Utilization.md  
**Version:** v1.0  
**Status:** Production Ready
