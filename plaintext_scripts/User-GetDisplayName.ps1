#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves the display name of the currently logged-in user from Active Directory

.DESCRIPTION
    Queries Active Directory for the display name of the user currently logged into
    the computer and stores it in a NinjaRMM custom field.
    
    The script performs the following:
    - Identifies the currently logged-in user
    - Queries Active Directory for user's display name
    - Updates specified NinjaRMM custom field with the display name
    - Handles domain-qualified usernames
    
    This script runs unattended without user interaction.

.PARAMETER CustomFieldName
    Name of the NinjaRMM custom field to store the display name.
    Default: "userDisplayName"

.EXAMPLE
    .\User-GetDisplayName.ps1
    
    Gets display name of logged-in user and stores in default field.

.EXAMPLE
    .\User-GetDisplayName.ps1 -CustomFieldName "currentUserName"
    
    Gets display name and stores in specified custom field.

.NOTES
    Script Name:    User-GetDisplayName.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - CustomFieldName parameter (default: userDisplayName) - User's display name
        - userDisplayNameStatus (Success/NoUser/Failed)
        - userDisplayNameDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - NinjaRMM Agent installed
        - Domain-joined computer
        - Active Directory access (automatic via logged-in user context)
    
    Environment Variables (Optional):
        - customFieldName: Override -CustomFieldName parameter
    
    Exit Codes:
        0 - Success (display name retrieved and stored)
        1 - Failure (no user logged in, AD query failed, or script error)

.LINK
    https://github.com/Xore/waf
    https://docs.microsoft.com/dotnet/api/system.directoryservices.directorysearcher
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for display name")]
    [ValidateNotNullOrEmpty()]
    [string]$CustomFieldName = "userDisplayName"
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "User-GetDisplayName"

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

function Get-LoggedInUsername {
    <#
    .SYNOPSIS
        Gets the username of the currently logged-in user
    #>
    [CmdletBinding()]
    param()
    
    try {
        $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $FullUsername = $ComputerSystem.UserName
        
        if ([string]::IsNullOrWhiteSpace($FullUsername)) {
            Write-Log "No user currently logged in" -Level WARN
            return $null
        }
        
        Write-Log "Full username: $FullUsername" -Level DEBUG
        
        # Strip domain prefix if present (DOMAIN\username -> username)
        if ($FullUsername -match '\\') {
            $Username = ($FullUsername -split '\\')[1]
        } else {
            $Username = $FullUsername
        }
        
        Write-Log "SAM account name: $Username" -Level INFO
        return $Username
        
    } catch {
        Write-Log "Failed to get logged-in username: $_" -Level ERROR
        return $null
    }
}

function Get-ADUserDisplayName {
    <#
    .SYNOPSIS
        Queries Active Directory for user's display name
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName
    )
    
    try {
        Write-Log "Querying Active Directory for user: $SamAccountName" -Level INFO
        
        # Build LDAP filter
        $Filter = "(&(objectCategory=User)(samAccountName=$SamAccountName))"
        Write-Log "LDAP filter: $Filter" -Level DEBUG
        
        # Create directory searcher
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.Filter = $Filter
        $Searcher.PropertiesToLoad.Add("displayName") | Out-Null
        $Searcher.PropertiesToLoad.Add("mail") | Out-Null
        $Searcher.PropertiesToLoad.Add("title") | Out-Null
        
        # Execute search
        $Result = $Searcher.FindOne()
        
        if ($null -eq $Result) {
            Write-Log "User not found in Active Directory: $SamAccountName" -Level WARN
            return $null
        }
        
        # Get directory entry
        $User = $Result.GetDirectoryEntry()
        $DisplayName = $User.Properties['displayName'].Value
        
        if ([string]::IsNullOrWhiteSpace($DisplayName)) {
            Write-Log "Display name is empty for user: $SamAccountName" -Level WARN
            return $null
        }
        
        Write-Log "Display name found: $DisplayName" -Level SUCCESS
        
        # Get additional info for logging
        $Email = $User.Properties['mail'].Value
        $Title = $User.Properties['title'].Value
        
        if ($Email) { Write-Log "Email: $Email" -Level DEBUG }
        if ($Title) { Write-Log "Title: $Title" -Level DEBUG }
        
        return $DisplayName
        
    } catch {
        Write-Log "Failed to query Active Directory: $_" -Level ERROR
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
    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomFieldName = $env:customFieldName
        Write-Log "Using custom field from environment: $CustomFieldName" -Level INFO
    }
    
    Write-Log "Custom field: $CustomFieldName" -Level INFO
    
    # Get logged-in username
    $Username = Get-LoggedInUsername
    
    if (-not $Username) {
        Write-Log "Cannot determine display name - no user logged in" -Level WARN
        Set-NinjaField -FieldName "userDisplayNameStatus" -Value "NoUser"
        Set-NinjaField -FieldName "userDisplayNameDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        exit 0
    }
    
    # Query Active Directory for display name
    $DisplayName = Get-ADUserDisplayName -SamAccountName $Username
    
    if (-not $DisplayName) {
        throw "Failed to retrieve display name for user: $Username"
    }
    
    # Update NinjaRMM custom field
    Set-NinjaField -FieldName $CustomFieldName -Value $DisplayName
    Write-Log "Display name stored in field '$CustomFieldName': $DisplayName" -Level SUCCESS
    
    # Update status fields
    Set-NinjaField -FieldName "userDisplayNameStatus" -Value "Success"
    Set-NinjaField -FieldName "userDisplayNameDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "Display name retrieval completed successfully" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Update failure status
    Set-NinjaField -FieldName "userDisplayNameStatus" -Value "Failed"
    Set-NinjaField -FieldName "userDisplayNameDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
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
