# Script 50: Emergency Disk Cleanup

**Purpose:** Free 2-5GB of disk space during critical low-disk situations  
**Frequency:** On-demand / Alert-triggered  
**Runtime:** 60-90 seconds  
**Fields Updated:** `cleanupSpaceFreedGB`, `cleanupLastRunDate`, `cleanupLastResult`

---

## PowerShell Code

```powershell
# Emergency Disk Cleanup - Target: Free 2-5GB
# Compatible with NinjaRMM custom fields

param()

try {
    Write-Output "Starting Emergency Disk Cleanup..."

    $freedSpaceGB = 0
    $logDetails = @()

    # 1. Clear Windows Temp Files
    Write-Output "Cleaning Windows Temp..."
    $tempPath = "$env:SystemRoot\Temp"
    if (Test-Path $tempPath) {
        $beforeSize = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1GB
        Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        $afterSize = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1GB
        $cleaned = [math]::Round($beforeSize - $afterSize, 2)
        $freedSpaceGB += $cleaned
        $logDetails += "Windows Temp: $cleaned GB"
    }

    # 2. Clear User Temp Files
    Write-Output "Cleaning User Temp..."
    $userTemp = "$env:TEMP"
    if (Test-Path $userTemp) {
        $beforeSize = (Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1GB
        Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        $afterSize = (Get-ChildItem $userTemp -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1GB
        $cleaned = [math]::Round($beforeSize - $afterSize, 2)
        $freedSpaceGB += $cleaned
        $logDetails += "User Temp: $cleaned GB"
    }

    # 3. Clear Windows Update Cache
    Write-Output "Cleaning Windows Update Cache..."
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    $wuCache = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $wuCache) {
        $beforeSize = (Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1GB
        Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        $afterSize = (Get-ChildItem $wuCache -Recurse -Force -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1GB
        $cleaned = [math]::Round($beforeSize - $afterSize, 2)
        $freedSpaceGB += $cleaned
        $logDetails += "WU Cache: $cleaned GB"
    }
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue

    # 4. Empty Recycle Bin
    Write-Output "Emptying Recycle Bin..."
    $recycleBin = Get-CimInstance -ClassName Win32_RecycleBin -ErrorAction SilentlyContinue
    if ($recycleBin) {
        $rbSize = ($recycleBin | Measure-Object -Property Size -Sum).Sum / 1GB
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        $freedSpaceGB += [math]::Round($rbSize, 2)
        $logDetails += "Recycle Bin: $([math]::Round($rbSize, 2)) GB"
    }

    # 5. Clear Browser Caches
    Write-Output "Cleaning Browser Caches..."
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"

    foreach ($path in @($chromePath, $edgePath)) {
        if (Test-Path $path) {
            $beforeSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB
            $cleaned = [math]::Round($beforeSize - $afterSize, 2)
            $freedSpaceGB += $cleaned
        }
    }
    $logDetails += "Browser Caches: cleaned"

    # 6. Run Windows Disk Cleanup Tool
    Write-Output "Running Disk Cleanup utility..."
    Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow -ErrorAction SilentlyContinue

    $freedSpaceGB = [math]::Round($freedSpaceGB, 2)

    # Update NinjaRMM custom fields
    Ninja-Property-Set cleanupLastRunDate (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Ninja-Property-Set cleanupSpaceFreedGB $freedSpaceGB
    Ninja-Property-Set cleanupLastResult "Success"

    Write-Output "SUCCESS: Freed $freedSpaceGB GB"
    Write-Output "Details: $($logDetails -join ' | ')"

    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set cleanupLastResult "Failed: $($_.Exception.Message)"
    exit 1
}
```

---

## Expected Results

- **Target:** 2-5GB freed
- **Actual:** Varies based on system state
- **Actions:**
  - Windows Temp cleaned
  - User Temp cleaned
  - Windows Update cache cleared
  - Recycle Bin emptied
  - Browser caches cleared
  - Disk Cleanup utility executed

---

## Custom Fields Required

| Field Name | Type | Purpose |
|-----------|------|---------|
| `cleanupLastRunDate` | DateTime | Last execution timestamp |
| `cleanupSpaceFreedGB` | Integer | Amount of space freed in GB |
| `cleanupLastResult` | Text | Success or failure message |

---

## Deployment

1. Upload to NinjaOne Automation Library
2. Create the required custom fields
3. Assign to devices via policy or run on-demand
4. Trigger via alert condition: Disk Free Space < 10GB

---

**File:** `50_Emergency_Disk_Cleanup.md`  
**Created:** February 1, 2026  
**Framework Version:** 1.0  
**Author:** NinjaRMM Custom Field Framework
