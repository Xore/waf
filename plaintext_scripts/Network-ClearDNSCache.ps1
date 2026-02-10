#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Clears the DNS resolver cache multiple times

.DESCRIPTION
    Flushes the DNS client cache the specified number of times to resolve
    DNS-related connectivity issues. Supports both modern PowerShell cmdlets
    and legacy ipconfig fallback.
    
    The script performs the following:
    - Validates administrator privileges
    - Clears DNS cache using Clear-DnsClientCache or ipconfig /flushdns
    - Retries specified number of times with delays
    - Displays current DNS cache after clearing
    - Reports success or failure to NinjaRMM
    
    This script runs unattended without user interaction.

.PARAMETER Attempts
    Number of times to clear the DNS cache.
    Default: 3
    Range: 1-10

.PARAMETER DelaySeconds
    Seconds to wait between clearing attempts.
    Default: 1
    Range: 0-5

.EXAMPLE
    .\Network-ClearDNSCache.ps1
    
    Clears DNS cache 3 times with 1 second delay between attempts.

.EXAMPLE
    .\Network-ClearDNSCache.ps1 -Attempts 5
    
    Clears DNS cache 5 times.

.EXAMPLE
    .\Network-ClearDNSCache.ps1 -Attempts 1 -DelaySeconds 0
    
    Clears DNS cache once with no delay.

.NOTES
    File Name      : Network-ClearDNSCache.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced retry logic and error handling
    - 2.0: Added NinjaRMM integration
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or when DNS issues detected
    Typical Duration: 3-10 seconds (depends on attempts)
    Timeout Setting: 60 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    NinjaRMM Fields Updated:
        - dnsCacheStatus (Cleared/Failed)
        - dnsCacheLastClear (timestamp)
        - dnsCacheAttempts (number of attempts made)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Windows 10 / Server 2016 or higher
    
    Environment Variables (Optional):
        - numberOfTimesToClearCache: Override -Attempts parameter
        - delaybetweenAttempts: Override -DelaySeconds parameter
    
    Exit Codes:
        0 - Success (DNS cache cleared)
        1 - Failure (could not clear cache or script error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Number of times to clear DNS cache")]
    [ValidateRange(1,10)]
    [int]$Attempts = 3,
    
    [Parameter(Mandatory=$false, HelpMessage="Seconds to wait between attempts")]
    [ValidateRange(0,5)]
    [int]$DelaySeconds = 1
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Network-ClearDNSCache"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:CLIFallbackCount = 0
    $script:ClearAttempts = 0
    
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

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

    function Set-NinjaField {
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
        $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
        return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Clear-DNSCache {
        [CmdletBinding()]
        param()
        
        try {
            if (Get-Command Clear-DnsClientCache -ErrorAction SilentlyContinue) {
                Clear-DnsClientCache -ErrorAction Stop
                Write-Log "DNS cache cleared using Clear-DnsClientCache" -Level DEBUG
                return $true
            } else {
                Write-Log "Clear-DnsClientCache not available, using ipconfig" -Level DEBUG
                $Result = ipconfig.exe /flushdns 2>&1 | Out-String
                
                if ($Result -like "*Could not flush the DNS Resolver Cache*") {
                    throw "ipconfig /flushdns failed: $Result"
                }
                
                Write-Log "DNS cache cleared using ipconfig /flushdns" -Level DEBUG
                return $true
            }
        } catch {
            Write-Log "Failed to clear DNS cache: $_" -Level ERROR
            return $false
        }
    }

    function Get-CurrentDNSCache {
        [CmdletBinding()]
        param()
        
        try {
            if (Get-Command Get-DnsClientCache -ErrorAction SilentlyContinue) {
                $Cache = Get-DnsClientCache -ErrorAction Stop
                if ($Cache) {
                    return ($Cache | Select-Object Entry, TimeToLive, Data | Format-Table | Out-String)
                } else {
                    return "DNS cache is empty"
                }
            } else {
                $Cache = ipconfig.exe /displaydns 2>&1
                $Cache = $Cache -replace "Windows IP Configuration" | Where-Object { $_ } | Out-String
                
                if ($Cache -like "*Could not display the DNS Resolver Cache*" -or [string]::IsNullOrWhiteSpace($Cache)) {
                    return "DNS cache is empty"
                }
                
                return $Cache
            }
        } catch {
            Write-Log "Failed to retrieve DNS cache: $_" -Level WARN
            return "Unable to retrieve DNS cache"
        }
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:numberOfTimesToClearCache -and $env:numberOfTimesToClearCache -notlike "null") {
            $Attempts = [int]$env:numberOfTimesToClearCache
            Write-Log "Using attempts from environment: $Attempts" -Level INFO
        }
        
        if ($env:delayBetweenAttempts -and $env:delayBetweenAttempts -notlike "null") {
            $DelaySeconds = [int]$env:delayBetweenAttempts
            Write-Log "Using delay from environment: $DelaySeconds seconds" -Level INFO
        }
        
        Write-Log "Configuration: $Attempts attempt(s) with $DelaySeconds second delay" -Level INFO
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required to clear DNS cache"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        $SuccessCount = 0
        $FailureCount = 0
        
        for ($i = 1; $i -le $Attempts; $i++) {
            $script:ClearAttempts++
            Write-Log "DNS cache clearing attempt $i of $Attempts" -Level INFO
            
            if (Clear-DNSCache) {
                $SuccessCount++
                Write-Log "DNS cache cleared successfully (attempt $i)" -Level SUCCESS
            } else {
                $FailureCount++
                Write-Log "Failed to clear DNS cache (attempt $i)" -Level ERROR
            }
            
            if ($i -lt $Attempts -and $DelaySeconds -gt 0) {
                Write-Log "Waiting $DelaySeconds second(s) before next attempt" -Level DEBUG
                Start-Sleep -Seconds $DelaySeconds
            }
        }
        
        Write-Log "Clearing complete: $SuccessCount successful, $FailureCount failed" -Level INFO
        
        if ($FailureCount -gt 0) {
            throw "Failed to clear DNS cache on $FailureCount attempt(s)"
        }
        
        Write-Log "Retrieving current DNS cache contents" -Level INFO
        $CurrentCache = Get-CurrentDNSCache
        
        Write-Log "Current DNS Cache:" -Level INFO
        Write-Log $CurrentCache -Level INFO
        
        Set-NinjaField -FieldName "dnsCacheStatus" -Value "Cleared"
        Set-NinjaField -FieldName "dnsCacheLastClear" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Set-NinjaField -FieldName "dnsCacheAttempts" -Value $Attempts
        
        Write-Log "DNS cache clearing completed successfully" -Level SUCCESS
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "dnsCacheStatus" -Value "Failed"
        Set-NinjaField -FieldName "dnsCacheLastClear" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
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
        Write-Log "Clear Attempts: $script:ClearAttempts" -Level INFO
        
        if ($script:CLIFallbackCount -gt 0) {
            Write-Log "CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
        }
        
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
