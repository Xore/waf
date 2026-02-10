<#
.SYNOPSIS
    Restart Windows Update - Emergency Service Recovery for Update Failures

.DESCRIPTION
    Provides automated emergency restart of Windows Update and Background Intelligent Transfer
    Service (BITS) to resolve common update failures including stuck downloads, corrupted
    update cache, service hangs, and communication errors with Windows Update servers.
    
    Windows Update failures often require service restarts to clear transient states:
    - Download corruption or incomplete transfers
    - Update installation failures leaving service in error state
    - Windows Update Agent cache corruption
    - BITS transfer queue congestion
    - COM component registration issues
    - Network communication failures with Microsoft update servers
    
    Services Managed:
    
    Windows Update Service (wuauserv):
    - Primary service controlling Windows Update operations
    - Manages update detection, download, and installation
    - Must be running for automatic updates
    
    Background Intelligent Transfer Service (BITS):
    - Handles background file transfers for updates
    - Manages bandwidth throttling for downloads
    - Supports update download resumption
    - Critical for large update packages
    
    Restart Procedure:
    1. Stop Windows Update service (wuauserv)
    2. Stop BITS service (dependency)
    3. Wait 3 seconds for clean shutdown
    4. Start BITS service
    5. Start Windows Update service
    6. Verify service running status
    7. Update telemetry fields

.NOTES
    Frequency: On-demand / Alert-triggered
    Runtime: 5-10 seconds
    Timeout: 30 seconds
    Context: SYSTEM
    
    Services Restarted:
    - wuauserv (Windows Update)
    - BITS (Background Intelligent Transfer Service)
    
    Fields Updated:
    - svcWULastRestart (DateTime: timestamp of last restart)
    - svcWUStatus (Text: Running, Failed, or error description)
    
    Dependencies:
    - Windows Update service (wuauserv)
    - BITS service (optional but recommended)
    - SYSTEM context required for service control
    
    Use Cases:
    - Automated remediation for update error codes 0x80070422, 0x80240438
    - Manual intervention when updates stuck downloading
    - Recovery from Windows Update Agent failures
    - Clearing corrupted update cache
    - Scheduled maintenance restart
    
    Side Effects:
    - Active update downloads will be interrupted (can resume)
    - Current update check operations will be cancelled
    - BITS transfers for other applications briefly interrupted
    - Update installation in progress may fail (will retry)
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Windows Update Service Restart (v4.0)..."

    # Stop Windows Update service
    Write-Output "INFO: Stopping Windows Update service (wuauserv)..."
    Stop-Service -Name wuauserv -Force -ErrorAction Stop
    Write-Output "INFO: Windows Update service stopped"

    # Stop BITS service (update download dependency)
    Write-Output "INFO: Stopping BITS service..."
    try {
        Stop-Service -Name BITS -Force -ErrorAction Stop
        Write-Output "INFO: BITS service stopped"
    } catch {
        Write-Output "WARNING: BITS service stop failed (may not be running): $_"
    }

    # Wait for clean shutdown
    Write-Output "INFO: Waiting 3 seconds for clean shutdown..."
    Start-Sleep -Seconds 3

    # Start BITS service first
    Write-Output "INFO: Starting BITS service..."
    try {
        Start-Service -Name BITS -ErrorAction Stop
        Write-Output "INFO: BITS service started"
    } catch {
        Write-Output "WARNING: BITS service start failed: $_"
    }

    # Start Windows Update service
    Write-Output "INFO: Starting Windows Update service (wuauserv)..."
    Start-Service -Name wuauserv -ErrorAction Stop
    
    Write-Output "INFO: Waiting 2 seconds for service initialization..."
    Start-Sleep -Seconds 2

    # Verify service is running
    Write-Output "INFO: Verifying Windows Update service status..."
    $service = Get-Service -Name wuauserv
    
    if ($service.Status -eq "Running") {
        Write-Output "SUCCESS: Windows Update service is running"
        Write-Output "INFO: Service restart completed successfully"
        
        # Update telemetry
        $restartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Ninja-Property-Set svcWULastRestart $restartTime
        Ninja-Property-Set svcWUStatus "Running"
        
        Write-Output "TELEMETRY: Last restart timestamp: $restartTime"
        Write-Output "NOTE: Windows Update will resume operations automatically"
        Write-Output "NOTE: Any interrupted downloads will resume from last checkpoint"
        
        exit 0
    } else {
        throw "Windows Update service failed to start (current status: $($service.Status))"
    }

} catch {
    Write-Output "ERROR: Windows Update restart failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    
    # Update telemetry with failure status
    Ninja-Property-Set svcWUStatus "Failed: $_"
    
    Write-Output "RECOMMENDATION: Manual investigation required"
    Write-Output "  1. Check Event Viewer: System log for wuauserv service errors"
    Write-Output "  2. Review WindowsUpdate.log for error codes"
    Write-Output "  3. Run: sfc /scannow to repair system files"
    Write-Output "  4. Run: DISM /Online /Cleanup-Image /RestoreHealth"
    Write-Output "  5. Consider: Delete C:\Windows\SoftwareDistribution\Download\
    Write-Output "  6. Verify: Windows Update Agent is not corrupted"
    
    exit 1
}
