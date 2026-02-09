#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Monitors SSL certificates for expiration and reports findings

.DESCRIPTION
    Scans IIS HTTPS bindings for SSL/TLS certificates and checks expiration dates.
    Alerts on certificates expiring within specified threshold.
    
    The script performs the following:
    - Validates Windows Server 2012 R2 or higher
    - Scans IIS HTTPS bindings for certificates
    - Checks certificate expiration dates
    - Reports certificates expiring within threshold
    - Updates NinjaRMM custom field with findings
    
    This script runs unattended without user interaction.

.PARAMETER DaysToAlert
    Number of days before expiration to trigger alert.
    Default: 21 days

.PARAMETER CustomField
    Name of NinjaRMM custom field to store results.
    Default: "sslCertificates"

.EXAMPLE
    .\Certificates-GetExpiring.ps1
    
    Checks for certificates expiring within 21 days.

.EXAMPLE
    .\Certificates-GetExpiring.ps1 -DaysToAlert 30
    
    Checks for certificates expiring within 30 days.

.EXAMPLE
    .\Certificates-GetExpiring.ps1 -DaysToAlert 14 -CustomField "certStatus"
    
    Checks for certificates expiring within 14 days, saves to custom field.

.NOTES
    Script Name:    Certificates-GetExpiring.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily
    Typical Duration: ~2-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - sslCertificates (or custom field) - Certificate status report
        - certExpirationStatus (Healthy/Warning/Critical)
        - certLastCheckDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Windows Server 2012 R2 or higher
        - IIS Web Server role
        - WebAdministration PowerShell module
    
    Environment Variables (Optional):
        - DaysToAlert: Override default alert threshold
        - CustomFieldName: Override default custom field
    
    Exit Codes:
        0 - Success (no expiring certificates or check completed)
        1 - Failure (unsupported OS, missing IIS, script error)

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/iis/get-started/whats-new-in-iis-10/certificates
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Days before expiration to alert")]
    [ValidateRange(1,365)]
    [int]$DaysToAlert = 21,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for results")]
    [ValidateNotNullOrEmpty()]
    [string]$CustomField = "sslCertificates"
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Certificates-GetExpiring"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# Minimum supported OS version (6.3 = Server 2012 R2 / Windows 8.1)
$MinimumOSVersion = [version]"6.3"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:CLIFallbackCount = 0

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
    
    # Plain text output only - no colors
    Write-Output $LogMessage
    
    # Track counts
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
    
    # Method 1: Try Ninja-Property-Set cmdlet
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
        
        # Method 2: Fall back to NinjaRMM CLI
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

