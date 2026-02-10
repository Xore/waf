#Requires -Version 5.1

<#
.SYNOPSIS
    Updates Cepros CDB Server URL based on network location

.DESCRIPTION
    Automatically configures the Cepros CONTACT CIM Database Desktop ServerURL
    setting in cdbpc.ini based on the system's current IP address. Maps IP address
    prefixes to specific CDB server URLs, allowing seamless configuration across
    different network locations.
    
    The script performs the following:
    - Retrieves all private IP addresses from the system using ipconfig
    - Matches IP addresses against configured location map
    - Updates cdbpc.ini [Login] section with appropriate ServerURL
    - Sets language to German (de) as default
    - Disables OIDC and persistent web environment settings
    - Reports configuration status
    
    Private IP ranges detected:
    - Class A: 10.0.0.0/8
    - Class B: 172.16.0.0/12
    - Class C: 192.168.0.0/16
    
    This script runs unattended without user interaction.

.PARAMETER IpLocationMap
    Hashtable mapping IP prefixes to server URLs and location names.
    Format: @{"10.1." = @("https://server.com", "LocationName")}
    Default maps provided for example locations.

.PARAMETER IniFilePath
    Full path to the cdbpc.ini configuration file.
    Default: C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.ini
    Can be overridden by environment variable: iniFilePath

.EXAMPLE
    .\Cepros-UpdateCDBServerURL.ps1
    
    Detected IP: 10.1.50.100
    Matched location for IP prefix 10.1.
    Server URL: https://example1.com
    Configuration file updated successfully

.EXAMPLE
    .\Cepros-UpdateCDBServerURL.ps1 -IniFilePath "C:\Cepros\config.ini"
    
    Uses custom INI file path.

.EXAMPLE
    .\Cepros-UpdateCDBServerURL.ps1 -IpLocationMap @{"192.168.1." = @("https://myserver.local", "Office")}
    
    Uses custom IP-to-location mapping.

.NOTES
    Script Name:    Cepros-UpdateCDBServerURL.ps1
    Author:         Windows Automation Framework
    Version:        3.0.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or User (via NinjaRMM automation)
    Execution Frequency: On-demand, at startup, or network change
    Typical Duration: ~1-2 seconds
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - None (consider adding status fields in future)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Write access to INI file
        - ipconfig.exe (built-in Windows command)
        - Cepros CONTACT CIM Database Desktop installed
    
    Environment Variables (Optional):
        - iniFilePath: Override default INI file path
    
    Exit Codes:
        0 - Success (server URL updated)
        1 - Failure (no matching location, file access error, or no IPs found)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/ipconfig
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="IP prefix to server URL mapping")]
    [ValidateNotNull()]
    [hashtable]$IpLocationMap = @{
        "10.1." = @("https://example1.com", "Location1")
        "10.8." = @("https://example1.com", "Location2")
    },
    
    [Parameter(Mandatory=$false, HelpMessage="Full path to cdbpc.ini file")]
    [ValidateNotNullOrEmpty()]
    [string]$IniFilePath = "C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.ini"
)

