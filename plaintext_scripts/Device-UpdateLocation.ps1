#Requires -Version 5.1

<#
.SYNOPSIS
    Automatically updates device location based on IP address

.DESCRIPTION
    Determines device location by analyzing private IP addresses and mapping them
    to configured location names. Updates NinjaRMM deviceLocation custom field
    when location changes.
    
    The script performs the following:
    - Retrieves all private IPv4 addresses from network adapters
    - Matches IP prefixes against location mapping table
    - Updates NinjaRMM deviceLocation field if location changes
    - Handles VPN connections and unknown locations
    
    This script runs unattended without user interaction.

.PARAMETER LocationMap
    Hashtable mapping IP prefixes to location names.
    Format: @{ "10.1." = "LocationName" }
    Default map includes Test1, Test2, Test3, and VPN locations.

.EXAMPLE
    .\Device-UpdateLocation.ps1
    
    Uses default location mappings to determine and update device location.

.EXAMPLE
    .\Device-UpdateLocation.ps1 -LocationMap @{ "192.168.1." = "MainOffice"; "192.168.2." = "Branch" }
    
    Uses custom location mappings.

.NOTES
    Script Name:    Device-UpdateLocation.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-09
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Every 15 minutes or on network change
    Typical Duration: ~1-2 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - deviceLocation - Current location based on IP
        - deviceLocationIP - Primary IP used for detection
        - deviceLocationUpdateDate - Last update timestamp
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - NinjaRMM Agent installed
        - Network connectivity
    
    Environment Variables (Optional):
        - LocationMapJson: JSON string containing custom IP-to-location mappings
        Example: {"10.1.":"Office1","10.2.":"Office2"}
    
    Exit Codes:
        0 - Success (location determined and updated if needed)
        1 - Failure (no IP addresses found or critical error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="IP prefix to location mapping")]
    [hashtable]$LocationMap = @{
        "10.1."    = "Test1"
        "10.2."    = "Test2"
        "10.3."    = "Test3"
        "10.254."  = "VPN"
    }
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Device-UpdateLocation"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# Private IP regex patterns
$PrivateIPPatterns = @(
    "^10\.",                           # Class A: 10.0.0.0/8
    "^172\.(1[6-9]|2[0-9]|3[0-1])\.", # Class B: 172.16.0.0/12
    "^192\.168\."                      # Class C: 192.168.0.0/16
)

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

function Get-NinjaField {
    <#
    .SYNOPSIS
        Gets a NinjaRMM custom field value with automatic fallback to CLI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName
    )
    
    # Method 1: Try Ninja-Property-Get cmdlet
    try {
        if (Get-Command Ninja-Property-Get -ErrorAction SilentlyContinue) {
            $Value = Ninja-Property-Get $FieldName -ErrorAction Stop
            Write-Log "Field '$FieldName' retrieved successfully" -Level DEBUG
            return $Value
        } else {
            throw "Ninja-Property-Get cmdlet not available"
        }
    } catch {
        Write-Log "Ninja-Property-Get failed, using CLI fallback" -Level DEBUG
        
        # Method 2: Fall back to NinjaRMM CLI
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            $CLIArgs = @("get", $FieldName)
            $Value = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI exit code: $LASTEXITCODE"
            }
            
            Write-Log "Field '$FieldName' retrieved via CLI" -Level DEBUG
            $script:CLIFallbackCount++
            return $Value
            
        } catch {
            Write-Log "Failed to get field '$FieldName': $_" -Level ERROR
            return $null
        }
    }
}

function Get-PrivateIPAddresses {
    <#
    .SYNOPSIS
        Retrieves all private IPv4 addresses from network adapters
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Retrieving private IP addresses" -Level DEBUG
        
        # Run ipconfig and parse output
        $IpconfigOutput = ipconfig
        $PrivateIPs = [System.Collections.Generic.List[string]]::new()
        
        foreach ($Line in $IpconfigOutput) {
            # Look for IPv4 Address lines
            if ($Line -match "IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)") {
                $IP = $matches[1]
                
                # Skip loopback
                if ($IP -eq "127.0.0.1") {
                    continue
                }
                
                # Check if private IP
                $IsPrivate = $false
                foreach ($Pattern in $PrivateIPPatterns) {
                    if ($IP -match $Pattern) {
                        $IsPrivate = $true
                        break
                    }
                }
                
                if ($IsPrivate) {
                    $PrivateIPs.Add($IP)
                    Write-Log "Found private IP: $IP" -Level DEBUG
                }
            }
        }
        
        return $PrivateIPs
        
    } catch {
        Write-Log "Error retrieving IP addresses: $_" -Level ERROR
        return @()
    }
}

function Get-LocationFromIP {
    <#
    .SYNOPSIS
        Matches IP address to location using prefix mapping
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Map
    )
    
    foreach ($Prefix in $Map.Keys) {
        if ($IPAddress.StartsWith($Prefix)) {
            Write-Log "IP $IPAddress matched prefix $Prefix = $($Map[$Prefix])" -Level DEBUG
            return $Map[$Prefix]
        }
    }
    
    return $null
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable override
    if ($env:LocationMapJson -and $env:LocationMapJson -notlike "null") {
        try {
            $LocationMap = $env:LocationMapJson | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            Write-Log "Using location map from environment" -Level INFO
        } catch {
            Write-Log "Failed to parse LocationMapJson, using default map" -Level WARN
        }
    }
    
    Write-Log "Location map configured with $($LocationMap.Count) prefix(es)" -Level INFO
    foreach ($Prefix in $LocationMap.Keys) {
        Write-Log "  $Prefix -> $($LocationMap[$Prefix])" -Level DEBUG
    }
    
    # Get current location from NinjaRMM
    $OldLocation = Get-NinjaField -FieldName "deviceLocation"
    Write-Log "Current location in NinjaRMM: $OldLocation" -Level INFO
    
    # Get all private IP addresses
    $PrivateIPs = Get-PrivateIPAddresses
    
    if ($PrivateIPs.Count -eq 0) {
        throw "No private IP addresses found on this device"
    }
    
    Write-Log "Found $($PrivateIPs.Count) private IP address(es)" -Level INFO
    
    # Try to match location for each IP (first match wins)
    $NewLocation = $null
    $MatchedIP = $null
    
    foreach ($IP in $PrivateIPs) {
        $Location = Get-LocationFromIP -IPAddress $IP -Map $LocationMap
        if ($Location) {
            $NewLocation = $Location
            $MatchedIP = $IP
            Write-Log "Location determined: $NewLocation (from IP: $IP)" -Level INFO
            break
        }
    }
    
    # Set to Unknown if no match found
    if (-not $NewLocation) {
        $NewLocation = "Unknown"
        $MatchedIP = $PrivateIPs[0]
        Write-Log "No location match found, setting to Unknown" -Level WARN
    }
    
    # Update location if changed
    if ($OldLocation -ne $NewLocation) {
        Write-Log "Location changed: $OldLocation -> $NewLocation" -Level INFO
        Set-NinjaField -FieldName "deviceLocation" -Value $NewLocation
        Write-Log "Location updated to: $NewLocation" -Level SUCCESS
    } else {
        Write-Log "Location unchanged: $NewLocation" -Level INFO
    }
    
    # Update additional tracking fields
    Set-NinjaField -FieldName "deviceLocationIP" -Value $MatchedIP
    Set-NinjaField -FieldName "deviceLocationUpdateDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    Write-Log "Device location update completed" -Level SUCCESS
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
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