function Test-MinimumOSVersion {
    <#
    .SYNOPSIS
        Validates OS version meets minimum requirements
    #>
    try {
        $CurrentVersion = [version](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction Stop).CurrentVersion
        return ($CurrentVersion -ge $MinimumOSVersion)
    } catch {
        Write-Log "Failed to check OS version: $_" -Level ERROR
        return $false
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable overrides
    if ($env:DaysToAlert -and $env:DaysToAlert -match '^\d+$') {
        $DaysToAlert = [int]$env:DaysToAlert
        Write-Log "Using alert threshold from environment: $DaysToAlert days" -Level INFO
    }
    
    if ($env:CustomFieldName -and $env:CustomFieldName -notlike "null") {
        $CustomField = $env:CustomFieldName
        Write-Log "Using custom field from environment: $CustomField" -Level INFO
    }
    
    Write-Log "Alert threshold: $DaysToAlert days" -Level INFO
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Check OS version
    Write-Log "Checking OS version compatibility" -Level INFO
    if (-not (Test-MinimumOSVersion)) {
        throw "Unsupported OS. Only Server 2012 R2 and higher are supported."
    }
    Write-Log "OS version check passed" -Level INFO
    
    # Check for WebAdministration module
    Write-Log "Loading WebAdministration module" -Level INFO
    try {
        Import-Module WebAdministration -ErrorAction Stop
        Write-Log "WebAdministration module loaded" -Level INFO
    } catch {
        throw "Failed to load WebAdministration module. IIS may not be installed: $_"
    }
    
    # Get current date for comparisons
    $Today = Get-Date
    Write-Log "Scanning IIS HTTPS bindings for certificates" -Level INFO
    
    # Get all HTTPS bindings
    $CertsBound = Get-WebBinding | Where-Object { $_.Protocol -eq "https" }
    
    if (-not $CertsBound) {
        Write-Log "No HTTPS bindings found in IIS" -Level WARN
        $ResultMessage = "No HTTPS bindings configured in IIS"
        Set-NinjaField -FieldName $CustomField -Value $ResultMessage
        Set-NinjaField -FieldName "certExpirationStatus" -Value "NoBindings"
        Set-NinjaField -FieldName "certLastCheckDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        exit 0
    }
    
    Write-Log "Found $($CertsBound.Count) HTTPS binding(s)" -Level INFO
    
    # Check each certificate
    $ExpiringCerts = foreach ($Cert in $CertsBound) {
        try {
            $BindingInfo = $Cert.bindingInformation.Split(':')
            $HostHeader = $BindingInfo[2]
            $Port = $BindingInfo[1]
            $Thumbprint = $Cert.CertificateHash
            $Store = $Cert.CertificateStoreName
            
            Write-Log "Checking certificate: Thumbprint=$Thumbprint, Host=$HostHeader, Port=$Port" -Level DEBUG
            
            # Get certificate from store
            $CertFile = Get-ChildItem -Path "Cert:\LocalMachine\$Store" -ErrorAction Stop | 
                Where-Object { $_.Thumbprint -eq $Thumbprint }
            
            if (-not $CertFile) {
                Write-Log "Certificate not found in store: $Thumbprint" -Level WARN
                continue
            }
            
            # Calculate days until expiration
            $DaysRemaining = (New-TimeSpan -Start $Today -End $CertFile.NotAfter).Days
            
            Write-Log "Certificate expires in $DaysRemaining days" -Level DEBUG
            
            # Check if within alert threshold and has valid dates
            if ($DaysRemaining -lt $DaysToAlert -and $null -ne $CertFile.NotBefore -and $DaysRemaining -gt 0) {
                Write-Log "Certificate expiring soon: $($CertFile.Subject)" -Level WARN
                
                [PSCustomObject]@{
                    FriendlyName = $CertFile.FriendlyName
                    Subject      = $CertFile.Subject
                    HostHeader   = $HostHeader
                    Port         = $Port
                    NotBefore    = $CertFile.NotBefore
                    NotAfter     = $CertFile.NotAfter
                    DaysRemaining = $DaysRemaining
                    Thumbprint   = $Thumbprint
                }
            }
        } catch {
            Write-Log "Error processing certificate binding: $_" -Level ERROR
        }
    }
    
    # Generate report
    if (-not $ExpiringCerts) {
        $ResultMessage = "Healthy - No certificates expiring within $DaysToAlert days"
        $Status = "Healthy"
        Write-Log $ResultMessage -Level SUCCESS
    } else {
        $CertCount = ($ExpiringCerts | Measure-Object).Count
        Write-Log "WARNING: Found $CertCount certificate(s) expiring within $DaysToAlert days" -Level WARN
        
        $ReportLines = [System.Collections.Generic.List[string]]::new()
        $ReportLines.Add("ALERT: $CertCount certificate(s) expiring within $DaysToAlert days")
        $ReportLines.Add("")
        
        foreach ($Cert in $ExpiringCerts) {
            $ReportLines.Add("Certificate: $($Cert.Subject)")
            $ReportLines.Add("  Friendly Name: $($Cert.FriendlyName)")
            $ReportLines.Add("  Host: $($Cert.HostHeader)")
            $ReportLines.Add("  Port: $($Cert.Port)")
            $ReportLines.Add("  Valid From: $($Cert.NotBefore)")
            $ReportLines.Add("  Expires: $($Cert.NotAfter)")
            $ReportLines.Add("  Days Remaining: $($Cert.DaysRemaining)")
            $ReportLines.Add("  Thumbprint: $($Cert.Thumbprint)")
            $ReportLines.Add("")
        }
        
        $ReportLines.Add("Action Required: Renew certificates before expiration")
        
        $ResultMessage = $ReportLines -join "`n"
        
        # Determine status level
        $MinDays = ($ExpiringCerts | Measure-Object -Property DaysRemaining -Minimum).Minimum
        if ($MinDays -le 7) {
            $Status = "Critical"
        } else {
            $Status = "Warning"
        }
    }
    
    # Output full report
    Write-Log "Certificate Status Report:" -Level INFO
    Write-Log $ResultMessage -Level INFO
    
    # Update NinjaRMM fields
    Set-NinjaField -FieldName $CustomField -Value $ResultMessage
    Set-NinjaField -FieldName "certExpirationStatus" -Value $Status
    Set-NinjaField -FieldName "certLastCheckDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "Certificate expiration check completed" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Update failure status
    Set-NinjaField -FieldName "certExpirationStatus" -Value "Error"
    Set-NinjaField -FieldName "certLastCheckDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    exit 1
    
} finally {
    # Calculate and log execution time
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}

# Exit with appropriate code
if ($script:ErrorCount -gt 0) {
    exit 1
} else {
    exit 0
}
