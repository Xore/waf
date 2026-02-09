# Run as Administrator
$ErrorActionPreference = "SilentlyContinue"

# --- 1. Data Gathering ---
$reportDate = Get-Date -Format "MM/dd/yy"

# Secure Boot Status
$sbStatus = Confirm-SecureBootUEFI
$sbASCII = if ($sbStatus) { "[v] Enabled" } else { "[X] Disabled" }

# BIOS Info
$bios = Get-WmiObject Win32_BIOS
$currentBIOS = $bios.SMBIOSBIOSVersion
$installDate = [Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate).ToString("MM/dd/yy")
$oem = $bios.Manufacturer

# Registry Check (0x5944)
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot"
$regVal = (Get-ItemProperty -Path $regPath -Name "AvailableUpdates" -ErrorAction SilentlyContinue).AvailableUpdates
$regASCII = if ($regVal -eq 22852) { "[v] 0x5944 Added" } else { "[X] 0x5944 Missing" }

# Scheduled Task Check
$task = Get-ScheduledTask -TaskName "Secure-Boot-Update" -ErrorAction SilentlyContinue
$taskASCII = if ($task) { "[v] Task Exists" } else { "[X] Task Missing" }

# Certificate Audit
$dbBytes = Get-SecureBootUEFI -Name db
$dbString = [System.Text.Encoding]::ASCII.GetString($dbBytes.Bytes)
$certsToCheck = @("Windows UEFI CA 2023", "Microsoft Corporation KEK 2K CA 2023", "Microsoft UEFI CA 2023")

$certResultsASCII = ""

foreach ($cert in $certsToCheck) {
    if ($dbString -match $cert) {
        $certResultsASCII += " - [v] Found: $cert`r`n"
    } else {
        $certResultsASCII += " - [X] Missing: $cert`r`n"
    }
}
# --- 4. Final Output & Ninja Property Update ---
# Update NinjaOne Custom Fields
Ninja-Property-Set -Name securebootUEFI -Value "STATUS: $sbASCII"
Ninja-Property-Set -Name securebootBios -Value "BIOS: $currentBIOS (Released: $installDate)"
Ninja-Property-Set -Name securebootRegistry -Value "REGISTRY: $regASCII"
Ninja-Property-Set -Name securebootTask -Value "TASK: $taskASCII"
Ninja-Property-Set -Name securebootCertificates -Value "CERTIFICATES: $certResultsASCII"