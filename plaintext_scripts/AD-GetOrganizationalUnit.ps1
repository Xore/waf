#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Retrieves the Organizational Unit(s) this device belongs to in Active Directory

.DESCRIPTION
    Queries Active Directory to determine which Organizational Unit(s) the local computer
    is a member of. Retrieves the distinguished name from Group Policy State registry
    and validates domain connectivity.
    
    The script performs the following:
    - Validates administrator privileges
    - Checks domain membership status
    - Retrieves OU distinguished name from registry
    - Tests secure channel to verify domain connectivity
    - Indicates if OU information is cached vs live
    - Optionally saves results to NinjaRMM custom field
    
    This script runs unattended without user interaction.

.PARAMETER CustomFieldName
    Optional name of a multiline custom field to store OU distinguished name.
    If not domain-joined, will store "Workgroup" instead.

.EXAMPLE
    .\AD-GetOrganizationalUnit.ps1
    
    Retrieves OU membership and displays to console.

.EXAMPLE
    .\AD-GetOrganizationalUnit.ps1 -CustomFieldName "deviceOrgUnit"
    
    Retrieves OU membership and saves to specified custom field.

.NOTES
    Script Name:    AD-GetOrganizationalUnit.ps1
    Author:         Windows Automation Framework
    Version:        2.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~2-5 seconds (measured average)
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName parameter (if specified) - OU distinguished name
        - adOrgUnitStatus (Success/Failed/Workgroup)
        - adOrgUnit (OU path)
        - adOrgUnitCached (Yes/No)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Domain-joined computer (returns Workgroup if not)
    
    Environment Variables (Optional):
        - customFieldName: Alternative to -CustomFieldName parameter
    
    Exit Codes:
        0 - Success (OU retrieved or workgroup detected)
        1 - Failure (access denied, query failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name to store OU")]
    [ValidateNotNullOrEmpty()]
    [String]$CustomFieldName
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "2.0"
$ScriptName = "AD-GetOrganizationalUnit"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# Registry path for Group Policy OU information
$GPStatePath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine'

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

function Test-IsDomainJoined {
    <#
    .SYNOPSIS
        Checks if computer is joined to a domain
    #>
    try {
        $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        return $ComputerSystem.PartOfDomain
    } catch {
        Write-Log "Error checking domain status: $_" -Level ERROR
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
    
    # Check for environment variable override
    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomFieldName = $env:customFieldName
        Write-Log "Using custom field from environment: $CustomFieldName" -Level INFO
    }
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Check domain membership
    Write-Log "Checking domain membership status" -Level INFO
    $IsDomainJoined = Test-IsDomainJoined
    
    if (-not $IsDomainJoined) {
        Write-Log "Computer is not domain-joined (Workgroup)" -Level INFO
        
        if ($CustomFieldName) {
            Set-NinjaField -FieldName $CustomFieldName -Value "Workgroup"
            Write-Log "Set custom field to 'Workgroup'" -Level SUCCESS
        }
        
        Set-NinjaField -FieldName "adOrgUnitStatus" -Value "Workgroup"
        Set-NinjaField -FieldName "adOrgUnit" -Value "Workgroup"
        
        Write-Log "Computer is in Workgroup (not domain-joined)" -Level INFO
        exit 0
    }
    
    Write-Log "Computer is domain-joined" -Level INFO
    
    # Retrieve OU from registry
    Write-Log "Querying Group Policy State registry for OU information" -Level DEBUG
    
    try {
        $DistinguishedName = Get-ItemProperty -Path $GPStatePath -Name 'Distinguished-Name' -ErrorAction Stop
        
        if ($DistinguishedName -and $DistinguishedName.'Distinguished-Name') {
            # Remove computer name, keep only OU path
            $OrganizationalUnit = $DistinguishedName.'Distinguished-Name' -replace '^CN=.*?,', ''
            Write-Log "Retrieved OU from registry: $OrganizationalUnit" -Level INFO
        } else {
            throw "Distinguished-Name property is empty"
        }
    } catch {
        Write-Log "Failed to retrieve OU from Group Policy State: $_" -Level WARN
        throw "Unable to retrieve Organizational Unit information"
    }
    
    # Test secure channel to verify if OU is live or cached
    Write-Log "Testing secure channel connectivity" -Level DEBUG
    $SecureChannelTest = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
    
    if ($SecureChannelTest) {
        Write-Log "Secure channel test passed - OU information is live" -Level INFO
        $IsCached = "No"
    } else {
        Write-Log "Secure channel test failed - OU information may be cached" -Level WARN
        $OrganizationalUnit = "(Cached) $OrganizationalUnit"
        $IsCached = "Yes"
    }
    
    # Display results
    Write-Log "Organizational Unit for $env:COMPUTERNAME: $OrganizationalUnit" -Level SUCCESS
    
    # Update NinjaRMM fields
    Set-NinjaField -FieldName "adOrgUnitStatus" -Value "Success"
    Set-NinjaField -FieldName "adOrgUnit" -Value $OrganizationalUnit
    Set-NinjaField -FieldName "adOrgUnitCached" -Value $IsCached
    
    # Save to custom field if specified
    if ($CustomFieldName) {
        Set-NinjaField -FieldName $CustomFieldName -Value $OrganizationalUnit
        Write-Log "Successfully set Custom Field: $CustomFieldName" -Level SUCCESS
    }
    
    Write-Log "OU query completed successfully" -Level INFO
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Update failure status
    Set-NinjaField -FieldName "adOrgUnitStatus" -Value "Failed"
    
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
