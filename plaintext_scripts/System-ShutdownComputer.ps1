#Requires -Version 5.1

<#
.SYNOPSIS
    Schedules a computer shutdown with configurable time delay.

.DESCRIPTION
    This script initiates a graceful system shutdown with a configurable delay period. It uses 
    the Windows shutdown.exe utility to schedule the shutdown, allowing time for users to save 
    work and close applications. The script supports both legacy and modern shutdown methods 
    based on the Windows version.
    
    Graceful shutdown scheduling is essential for remote system management, scheduled maintenance, 
    and automated deployment scenarios. The timeout allows administrators to give users advance 
    warning before the system shuts down.

.PARAMETER Timeout
    Time delay in seconds before shutdown executes. Valid range: 10 to 315360000 seconds (10 years).
    Default: 60 seconds

.EXAMPLE
    -Timeout 300

    Shutdown scheduled for 02/10/2026 00:51:00
    [Info] System will shut down in 5 minutes

.EXAMPLE
    No Parameters (uses default 60 second timeout)
    
    Shutdown scheduled for 02/10/2026 00:47:00
    [Info] System will shut down in 60 seconds

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2012 R2
    Release notes: V3.0.0 - Upgraded to script-scoped exit code handling
    User interaction: None - executes unattended shutdown
    Restart behavior: System will shut down after timeout period
    Typical duration: < 1 second to schedule, then waits for timeout
    
.COMPONENT
    shutdown.exe - Windows shutdown utility
    
.LINK
    https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shutdown

.FUNCTIONALITY
    - Schedules graceful system shutdown with configurable delay
    - Uses /sg (shutdown with GUI) on Windows 10+ for better user experience
    - Forces application closure (/f flag) to prevent hang situations
    - Validates timeout range (10 seconds to 10 years)
    - Provides shutdown confirmation with timestamp
    - Captures and reports any shutdown scheduling errors
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateRange(10, 315360000)]
    [long]$Timeout = 60
)

begin {
    if ($env:timeDelayInSeconds -and $env:timeDelayInSeconds -notlike "null") { 
        $Timeout = $env:timeDelayInSeconds 
    }

    if (-not $Timeout) {
        Write-Host "[Error] Timeout in seconds is required"
        exit 1
    }

    if ($Timeout -lt 10 -or $Timeout -gt 315360000) {
        Write-Host "[Error] Invalid timeout '$Timeout'. Must be between 10 and 315360000 seconds (10 years)"
        exit 1
    }
    
    $script:ExitCode = 0
}

process {
    try {
        $ShutdownOutputLog = "$env:TEMP\shutdown-output-$(Get-Random).log"
        $ShutdownErrorLog = "$env:TEMP\shutdown-error-$(Get-Random).log"

        if ([System.Environment]::OSVersion.Version.Major -ge 10) {
            $ShutdownArguments = "/sg", "/t", $Timeout, "/f"
            Write-Host "[Info] Using modern shutdown method (/sg) for Windows 10+"
        }
        else {
            $ShutdownArguments = "/s", "/t", $Timeout, "/f"
            Write-Host "[Info] Using legacy shutdown method (/s)"
        }

        Write-Host "[Info] Scheduling shutdown with $Timeout second delay..."
        $ShutdownProcess = Start-Process -FilePath "$env:SystemRoot\System32\shutdown.exe" -ArgumentList $ShutdownArguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput $ShutdownOutputLog -RedirectStandardError $ShutdownErrorLog

        if (Test-Path -Path $ShutdownOutputLog -ErrorAction SilentlyContinue) {
            Get-Content -Path $ShutdownOutputLog -ErrorAction SilentlyContinue | ForEach-Object { 
                Write-Host "[Info] $_" 
            }
            Remove-Item -Path $ShutdownOutputLog -Force -Confirm:$false -ErrorAction SilentlyContinue
        }

        if (Test-Path -Path $ShutdownErrorLog -ErrorAction SilentlyContinue) {
            Get-Content -Path $ShutdownErrorLog -ErrorAction SilentlyContinue | ForEach-Object { 
                Write-Host "[Error] $_"
                $script:ExitCode = 1
            }
            Remove-Item -Path $ShutdownErrorLog -Force -Confirm:$false -ErrorAction SilentlyContinue
        }

        if ($ShutdownProcess.ExitCode -eq 0) {
            $ShutdownTime = (Get-Date).AddSeconds($Timeout)
            Write-Host "[Info] Shutdown scheduled successfully for $($ShutdownTime.ToString('MM/dd/yyyy HH:mm:ss'))"
            Write-Host "[Info] System will shut down in $Timeout seconds"
            $script:ExitCode = 0
        }
        else {
            Write-Host "[Error] Failed to schedule shutdown (Exit code: $($ShutdownProcess.ExitCode))"
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Host "[Error] Shutdown scheduling failed: $_"
        $script:ExitCode = 1
    }

    exit $ExitCode
}

end {
}
