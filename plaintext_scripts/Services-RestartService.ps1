#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Restarts one or more Windows services with retry logic and timeout handling.

.DESCRIPTION
    Restarts specified Windows services with configurable retry attempts and wait times.
    Supports multiple services, validates service existence, and monitors restart status.
    
    The script performs the following:
    - Validates administrator privileges
    - Accepts service names or display names
    - Restarts services with configurable timeouts
    - Retries failed starts with configurable attempts
    - Waits between restart attempts
    - Reports detailed service status
    - Updates NinjaRMM custom fields with results
    
    This script runs unattended without user interaction.

.PARAMETER Name
    Service name(s) to restart. Accepts either ServiceName or DisplayName.
    Can be a single service or comma-separated list.
    Examples: "wuauserv", "Windows Update", "Spooler,BITS"

.PARAMETER Attempts
    Number of restart attempts per service before giving up.
    Default: 3
    Range: 1-10

.PARAMETER WaitTimeInSecs
    Duration in seconds to wait for service to start between each attempt.
    Default: 15
    Range: 5-300

.EXAMPLE
    .\Services-RestartService.ps1 -Name "wuauserv"
    
    Restarts Windows Update service with default settings (3 attempts, 15 second wait).

.EXAMPLE
    .\Services-RestartService.ps1 -Name "Spooler,BITS" -Attempts 5 -WaitTimeInSecs 30
    
    Restarts Print Spooler and BITS services with 5 attempts and 30 second waits.

.EXAMPLE
    .\Services-RestartService.ps1 -Name "Windows Update"
    
    Restarts service using display name instead of service name.

