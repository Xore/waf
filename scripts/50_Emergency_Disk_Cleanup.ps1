<#
.SYNOPSIS
    Emergency Disk Cleanup - Critical Disk Space Recovery for Low Disk Situations

.DESCRIPTION
    Performs aggressive disk space recovery during critical low-disk situations by cleaning
    temporary files, Windows Update cache, recycle bin, browser caches, and running Windows
    Disk Cleanup utility. Typically recovers 2-5 GB of disk space to restore system functionality
    and prevent service failures.
    
    Designed for emergency intervention when disk space falls below critical thresholds and
    threatens system stability. Implements safe cleanup procedures that remove only temporary
    and cached data without risking user files or system integrity.
    
    Cleanup Targets and Expected Recovery:
    
    1. Windows Temp Files:
    - Location: C:\Windows\Temp
    - Typical recovery: 200-800 MB
    - Contains: Installation logs, update temp files, system temp data
    - Safety: Safe to delete (system temp folder)
    
    2. User Temp Files:
    - Location: %TEMP% (typically C:\Users\[username]\AppData\Local\Temp)
    - Typical recovery: 100-500 MB
    - Contains: Application temp files, download cache
    - Safety: Safe to delete (user temp folder)
    
    3. Windows Update Cache:
    - Location: C:\Windows\SoftwareDistribution\Download
    - Typical recovery: 1-3 GB
    - Contains: Downloaded update packages, installation files
    - Safety: Safe to delete (updates can be re-downloaded)
    - Note: Windows Update service stopped during cleanup
    
    4. Recycle Bin:
    - Location: All drives $Recycle.Bin
    - Typical recovery: Variable (0.5-2 GB)
    - Contains: Deleted files pending permanent removal
    - Safety: Permanent deletion (cannot be recovered)
    
    5. Browser Caches:
    - Locations: Chrome and Edge user data caches
    - Typical recovery: 200-1000 MB
    - Contains: Cached web pages, images, scripts
    - Safety: Safe to delete (browsers rebuild cache)
    
    6. Windows Disk Cleanup Utility:
    - System: cleanmgr.exe with sage settings
    - Additional recovery: 500 MB - 2 GB
    - Contains: Windows component cleanup, system files
    - Safety: Microsoft-verified safe cleanup
    
    Total Expected Recovery: 2-5 GB