begin {
    Set-StrictMode -Version Latest
    
    # ============================================================================
    # CONFIGURATION
    # ============================================================================
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Cepros-UpdateCDBServerURL"
    
    # NinjaRMM CLI path for fallback
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    # ============================================================================
    # INITIALIZATION
    # ============================================================================
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $script:ExitCode = 0
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
    
    function Get-PrivateIPs {
        <#
        .SYNOPSIS
            Retrieves all private IP addresses from the system using ipconfig
        #>
        try {
            Write-Log "Retrieving IP addresses from system" -Level DEBUG
            $IpconfigOutput = ipconfig
            $PrivateIPs = @()
            
            foreach ($Line in $IpconfigOutput) {
                if ($Line -match "IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)") {
                    $Ip = $matches[1]
                    
                    # Match private IP ranges (exclude loopback)
                    if ($Ip -match "^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)" -and $Ip -ne "127.0.0.1") {
                        $PrivateIPs += $Ip
                        Write-Log "Found private IP: $Ip" -Level DEBUG
                    }
                }
            }
            
            return $PrivateIPs
            
        } catch {
            Write-Log "Unable to retrieve private IP addresses using ipconfig: $($_.Exception.Message)" -Level ERROR
            return @()
        }
    }
    
    function Get-LocationFromIP {
        <#
        .SYNOPSIS
            Maps an IP address to a server URL based on prefix matching
        #>
        param(
            [Parameter(Mandatory=$true)]
            [string]$IpAddress,
            
            [Parameter(Mandatory=$true)]
            [hashtable]$LocationMap
        )
        
        foreach ($Prefix in $LocationMap.Keys) {
            if ($IpAddress.StartsWith($Prefix)) {
                Write-Log "IP prefix '$Prefix' matched for IP: $IpAddress" -Level DEBUG
                return $LocationMap[$Prefix][0]
            }
        }
        
        Write-Log "No matching prefix found for IP: $IpAddress" -Level DEBUG
        return $null
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        # Check for environment variable override
        if ($env:iniFilePath -and $env:iniFilePath -notlike 'null') {
            $IniFilePath = $env:iniFilePath
            Write-Log "Using INI path from environment: $IniFilePath" -Level INFO
        }
        
        Write-Log "Target INI file: $IniFilePath" -Level INFO
        
        # ============================================================================
        # DETECT PRIVATE IP ADDRESSES
        # ============================================================================
        
        $PrivateIPs = Get-PrivateIPs
        
        if ($PrivateIPs.Count -eq 0) {
            Write-Log "No private IP addresses found on this system" -Level ERROR
            Write-Log "System may not be on a private network" -Level ERROR
            $script:ExitCode = 1
            return
        }
        
        Write-Log "Detected $($PrivateIPs.Count) private IP address(es)" -Level SUCCESS
        foreach ($Ip in $PrivateIPs) {
            Write-Log "  - $Ip" -Level INFO
        }
        
        # ============================================================================
        # MATCH IP TO LOCATION AND UPDATE CONFIG
        # ============================================================================
        
        $MatchFound = $false
        foreach ($Ip in $PrivateIPs) {
            Write-Log "Checking IP for location match: $Ip" -Level INFO
            
            $ServerUrl = Get-LocationFromIP -IpAddress $Ip -LocationMap $IpLocationMap
            
            if ($ServerUrl) {
                Write-Log "Location match found!" -Level SUCCESS
                Write-Log "Server URL: $ServerUrl" -Level INFO
                
                # Build INI content
                $IniContent = @"
[Login]
Language=de
LoginUseOIDC=0
PersistentWebEnv=0
ServerURL=$ServerUrl
"@
                
                # Write to INI file
                try {
                    Set-Content -Path $IniFilePath -Value $IniContent -Force -ErrorAction Stop
                    Write-Log "Configuration file updated successfully" -Level SUCCESS
                    Write-Log "INI file path: $IniFilePath" -Level INFO
                    $MatchFound = $true
                    break
                    
                } catch {
                    Write-Log "Failed to write to INI file: $($_.Exception.Message)" -Level ERROR
                    $script:ExitCode = 1
                    return
                }
            }
        }
        
        # ============================================================================
        # VALIDATE RESULT
        # ============================================================================
        
        if (-not $MatchFound) {
            Write-Log "No matching location found for any detected IP addresses" -Level WARN
            Write-Log "Available prefixes in location map:" -Level INFO
            foreach ($Prefix in $IpLocationMap.Keys) {
                Write-Log "  - $Prefix -> $($IpLocationMap[$Prefix][1])" -Level INFO
            }
            $script:ExitCode = 1
        } else {
            Write-Log "Cepros CDB Server URL update completed successfully" -Level SUCCESS
            $script:ExitCode = 0
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
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
        
    } finally {
        # Force garbage collection
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
