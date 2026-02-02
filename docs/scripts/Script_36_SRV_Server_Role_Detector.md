# Script 36: SRV Server Role Detector

**File:** Script_36_SRV_Server_Role_Detector.md  
**Version:** v1.0  
**Script Number:** 36  
**Category:** Advanced Telemetry - Server Classification  
**Last Updated:** February 2, 2026

---

## Purpose

Auto-detect installed server roles and assess device criticality.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~35 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [SRVServerRole](../core/11_AUTO_UX_SRV_Core_Experience.md) (Text)
- [SRVRoleCount](../core/11_AUTO_UX_SRV_Core_Experience.md) (Integer)
- SRVCriticalService (Checkbox)

---

## PowerShell Implementation

```powershell
# Script 36: Server Role Detector
# Auto-detect server roles and criticality

param()

try {
    Write-Output "Starting Server Role Detector (v1.0)"

    $detectedRoles = @()

    # Check if this is a server OS
    $os = Get-CimInstance Win32_OperatingSystem
    $isServer = $os.ProductType -ne 1  # 1 = Workstation, 2 = Domain Controller, 3 = Server

    if ($isServer) {
        # Check for specific server features
        $features = Get-WindowsFeature -ErrorAction SilentlyContinue

        if ($features) {
            # Domain Controller
            if (($features | Where-Object {$_.Name -eq "AD-Domain-Services" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "Domain Controller"
            }

            # DNS Server
            if (($features | Where-Object {$_.Name -eq "DNS" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "DNS Server"
            }

            # DHCP Server
            if (($features | Where-Object {$_.Name -eq "DHCP" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "DHCP Server"
            }

            # File Server
            if (($features | Where-Object {$_.Name -eq "FS-FileServer" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "File Server"
            }

            # Print Server
            if (($features | Where-Object {$_.Name -eq "Print-Services" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "Print Server"
            }

            # Web Server (IIS)
            if (($features | Where-Object {$_.Name -eq "Web-Server" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "Web Server"
            }

            # Hyper-V
            if (($features | Where-Object {$_.Name -eq "Hyper-V" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "Hyper-V Host"
            }

            # Remote Desktop Services
            if (($features | Where-Object {$_.Name -match "RDS" -and $_.Installed}).Count -gt 0) {
                $detectedRoles += "Remote Desktop Server"
            }
        }

        # Check for database services
        $sqlService = Get-Service -Name "MSSQLSERVER","SQLSERVERAGENT" -ErrorAction SilentlyContinue
        if ($sqlService) {
            $detectedRoles += "SQL Server"
        }

        $mysqlService = Get-Service -Name "MySQL*","MariaDB*" -ErrorAction SilentlyContinue
        if ($mysqlService) {
            $detectedRoles += "MySQL/MariaDB Server"
        }
    } else {
        $detectedRoles += "Workstation"
    }

    # Determine if critical
    $criticalRoles = @("Domain Controller", "DNS Server", "DHCP Server", "SQL Server", "Hyper-V Host")
    $isCritical = ($detectedRoles | Where-Object {$_ -in $criticalRoles}).Count -gt 0

    # Format roles
    $rolesText = if ($detectedRoles.Count -gt 0) {
        $detectedRoles -join ", "
    } else {
        "No roles detected"
    }

    # Update custom fields
    Ninja-Property-Set srvServerRole $rolesText
    Ninja-Property-Set srvRoleCount $detectedRoles.Count
    Ninja-Property-Set srvCriticalService $isCritical

    Write-Output "SUCCESS: Server role detection completed"
    Write-Output "  Detected Roles: $rolesText"
    Write-Output "  Role Count: $($detectedRoles.Count)"
    Write-Output "  Critical Service: $isCritical"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [SRV Server Role Fields](../core/11_AUTO_UX_SRV_Core_Experience.md)
- [Script 16: Server Role Detector](Script_16_SRV_Server_Role_Detector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_36_SRV_Server_Role_Detector.md  
**Version:** v1.0  
**Status:** Production Ready
