<#
.SYNOPSIS
    Restart Print Spooler - Emergency Service Recovery for Stuck Print Jobs

.DESCRIPTION
    Provides automated emergency restart of the Windows Print Spooler service to resolve
    common printing issues including stuck print jobs, hung queues, driver failures, and
    spooler crashes. Implements safe restart procedure with proper service stop/start
    sequencing and status verification.
    
    The Print Spooler service (spoolsv.exe) manages all print jobs sent to local and network
    printers. Common failure scenarios include:
    - Corrupted print jobs blocking the queue
    - Printer driver crashes causing service hangs
    - Memory leaks in long-running spooler processes
    - Network printer communication failures
    - Spooler service dependencies issues
    
    Restart Procedure:
    1. Check current service status
    2. Forcefully stop service if running (clearing queue)
    3. Wait 3 seconds for clean shutdown
    4. Start service fresh
    5. Verify service is running
    6. Update telemetry fields
    
    Safe Recovery Approach:
    - Uses -Force flag to ensure clean stop even if jobs are pending
    - Implements wait periods for proper service state transitions
    - Validates service running status before reporting success
    - Logs all actions for troubleshooting

.NOTES
    Frequency: On-demand / Alert-triggered
    Runtime: 5-10 seconds
    Timeout: 30 seconds
    Context: SYSTEM
    
    Fields Updated:
    - svcSpoolerLastRestart (DateTime: timestamp of last restart)
    - svcSpoolerStatus (Text: Running, Failed, or error description)
    
    Dependencies:
    - Windows Print Spooler service (Spooler)
    - SYSTEM context required for service control
    
    Use Cases:
    - Automated remediation triggered by print queue alerts
    - Manual intervention via NinjaRMM
    - Scheduled maintenance restart
    - Emergency recovery during business hours
    
    Side Effects:
    - All pending print jobs will be cleared
    - Users may need to resubmit failed print jobs
    - Brief printing unavailability (5-10 seconds)
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Print Spooler Service Restart (v4.0)..."

    # Get current service status
    Write-Output "INFO: Checking Print Spooler service status..."
    $service = Get-Service -Name Spooler -ErrorAction Stop
    $initialStatus = $service.Status
    Write-Output "INFO: Initial service status: $initialStatus"

    # Stop service if running
    if ($service.Status -eq "Running") {
        Write-Output "INFO: Stopping Print Spooler service..."
        Stop-Service -Name Spooler -Force -ErrorAction Stop
        Write-Output "INFO: Service stopped (forced to clear queue)"
        
        Write-Output "INFO: Waiting 3 seconds for clean shutdown..."
        Start-Sleep -Seconds 3
    } else {
        Write-Output "INFO: Service was not running, proceeding to start"
    }

    # Start service
    Write-Output "INFO: Starting Print Spooler service..."
    Start-Service -Name Spooler -ErrorAction Stop
    
    Write-Output "INFO: Waiting 2 seconds for service initialization..."
    Start-Sleep -Seconds 2

    # Verify service is running
    Write-Output "INFO: Verifying service status..."
    $service = Get-Service -Name Spooler
    
    if ($service.Status -eq "Running") {
        Write-Output "SUCCESS: Print Spooler is running"
        Write-Output "INFO: Service restart completed successfully"
        
        # Update telemetry
        $restartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Ninja-Property-Set svcSpoolerLastRestart $restartTime
        Ninja-Property-Set svcSpoolerStatus "Running"
        
        Write-Output "TELEMETRY: Last restart timestamp: $restartTime"
        Write-Output "NOTE: Users may need to resubmit any print jobs that were in queue"
        
        exit 0
    } else {
        throw "Service failed to start (current status: $($service.Status))"
    }

} catch {
    Write-Output "ERROR: Print Spooler restart failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    
    # Update telemetry with failure status
    Ninja-Property-Set svcSpoolerStatus "Failed: $_"
    
    Write-Output "RECOMMENDATION: Manual investigation required"
    Write-Output "  1. Check Event Viewer: System log for Spooler service errors"
    Write-Output "  2. Verify printer drivers are not corrupted"
    Write-Output "  3. Check disk space in C:\Windows\System32\spool\PRINTERS"
    Write-Output "  4. Review spoolsv.exe crashes in Application log"
    
    exit 1
}
