#Requires -Version 5.1

<#
.SYNOPSIS
    Updates Cepros CDB Server URL based on network location.

.DESCRIPTION
    This script automatically configures the Cepros CONTACT CIM Database Desktop ServerURL
    setting in cdbpc.ini based on the system's current IP address. It maps IP address
    prefixes to specific CDB server URLs, allowing seamless configuration across different
    network locations.
    
    The script detects the system's private IP addresses using ipconfig and matches them
    against a configurable location map to determine the appropriate server URL.

.PARAMETER IpLocationMap
    Hashtable mapping IP prefixes to server URLs and location names.
    Format: @{"10.1." = @("https://server.com", "LocationName")}

.PARAMETER IniFilePath
    Full path to the cdbpc.ini configuration file.
    Default: C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.ini

.EXAMPLE
    .\Cepros-UpdateCDBServerURL.ps1
    
    Detected IP: 10.1.50.100
    Matched location for IP prefix 10.1.
    Server URL: https://example1.com
    Configuration file updated successfully

.EXAMPLE
    .\Cepros-UpdateCDBServerURL.ps1 -IniFilePath "C:\Cepros\config.ini"
    
    Uses custom INI file path.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : Cepros-UpdateCDBServerURL.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Requires       : Write access to INI file
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial version

.LINK
    https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/ipconfig
#>

[CmdletBinding()]
param(
    [Parameter()]
    [hashtable]$IpLocationMap = @{
        "10.1." = @("https://example1.com", "Location1")
        "10.8." = @("https://example1.com", "Location2")
    },
    
    [Parameter()]
    [string]$IniFilePath = "C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.ini"
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Output $logMessage }
        }
    }

    function Get-PrivateIPs {
        <#
        .SYNOPSIS
            Retrieves all private IP addresses from the system.
        #>
        try {
            $ipconfigOutput = ipconfig
            $privateIPs = @()
            
            foreach ($line in $ipconfigOutput) {
                if ($line -match "IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)") {
                    $ip = $matches[1]
                    if ($ip -match "^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)" -and $ip -ne "127.0.0.1") {
                        $privateIPs += $ip
                    }
                }
            }
            
            return $privateIPs
        }
        catch {
            Write-Log "Unable to retrieve private IP addresses using ipconfig: $_" -Level ERROR
            return @()
        }
    }

    function Get-LocationFromIP {
        <#
        .SYNOPSIS
            Maps an IP address to a server URL based on prefix matching.
        #>
        param([string]$IpAddress, [hashtable]$LocationMap)
        
        foreach ($prefix in $LocationMap.Keys) {
            if ($IpAddress.StartsWith($prefix)) {
                return $LocationMap[$prefix][0]
            }
        }
        return $null
    }

    if ($env:iniFilePath -and $env:iniFilePath -notlike 'null') {
        $IniFilePath = $env:iniFilePath
    }

    $ExitCode = 0
}

process {
    try {
        Write-Log "Starting Cepros CDB Server URL update"
        
        $PrivateIPs = Get-PrivateIPs
        
        if ($PrivateIPs.Count -eq 0) {
            throw "No private IP addresses found on this system"
        }
        
        Write-Log "Detected $($PrivateIPs.Count) private IP address(es)"
        
        $matchFound = $false
        foreach ($ip in $PrivateIPs) {
            Write-Log "Checking IP: $ip"
            $location = Get-LocationFromIP -IpAddress $ip -LocationMap $IpLocationMap
            
            if ($location) {
                Write-Log "Matched location for IP prefix"
                Write-Log "Server URL: $location"
                
                $iniContent = @"
[Login]
Language=de
LoginUseOIDC=0
PersistentWebEnv=0
ServerURL=$location
"@
                
                Set-Content -Path $IniFilePath -Value $iniContent -Force
                Write-Log "Configuration file updated successfully: $IniFilePath"
                $matchFound = $true
                break
            }
        }
        
        if (-not $matchFound) {
            Write-Log "No matching location found for any detected IP addresses" -Level WARNING
            $ExitCode = 1
        }
        else {
            Write-Log "Cepros CDB Server URL update completed successfully"
        }
    }
    catch {
        Write-Log "Failed to update Cepros CDB Server URL: $_" -Level ERROR
        $ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $Duration seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