.NOTES
    Frequency: On-demand / Alert-triggered
    Runtime: 60-90 seconds
    Timeout: 180 seconds
    Context: SYSTEM
    
    Fields Updated:
    - cleanupSpaceFreedGB (Decimal: gigabytes of space recovered)
    - cleanupLastRunDate (DateTime: timestamp in yyyy-MM-dd HH:mm:ss format)
    - cleanupLastResult (Text: Success or error description)
    
    Dependencies:
    - Windows Update service (wuauserv) - stopped/started
    - cleanmgr.exe (Windows Disk Cleanup utility)
    - SYSTEM context required for Windows folder access
    
    Use Cases:
    - Emergency response to disk full alerts
    - Pre-patch cleanup to ensure space for updates
    - Manual intervention when automated cleanup insufficient
    - Capacity management before critical operations
    
    Side Effects:
    - Windows Update service briefly stopped (restarted after cleanup)
    - Recycle bin permanently emptied (files cannot be recovered)
    - Browser cache cleared (first page load may be slower)
    - Active file handles may prevent some file deletions
    
    Safety Considerations:
    - Only removes temporary and cached data
    - No user documents or application data deleted
    - All cleanup targets are safe to remove
    - Failed deletions are silently skipped (no errors)
    - Before/after measurements prevent double-counting
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Emergency Disk Cleanup (v4.0)..."
    Write-Output "NOTICE: This will permanently delete temporary files and empty recycle bin"

    $freedSpaceGB = 0
    $logDetails = @()

    # Get initial disk space
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $initialFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    Write-Output "INFO: Initial free space: $initialFreeGB GB"

    # 1. Clear Windows Temp Files
    Write-Output "INFO: Cleaning Windows Temp directory..."
    $tempPath = "$env:SystemRoot\Temp"
    if (Test-Path $tempPath) {
        try {
            $beforeSize = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            
            Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            
            $afterSize = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            
            $cleaned = [math]::Round($beforeSize - $afterSize, 2)
            $freedSpaceGB += $cleaned
            $logDetails += "Windows Temp: $cleaned GB"
            Write-Output "  Cleaned: $cleaned GB from Windows Temp"
        } catch {
            Write-Output "  WARNING: Some Windows Temp files could not be deleted (in use)"
        }
    }

    # 2. Clear User Temp Files
    Write-Output "INFO: Cleaning User Temp directory..."
    $userTemp = "$env:TEMP"
    if (Test-Path $userTemp) {
        try {
            $beforeSize = (Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            
            Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            
            $afterSize = (Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            
            $cleaned = [math]::Round($beforeSize - $afterSize, 2)
            $freedSpaceGB += $cleaned
            $logDetails += "User Temp: $cleaned GB"
            Write-Output "  Cleaned: $cleaned GB from User Temp"
        } catch {
            Write-Output "  WARNING: Some User Temp files could not be deleted (in use)"
        }
    }

    # 3. Clear Windows Update Cache
    Write-Output "INFO: Cleaning Windows Update cache..."
    Write-Output "  Stopping Windows Update service..."
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    $wuCache = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuCache) {
        try {
            $beforeSize = (Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            
            Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            
            $afterSize = (Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            
            $cleaned = [math]::Round($beforeSize - $afterSize, 2)
            $freedSpaceGB += $cleaned
            $logDetails += "WU Cache: $cleaned GB"
            Write-Output "  Cleaned: $cleaned GB from Windows Update cache"
        } catch {
            Write-Output "  WARNING: Windows Update cache cleanup failed"
        }
    }
    
    Write-Output "  Restarting Windows Update service..."
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue

    # 4. Empty Recycle Bin
    Write-Output "INFO: Emptying Recycle Bin..."
    try {
        $recycleBin = Get-CimInstance -ClassName Win32_RecycleBin -ErrorAction SilentlyContinue
        if ($recycleBin) {
            $rbSize = ($recycleBin | Measure-Object -Property Size -Sum).Sum / 1GB
            
            if ($rbSize -gt 0) {
                Write-Output "  Recycle Bin contains: $([math]::Round($rbSize, 2)) GB"
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                $freedSpaceGB += [math]::Round($rbSize, 2)
                $logDetails += "Recycle Bin: $([math]::Round($rbSize, 2)) GB"
                Write-Output "  Cleaned: $([math]::Round($rbSize, 2)) GB from Recycle Bin"
            } else {
                Write-Output "  Recycle Bin is already empty"
            }
        }
    } catch {
        Write-Output "  WARNING: Recycle Bin cleanup failed"
    }

    # 5. Clear Browser Caches
    Write-Output "INFO: Cleaning browser caches..."
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    $browserCleaned = 0

    foreach ($path in @($chromePath, $edgePath)) {
        if (Test-Path $path) {
            try {
                $beforeSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum / 1GB
                
                Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                
                $afterSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum / 1GB
                
                $cleaned = [math]::Round($beforeSize - $afterSize, 2)
                $browserCleaned += $cleaned
            } catch {
                Write-Output "  WARNING: Some browser cache files could not be deleted (browser running)"
            }
        }
    }
    
    if ($browserCleaned -gt 0) {
        $freedSpaceGB += $browserCleaned
        $logDetails += "Browser Caches: $([math]::Round($browserCleaned, 2)) GB"
        Write-Output "  Cleaned: $([math]::Round($browserCleaned, 2)) GB from browser caches"
    } else {
        Write-Output "  No browser cache data found or could not be cleaned"
    }

    # 6. Run Windows Disk Cleanup Tool
    Write-Output "INFO: Running Windows Disk Cleanup utility..."
    try {
        Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow -ErrorAction Stop
        Write-Output "  Windows Disk Cleanup completed"
    } catch {
        Write-Output "  WARNING: Windows Disk Cleanup utility failed to run"
    }

    # Calculate final space freed
    $freedSpaceGB = [math]::Round($freedSpaceGB, 2)
    
    # Get final disk space
    $disk.PSBase.Get()
    $finalFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $actualRecoveredGB = [math]::Round($finalFreeGB - $initialFreeGB, 2)

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating cleanup telemetry..."
    Ninja-Property-Set cleanupLastRunDate (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Ninja-Property-Set cleanupSpaceFreedGB $freedSpaceGB
    Ninja-Property-Set cleanupLastResult "Success"

    Write-Output "SUCCESS: Emergency disk cleanup complete"
    Write-Output "SPACE RECOVERY SUMMARY:"
    Write-Output "  - Measured cleanup: $freedSpaceGB GB"
    Write-Output "  - Actual disk recovery: $actualRecoveredGB GB"
    Write-Output "  - Initial free space: $initialFreeGB GB"
    Write-Output "  - Final free space: $finalFreeGB GB"
    Write-Output "CLEANUP DETAILS:"
    $logDetails | ForEach-Object { Write-Output "  - $_" }

    exit 0

} catch {
    Write-Output "ERROR: Emergency Disk Cleanup failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set cleanupLastResult "Failed: $_"
    exit 1
}
