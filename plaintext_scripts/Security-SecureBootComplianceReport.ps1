#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Generates comprehensive Secure Boot compliance report

.DESCRIPTION
    Audits Windows Secure Boot configuration and compliance status including:
    UEFI Secure Boot status, BIOS version information, registry configuration,
    scheduled task existence, and certificate validation.
    
    The script performs the following:
    - Checks Secure Boot enabled status via Confirm-SecureBootUEFI
    - Retrieves BIOS/UEFI firmware information
    - Validates registry key for Secure Boot updates (0x5944)
    - Checks for Secure Boot update scheduled task
    - Audits UEFI certificate database for required certificates
    - Reports all findings to NinjaRMM custom fields
    
    This script runs unattended without user interaction.

.PARAMETER CheckCertificates
    Certificates to check in UEFI database.
    Default: Windows UEFI CA 2023, Microsoft Corporation KEK 2K CA 2023, Microsoft UEFI CA 2023

.EXAMPLE
    .\Security-SecureBootComplianceReport.ps1
    
    Runs full Secure Boot compliance audit with default settings.

.NOTES
    Script Name:    Security-SecureBootComplianceReport.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or weekly
    Typical Duration: ~2-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - securebootUEFI - Secure Boot enabled status
        - securebootBios - BIOS version and release date
        - securebootRegistry - Registry key validation (0x5944)
        - securebootTask - Scheduled task existence
        - securebootCertificates - Certificate audit results
        - securebootCompliance - Overall compliance (Compliant/NonCompliant/Partial)
        - securebootDate - Timestamp of check
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (required)
        - UEFI firmware (not legacy BIOS)
        - Windows 8 or later
        - Secure Boot capable hardware
    
    Environment Variables (Optional):
        - checkCertificates: JSON array of certificate names to validate
    
    Exit Codes:
        0 - Success (audit completed, regardless of compliance status)
        1 - Failure (script error or UEFI not available)

.LINK
    https://github.com/Xore/waf
    https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-secure-boot
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Certificates to validate in UEFI database")]
    [string[]]$CheckCertificates = @(
        "Windows UEFI CA 2023",
        "Microsoft Corporation KEK 2K CA 2023",
        "Microsoft UEFI CA 2023"
    )
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Security-SecureBootComplianceReport"

# Registry paths
$SecureBootRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot"
$ExpectedRegValue = 22852  # 0x5944 in decimal

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0
$script:ComplianceIssues = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes structured log messages with plain text output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Output $LogMessage
    
    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++ }
    }
}

function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with automatic fallback to CLI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' set successfully" -Level DEBUG
            return
        } else {
            throw "Ninja-Property-Set cmdlet not available"
        }
    } catch {
        Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
        
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
        }
    }
}

function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if script is running with Administrator privileges
    #>
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SecureBootStatus {
    <#
    .SYNOPSIS
        Checks if Secure Boot is enabled
    #>
    try {
        $Status = Confirm-SecureBootUEFI -ErrorAction Stop
        return $Status
    } catch {
        Write-Log "Failed to check Secure Boot status: $_" -Level WARN
        return $null
    }
}

