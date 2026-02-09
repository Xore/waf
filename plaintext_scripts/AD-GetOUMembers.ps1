#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Retrieves members of an Active Directory Organizational Unit

.DESCRIPTION
    Queries Active Directory for users within a specified Organizational Unit (OU).
    Searches for OUs matching the provided name and lists all user accounts within them.
    
    The script performs the following:
    - Validates Active Directory module availability
    - Searches for OUs matching the specified name
    - Retrieves all users from matching OUs
    - Displays results with OU distinguished names
    - Optionally saves results to NinjaRMM custom field
    
    This script runs unattended without user interaction.

.PARAMETER OU
    Name of the Organizational Unit to query.
    Supports wildcards (searches for OUs starting with this name).
    Example: "Sales" will match "OU=Sales,DC=contoso,DC=com"

.PARAMETER CustomField
    Optional name of NinjaRMM custom field to store results.
    Results will be saved as multiline text with OU paths and user lists.

.EXAMPLE
    .\AD-GetOUMembers.ps1 -OU "Sales"
    
    Retrieves all users from OUs starting with "Sales" and displays to console.

.EXAMPLE
    .\AD-GetOUMembers.ps1 -OU "IT" -CustomField "itOuMembers"
    
    Retrieves users from IT OUs and saves results to specified custom field.

.NOTES
    Script Name:    AD-GetOUMembers.ps1
    Author:         Windows Automation Framework
    Version:        2.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand
    Typical Duration: ~3-8 seconds (depends on OU size)
    Timeout Setting: 180 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomField parameter (if specified) - User list by OU
        - adOuQueryStatus (Success/Failed)
        - adOuQueryDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Active Directory PowerShell module (RSAT)
        - Must run on Domain Controller or system with RSAT
    
    Environment Variables (Optional):
        - OuName: Alternative to -OU parameter
        - CustomField: Alternative to -CustomField parameter
    
    Exit Codes:
        0 - Success (users retrieved)
        1 - Failure (missing module, access denied, query failed)

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/powershell/module/activedirectory/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Name of OU to query")]
    [ValidateNotNullOrEmpty()]
    [string]$OU,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field name to store results")]
    [ValidateNotNullOrEmpty()]
    [string]$CustomField
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "2.0"
$ScriptName = "AD-GetOUMembers"

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
    if ($env:OuName -and $env:OuName -notlike "null") {
        $OU = $env:OuName
        Write-Log "Using OU from environment: $OU" -Level INFO
    }
    
    if ($env:CustomField -and $env:CustomField -notlike "null") {
        $CustomField = $env:CustomField
        Write-Log "Using custom field from environment: $CustomField" -Level INFO
    }
    
    # Validate OU parameter
    if ([string]::IsNullOrWhiteSpace($OU)) {
        throw "OU parameter is required"
    }
    
    # Check Administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required"
    }
    Write-Log "Administrator privileges verified" -Level INFO
    
    # Check for Active Directory module
    Write-Log "Checking Active Directory module availability" -Level INFO
    if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
        throw "Active Directory PowerShell module not found. RSAT required. Run on Domain Controller or install RSAT."
    }
    
    # Import module
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Log "Active Directory module loaded" -Level INFO
    } catch {
        throw "Failed to import Active Directory module: $_"
    }
    
    # Search for OUs
    Write-Log "Searching for OUs matching: $OU" -Level INFO
    $OUPaths = Get-ADOrganizationalUnit -Filter * -ErrorAction Stop | 
        Where-Object { $_.DistinguishedName -like "OU=$OU*" } | 
        Select-Object -ExpandProperty DistinguishedName
    
    if (-not $OUPaths) {
        Write-Log "No OUs found matching: $OU" -Level WARN
        Set-NinjaField -FieldName "adOuQueryStatus" -Value "No Results"
        exit 0
    }
    
    Write-Log "Found $($OUPaths.Count) matching OU(s)" -Level INFO
    
    # Build report
    $Report = [System.Collections.Generic.List[string]]::new()
    $TotalUsers = 0
    
    foreach ($OUPath in $OUPaths) {
        Write-Log "Processing OU: $OUPath" -Level DEBUG
        
        $Report.Add("")
        $Report.Add($OUPath)
        $Report.Add("-" * $OUPath.Length)
        
        # Get users from OU
        try {
            $Users = Get-ADUser -Filter * -SearchBase $OUPath -ErrorAction Stop | 
                Select-Object -ExpandProperty UserPrincipalName
            
            if ($Users) {
                foreach ($User in $Users) {
                    $Report.Add($User)
                    $TotalUsers++
                }
                Write-Log "Found $($Users.Count) user(s) in $OUPath" -Level INFO
            } else {
                $Report.Add("(No users found)")
                Write-Log "No users found in $OUPath" -Level DEBUG
            }
        } catch {
            Write-Log "Error querying users from $OUPath - $_" -Level WARN
            $Report.Add("(Error: $_)")
        }
    }
    
    # Display report
    $ReportText = $Report -join "`n"
    Write-Log "OU Member Report:" -Level INFO
    Write-Log $ReportText -Level INFO
    Write-Log "Total users found: $TotalUsers" -Level SUCCESS
    
    # Save to custom field if specified
    if ($CustomField) {
        Set-NinjaField -FieldName $CustomField -Value $ReportText
        Write-Log "Results saved to custom field: $CustomField" -Level SUCCESS
    }
    
    # Update status fields
    Set-NinjaField -FieldName "adOuQueryStatus" -Value "Success"
    Set-NinjaField -FieldName "adOuQueryDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "OU member query completed successfully" -Level INFO
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Update failure status
    Set-NinjaField -FieldName "adOuQueryStatus" -Value "Failed"
    Set-NinjaField -FieldName "adOuQueryDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
