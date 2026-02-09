#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Retrieves IIS SSL/TLS certificate bindings and details

.DESCRIPTION
    Enumerates all SSL bindings in IIS and displays associated certificate information
    including site names, certificate details, and expiration dates.
    
    The script performs the following:
    - Imports WebAdministration module
    - Scans all SSL bindings in IIS
    - Retrieves certificate details from local machine store
    - Reports binding information with certificate metadata
    - Optionally saves results to NinjaRMM custom field
    
    This script runs unattended without user interaction.

.PARAMETER CustomField
    Optional name of NinjaRMM custom field to store binding report.
    Results will be stored as formatted text.

.PARAMETER OutputFormat
    Format for output display.
    Valid values: Table, List, JSON
    Default: Table

.EXAMPLE
    .\IIS-GetBindings.ps1
    
    Displays all IIS SSL bindings in table format.

.EXAMPLE
    .\IIS-GetBindings.ps1 -CustomField "iisBindings"
    
    Retrieves bindings and saves to specified custom field.

.EXAMPLE
    .\IIS-GetBindings.ps1 -OutputFormat List
    
    Displays bindings in detailed list format.

.NOTES
    Script Name:    IIS-GetBindings.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~2-5 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomField parameter (if specified) - Binding report
        - iisBindingsStatus (Success/NoBindings/Failed)
        - iisBindingsCount (number of bindings found)
        - iisBindingsDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - IIS Web Server role
        - WebAdministration PowerShell module
    
    Environment Variables (Optional):
        - customFieldName: Override -CustomField parameter
        - outputFormat: Override -OutputFormat parameter
    
    Exit Codes:
        0 - Success (bindings retrieved)
        1 - Failure (IIS not installed, module missing, script error)

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/iis/get-started/whats-new-in-iis-10/wildcard-host-header-support
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for binding report")]
    [ValidateNotNullOrEmpty()]
    [string]$CustomField,
    
    [Parameter(Mandatory=$false, HelpMessage="Output format for display")]
    [ValidateSet('Table','List','JSON')]
    [string]$OutputFormat = 'Table'
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "IIS-GetBindings"

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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable overrides
    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomField = $env:customFieldName
        Write-Log "Using custom field from environment: $CustomField" -Level INFO
    }
    
    if ($env:outputFormat -and $env:outputFormat -notlike "null") {
        $OutputFormat = $env:outputFormat
        Write-Log "Using output format from environment: $OutputFormat" -Level INFO
    }
    
    Write-Log "Output format: $OutputFormat" -Level INFO
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Import WebAdministration module
    Write-Log "Loading WebAdministration module" -Level INFO
    try {
        Import-Module WebAdministration -ErrorAction Stop
        Write-Log "WebAdministration module loaded successfully" -Level INFO
    } catch {
        throw "Failed to load WebAdministration module. IIS may not be installed: $_"
    }
    
    # Get SSL bindings from IIS
    Write-Log "Retrieving IIS SSL bindings" -Level INFO
    
    $Bindings = Get-ChildItem -Path IIS:SSLBindings -ErrorAction Stop | 
        Sort-Object Port | 
        ForEach-Object {
            if ($_.Sites) {
                try {
                    Write-Log "Processing binding for port $($_.Port)" -Level DEBUG
                    
                    # Get certificate from local machine store
                    $Certificate = Get-ChildItem -Path CERT:LocalMachine/My -ErrorAction Stop |
                        Where-Object { $_.Thumbprint -eq $_.Thumbprint }
                    
                    if ($Certificate) {
                        # Calculate days until expiration
                        $DaysUntilExpiration = ($Certificate.NotAfter - (Get-Date)).Days
                        
                        # Create binding object
                        [PSCustomObject]@{
                            Sites                   = $_.Sites.Value
                            Port                    = $_.Port
                            IPAddress               = $_.IPAddress
                            HostNamePort            = $_.HostNamePort
                            CertificateFriendlyName = $Certificate.FriendlyName
                            CertificateDnsNames     = ($Certificate.DnsNameList | Select-Object -ExpandProperty Unicode) -join ', '
                            CertificateNotBefore    = $Certificate.NotBefore
                            CertificateNotAfter     = $Certificate.NotAfter
                            DaysUntilExpiration     = $DaysUntilExpiration
                            CertificateIssuer       = $Certificate.Issuer
                            CertificateThumbprint   = $Certificate.Thumbprint
                        }
                    } else {
                        Write-Log "Certificate not found for binding on port $($_.Port)" -Level WARN
                    }
                } catch {
                    Write-Log "Error processing binding: $_" -Level ERROR
                }
            }
        }
    
    # Check if any bindings found
    if (-not $Bindings) {
        Write-Log "No SSL bindings found in IIS" -Level WARN
        Set-NinjaField -FieldName "iisBindingsStatus" -Value "NoBindings"
        Set-NinjaField -FieldName "iisBindingsCount" -Value 0
        Set-NinjaField -FieldName "iisBindingsDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        Write-Log "No SSL bindings configured" -Level INFO
        exit 0
    }
    
    $BindingCount = ($Bindings | Measure-Object).Count
    Write-Log "Found $BindingCount SSL binding(s)" -Level SUCCESS
    
    # Format output based on specified format
    $OutputText = ""
    
    switch ($OutputFormat) {
        'Table' {
            $OutputText = $Bindings | Format-Table -AutoSize | Out-String
        }
        'List' {
            $OutputText = $Bindings | Format-List | Out-String
        }
        'JSON' {
            $OutputText = $Bindings | ConvertTo-Json -Depth 3
        }
    }
    
    # Display bindings
    Write-Log "IIS SSL Bindings:" -Level INFO
    Write-Log $OutputText -Level INFO
    
    # Check for expiring certificates
    $ExpiringCerts = $Bindings | Where-Object { $_.DaysUntilExpiration -lt 30 -and $_.DaysUntilExpiration -gt 0 }
    if ($ExpiringCerts) {
        $ExpireCount = ($ExpiringCerts | Measure-Object).Count
        Write-Log "WARNING: $ExpireCount certificate(s) expiring within 30 days" -Level WARN
        
        foreach ($Cert in $ExpiringCerts) {
            Write-Log "  Site: $($Cert.Sites), Expires: $($Cert.CertificateNotAfter), Days: $($Cert.DaysUntilExpiration)" -Level WARN
        }
    }
    
    # Save to custom field if specified
    if ($CustomField) {
        Set-NinjaField -FieldName $CustomField -Value $OutputText
        Write-Log "Bindings saved to custom field: $CustomField" -Level SUCCESS
    }
    
    # Update status fields
    Set-NinjaField -FieldName "iisBindingsStatus" -Value "Success"
    Set-NinjaField -FieldName "iisBindingsCount" -Value $BindingCount
    Set-NinjaField -FieldName "iisBindingsDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "IIS binding retrieval completed successfully" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Update failure status
    Set-NinjaField -FieldName "iisBindingsStatus" -Value "Failed"
    Set-NinjaField -FieldName "iisBindingsDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