function Get-BIOSInformation {
    <#
    .SYNOPSIS
        Retrieves BIOS/UEFI firmware information
    #>
    try {
        $BIOS = Get-CimInstance Win32_BIOS -ErrorAction Stop
        
        return [PSCustomObject]@{
            Version      = $BIOS.SMBIOSBIOSVersion
            Manufacturer = $BIOS.Manufacturer
            ReleaseDate  = $BIOS.ReleaseDate
        }
    } catch {
        Write-Log "Failed to retrieve BIOS information: $_" -Level ERROR
        return $null
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable override
    if ($env:checkCertificates -and $env:checkCertificates -notlike "null") {
        try {
            $CheckCertificates = $env:checkCertificates | ConvertFrom-Json
            Write-Log "Using certificates from environment: $($CheckCertificates.Count) certificates" -Level INFO
        } catch {
            Write-Log "Failed to parse checkCertificates from environment, using defaults" -Level WARN
        }
    }
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required for Secure Boot audit"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # 1. Check Secure Boot Status
    Write-Log "Checking Secure Boot UEFI status" -Level INFO
    $SecureBootEnabled = Get-SecureBootStatus
    
    if ($null -eq $SecureBootEnabled) {
        $SBStatus = "UNKNOWN - Unable to determine"
        Write-Log "Secure Boot status: UNKNOWN" -Level WARN
        $script:ComplianceIssues++
    } elseif ($SecureBootEnabled) {
        $SBStatus = "ENABLED"
        Write-Log "Secure Boot status: ENABLED" -Level SUCCESS
    } else {
        $SBStatus = "DISABLED"
        Write-Log "Secure Boot status: DISABLED" -Level WARN
        $script:ComplianceIssues++
    }
    
    Set-NinjaField -FieldName "securebootUEFI" -Value "STATUS: $SBStatus"
    
    # 2. Get BIOS Information
    Write-Log "Retrieving BIOS information" -Level INFO
    $BIOSInfo = Get-BIOSInformation
    
    if ($BIOSInfo) {
        $BIOSString = "BIOS: $($BIOSInfo.Version) (Released: $($BIOSInfo.ReleaseDate.ToString('MM/dd/yy')))"
        Write-Log "BIOS Version: $($BIOSInfo.Version)" -Level INFO
        Write-Log "BIOS Manufacturer: $($BIOSInfo.Manufacturer)" -Level INFO
        Write-Log "BIOS Release Date: $($BIOSInfo.ReleaseDate.ToString('yyyy-MM-dd'))" -Level INFO
    } else {
        $BIOSString = "BIOS: Unable to retrieve"
        Write-Log "Failed to retrieve BIOS information" -Level WARN
    }
    
    Set-NinjaField -FieldName "securebootBios" -Value $BIOSString
    
    # 3. Check Registry Key (0x5944)
    Write-Log "Checking Secure Boot registry configuration" -Level INFO
    try {
        $RegValue = Get-ItemPropertyValue -Path $SecureBootRegPath -Name "AvailableUpdates" -ErrorAction Stop
        
        if ($RegValue -eq $ExpectedRegValue) {
            $RegStatus = "0x5944 PRESENT"
            Write-Log "Registry key AvailableUpdates: 0x5944 (FOUND)" -Level SUCCESS
        } else {
            $RegStatus = "0x5944 MISSING (Found: 0x$($RegValue.ToString('X')))"
            Write-Log "Registry key AvailableUpdates: Unexpected value 0x$($RegValue.ToString('X'))" -Level WARN
            $script:ComplianceIssues++
        }
    } catch {
        $RegStatus = "0x5944 MISSING (Not Found)"
        Write-Log "Registry key AvailableUpdates: Not found" -Level WARN
        $script:ComplianceIssues++
    }
    
    Set-NinjaField -FieldName "securebootRegistry" -Value "REGISTRY: $RegStatus"
    
    # 4. Check Scheduled Task
    Write-Log "Checking for Secure Boot update scheduled task" -Level INFO
    try {
        $Task = Get-ScheduledTask -TaskName "Secure-Boot-Update" -ErrorAction Stop
        
        if ($Task) {
            $TaskStatus = "TASK EXISTS"
            Write-Log "Scheduled task 'Secure-Boot-Update': Found" -Level SUCCESS
        } else {
            $TaskStatus = "TASK MISSING"
            Write-Log "Scheduled task 'Secure-Boot-Update': Not found" -Level WARN
            $script:ComplianceIssues++
        }
    } catch {
        $TaskStatus = "TASK MISSING"
        Write-Log "Scheduled task 'Secure-Boot-Update': Not found" -Level WARN
        $script:ComplianceIssues++
    }
    
    Set-NinjaField -FieldName "securebootTask" -Value "TASK: $TaskStatus"
    
    # 5. Audit UEFI Certificates
    Write-Log "Auditing UEFI certificate database" -Level INFO
    $CertResults = @()
    
    try {
        $DBBytes = Get-SecureBootUEFI -Name db -ErrorAction Stop
        $DBString = [System.Text.Encoding]::ASCII.GetString($DBBytes.Bytes)
        
        Write-Log "Retrieved UEFI database (db) - Size: $($DBBytes.Bytes.Length) bytes" -Level DEBUG
        
        foreach ($CertName in $CheckCertificates) {
            if ($DBString -match [regex]::Escape($CertName)) {
                $CertResults += "FOUND: $CertName"
                Write-Log "Certificate found: $CertName" -Level SUCCESS
            } else {
                $CertResults += "MISSING: $CertName"
                Write-Log "Certificate missing: $CertName" -Level WARN
                $script:ComplianceIssues++
            }
        }
        
    } catch {
        $CertResults += "ERROR: Unable to read UEFI database"
        Write-Log "Failed to read UEFI certificate database: $_" -Level ERROR
        $script:ComplianceIssues++
    }
    
    $CertResultsString = "CERTIFICATES:`n" + ($CertResults -join "`n")
    Set-NinjaField -FieldName "securebootCertificates" -Value $CertResultsString
    
    # Determine Overall Compliance
    if ($script:ComplianceIssues -eq 0) {
        $ComplianceStatus = "Compliant"
        Write-Log "Overall Compliance: COMPLIANT (No issues found)" -Level SUCCESS
    } elseif ($script:ComplianceIssues -le 2) {
        $ComplianceStatus = "Partial"
        Write-Log "Overall Compliance: PARTIAL ($script:ComplianceIssues issues found)" -Level WARN
    } else {
        $ComplianceStatus = "NonCompliant"
        Write-Log "Overall Compliance: NON-COMPLIANT ($script:ComplianceIssues issues found)" -Level WARN
    }
    
    Set-NinjaField -FieldName "securebootCompliance" -Value $ComplianceStatus
    Set-NinjaField -FieldName "securebootDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "Secure Boot compliance audit completed" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "securebootCompliance" -Value "AuditFailed"
    Set-NinjaField -FieldName "securebootDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    Write-Log "  Compliance Issues: $script:ComplianceIssues" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