.NOTES
    File Name      : Services-RestartService.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards with Set-StrictMode and garbage collection
    - 2.0: Added comprehensive restart logic
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or scheduled
    Typical Duration: 5-45 seconds (depends on service count and retry attempts)
    Timeout Setting: 120 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no system restart required)
    
    Fields Updated:
        - serviceRestartStatus (Success/Failed)
        - serviceRestartDate (timestamp)
        - serviceRestartCount (number of services restarted)
        - serviceRestartList (service names)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Services must exist on system
    
    Environment Variables (Optional):
        - Name: Alternative to -Name parameter
        - Attempts: Alternative to -Attempts parameter
        - WaitTimeInSecs: Alternative to -WaitTimeInSecs parameter

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Service name(s) to restart")]
    [ValidateNotNullOrEmpty()]
    [string[]]$Name,
    
    [Parameter(Mandatory=$false, HelpMessage="Number of restart attempts")]
    [ValidateRange(1, 10)]
    [int]$Attempts = 3,
    
    [Parameter(Mandatory=$false, HelpMessage="Wait time in seconds between attempts")]
    [ValidateRange(5, 300)]
    [int]$WaitTimeInSecs = 15
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Services-RestartService"
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Stop'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:CLIFallbackCount = 0

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
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Write-Output $LogMessage
        
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:Name -and $env:Name -notlike "null") {
            $Name = $env:Name
            Write-Log "Using service name from environment: $Name" -Level INFO
        }
        
        if ($env:Attempts -and $env:Attempts -notlike "null") {
            $Attempts = [int]$env:Attempts
            Write-Log "Using attempts from environment: $Attempts" -Level INFO
        }
        
        if ($env:WaitTimeInSecs -and $env:WaitTimeInSecs -notlike "null") {
            $WaitTimeInSecs = [int]$env:WaitTimeInSecs
            Write-Log "Using wait time from environment: $WaitTimeInSecs" -Level INFO
        }
        
        if (-not $Name) {
            throw "Name parameter is required. Specify one or more service names."
        }
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        if ($Name -like "*,*") {
            $Name = $Name -split ',' | ForEach-Object { $_.Trim() }
            Write-Log "Processing multiple services: $($Name.Count)" -Level INFO
        }
        
        Write-Log "Configuration: Attempts=$Attempts, WaitTime=$WaitTimeInSecs seconds" -Level INFO
        
        Write-Log "Finding services matching criteria" -Level DEBUG
        $Services = Get-Service -ErrorAction Stop | 
            Where-Object { $_.Name -in $Name -or $_.DisplayName -in $Name }
        
        if ($Services.Count -eq 0) {
            throw "No services found matching: $($Name -join ', ')"
        }
        
        Write-Log "Found $($Services.Count) service(s) to restart" -Level INFO
        
        $FailedServices = [System.Collections.Generic.List[string]]::new()
        $SuccessServices = [System.Collections.Generic.List[string]]::new()
        
        foreach ($Service in $Services) {
            Write-Log "Restarting service: $($Service.Name) ($($Service.DisplayName))" -Level INFO
            Write-Log "  Current status: $($Service.Status)" -Level DEBUG
            
            $AttemptCounter = $Attempts
            $ServiceRestarted = $false
            
            try {
                Restart-Service -Name $Service.Name -Force -ErrorAction Stop
                Write-Log "  Restart command issued" -Level DEBUG
                
                while ($AttemptCounter -gt 0) {
                    Start-Sleep -Seconds $WaitTimeInSecs
                    
                    $CurrentService = Get-Service -Name $Service.Name -ErrorAction Stop
                    Write-Log "  Attempt $($Attempts - $AttemptCounter + 1)/$Attempts - Status: $($CurrentService.Status)" -Level DEBUG
                    
                    if ($CurrentService.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
                        Write-Log "  Service $($Service.Name) is now running" -Level SUCCESS
                        $ServiceRestarted = $true
                        $SuccessServices.Add($Service.Name)
                        break
                    }
                    
                    if ($CurrentService.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
                        Write-Log "  Service not running, attempting to start" -Level DEBUG
                        Start-Service -Name $Service.Name -ErrorAction SilentlyContinue
                    }
                    
                    $AttemptCounter--
                }
                
                if (-not $ServiceRestarted) {
                    throw "Service failed to reach Running state after $Attempts attempts"
                }
                
            } catch {
                Write-Log "  Failed to restart $($Service.Name): $($_.Exception.Message)" -Level ERROR
                $FailedServices.Add($Service.Name)
            }
        }
        
        Write-Log "Service Restart Summary:" -Level INFO
        Write-Log "  Total services: $($Services.Count)" -Level INFO
        Write-Log "  Successfully restarted: $($SuccessServices.Count)" -Level INFO
        Write-Log "  Failed to restart: $($FailedServices.Count)" -Level INFO
        
        if ($SuccessServices.Count -gt 0) {
            Write-Log "  Success list: $($SuccessServices -join ', ')" -Level SUCCESS
        }
        
        if ($FailedServices.Count -gt 0) {
            Write-Log "  Failed list: $($FailedServices -join ', ')" -Level ERROR
        }
        
        if ($FailedServices.Count -eq 0) {
            Set-NinjaField -FieldName "serviceRestartStatus" -Value "Success"
            Write-Log "All services restarted successfully" -Level SUCCESS
        } else {
            Set-NinjaField -FieldName "serviceRestartStatus" -Value "Failed"
            Write-Log "Some services failed to restart" -Level ERROR
        }
        
        Set-NinjaField -FieldName "serviceRestartDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Set-NinjaField -FieldName "serviceRestartCount" -Value $SuccessServices.Count
        Set-NinjaField -FieldName "serviceRestartList" -Value ($SuccessServices -join ", ")
        
        if ($FailedServices.Count -gt 0) {
            $ExitCode = 1
        } else {
            $ExitCode = 0
        }
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "serviceRestartStatus" -Value "Failed"
        Set-NinjaField -FieldName "serviceRestartDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        $ExitCode = 1
    }
}

end {
    try {
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
    finally {
        [System.GC]::Collect()
        exit $ExitCode
    }
}
