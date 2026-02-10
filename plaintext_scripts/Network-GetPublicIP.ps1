#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves the public IP address of the computer by querying external services.

.DESCRIPTION
    This script queries external IP detection services to determine the computer's public-facing 
    IP address. This is useful for systems behind NAT/firewall to identify their external IP, 
    which differs from internal LAN addresses.
    
    The script attempts multiple reliable IP detection services with fallback logic to ensure 
    successful retrieval even if one service is unavailable.

.PARAMETER SaveToCustomField
    Name of a custom field to save the detected public IP address.

.EXAMPLE
    .\Network-GetPublicIP.ps1

    Detecting public IP address...
    Public IP: 203.0.113.42

.EXAMPLE
    .\Network-GetPublicIP.ps1 -SaveToCustomField "PublicIP"

    Detecting public IP address...
    Public IP: 203.0.113.42
    IP address saved to custom field 'PublicIP'

.OUTPUTS
    None

.NOTES
    File Name      : Network-GetPublicIP.ps1
    Prerequisite   : PowerShell 5.1 or higher, Internet connectivity
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced fallback logic and error handling
    - 1.0: Initial release
    
.COMPONENT
    Invoke-RestMethod - HTTP client for API queries
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Queries external IP detection services (ifconfig.me, ipinfo.io, api.ipify.org)
    - Uses fallback logic with multiple services for reliability
    - Detects public-facing IP address behind NAT/firewall
    - Validates IP address format
    - Can save IP address to custom fields for tracking
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SaveToCustomField
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Network-GetPublicIP"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Write-Output "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Name,
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
            $Value
        )
        
        try {
            $CustomField = $Value | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
            Write-Log "Custom field '$Name' set successfully" -Level DEBUG
        } catch {
            Write-Log "Failed to set custom field '$Name': $_" -Level ERROR
            throw
        }
    }

    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
        Write-Log "Using SaveToCustomField from environment: $SaveToCustomField" -Level DEBUG
    }

    $IPServices = @(
        "https://ifconfig.me/ip",
        "https://api.ipify.org",
        "https://ipinfo.io/ip"
    )
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        Write-Log "Detecting public IP address..." -Level INFO
        
        $PublicIP = $null
        $ServiceTried = 0
        
        foreach ($Service in $IPServices) {
            $ServiceTried++
            try {
                Write-Log "Querying service $ServiceTried/$($IPServices.Count): $Service" -Level DEBUG
                $Response = Invoke-RestMethod -Uri $Service -TimeoutSec 10 -ErrorAction Stop
                $PublicIP = $Response.Trim()
                
                if ($PublicIP -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
                    Write-Log "Successfully retrieved IP: $PublicIP" -Level SUCCESS
                    Write-Log "Public IP: $PublicIP" -Level INFO
                    break
                } else {
                    Write-Log "Invalid IP format received from $Service: $PublicIP" -Level WARN
                    $PublicIP = $null
                }
            } catch {
                Write-Log "Failed to query $Service - $_" -Level WARN
            }
        }

        if (-not $PublicIP) {
            throw "Could not detect public IP address from any service"
        }

        if ($SaveToCustomField) {
            try {
                $PublicIP | Set-NinjaProperty -Name $SaveToCustomField
                Write-Log "IP address saved to custom field '$SaveToCustomField'" -Level INFO
            } catch {
                Write-Log "Failed to save to custom field: $_" -Level ERROR
                $script:ExitCode = 1
            }
        }
        
        Write-Log "Public IP detection completed successfully" -Level SUCCESS
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
