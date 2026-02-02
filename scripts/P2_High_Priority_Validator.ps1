<#
.SYNOPSIS
    P2 High Priority Device Patch Validation

.DESCRIPTION
    Performs balanced validation checks before allowing patch deployment
    on P2 (High priority) devices. Standards are high but less strict than P1.

.EXAMPLE
    .\P2_High_Priority_Validator.ps1

.NOTES
    Frequency: Before each patch deployment
    Runtime: 15 seconds
    Context: SYSTEM
    
    Fields Updated:
    - patchValidationStatus (Dropdown: Passed, Failed, Error, Pending)
    - patchValidationNotes (Text)
    - patchValidationDate (DateTime)
    
    Target: Devices with priority P2 or High business criticality
    
    Exit Code 0 = Validation passed
    Exit Code 1 = Validation failed
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

try {
    Write-Output "=========================================="
    Write-Output "P2 High Priority Device Patch Validation"
    Write-Output "=========================================="
    Write-Output "Device: $env:COMPUTERNAME"
    Write-Output "Priority: P2 (High)"
    Write-Output ""

    $validationPassed = $true
    $validationNotes = @()

    # Get device characteristics
    $healthScore = Ninja-Property-Get opsHealthScore
    $stabilityScore = Ninja-Property-Get statStabilityScore
    $businessCriticality = Ninja-Property-Get baseBusinessCriticality
    $crashCount = Ninja-Property-Get statCrashCount30d

    Write-Output "Device Metrics:"
    Write-Output "  Health Score: $healthScore"
    Write-Output "  Stability Score: $stabilityScore"
    Write-Output "  Business Criticality: $businessCriticality"
    Write-Output "  Recent Crashes: $crashCount"
    Write-Output ""

    # P2 VALIDATION RULES (BALANCED)
    Write-Output "P2 Validation Checks:"
    Write-Output ""

    # Rule 1: Health Score >= 70
    Write-Output "Check 1: Health Score >= 70"
    if ($healthScore -and $healthScore -ge 70) {
        Write-Output "  PASSED - Health Score: $healthScore"
    } elseif ($healthScore) {
        Write-Output "  FAILED - Health Score: $healthScore (minimum 70)"
        $validationPassed = $false
        $validationNotes += "Health score: $healthScore (min 70)"
    }
    Write-Output ""

    # Rule 2: Stability Score >= 70
    Write-Output "Check 2: Stability Score >= 70"
    if ($stabilityScore -and $stabilityScore -ge 70) {
        Write-Output "  PASSED - Stability Score: $stabilityScore"
    } elseif ($stabilityScore) {
        Write-Output "  FAILED - Stability Score: $stabilityScore (minimum 70)"
        $validationPassed = $false
        $validationNotes += "Stability score: $stabilityScore (min 70)"
    }
    Write-Output ""

    # Rule 3: Reasonable crash count (<= 5)
    Write-Output "Check 3: Crash History"
    if ($crashCount -ne $null -and $crashCount -le 5) {
        Write-Output "  PASSED - Crash count: $crashCount (maximum 5)"
    } elseif ($crashCount -ne $null) {
        Write-Output "  WARNING - Crash count: $crashCount (recommended max 5)"
        $validationNotes += "High crash count: $crashCount"
    }
    Write-Output ""

    # Rule 4: Backup within 72 hours
    Write-Output "Check 4: Backup Recency"
    $lastBackup = Ninja-Property-Get backupLastSuccess

    if ($lastBackup) {
        $backupAge = (Get-Date) - [datetime]$lastBackup
        $backupHours = [math]::Round($backupAge.TotalHours, 1)

        if ($backupHours -le 72) {
            Write-Output "  PASSED - Backup: $backupHours hours ago"
        } else {
            Write-Output "  WARNING - Backup: $backupHours hours ago (recommended: 72)"
            $validationNotes += "Backup age: $backupHours hours"
        }
    } else {
        Write-Output "  WARNING - No backup information"
        $validationNotes += "No backup data"
    }
    Write-Output ""

    # Rule 5: Disk space >= 10 GB
    Write-Output "Check 5: Disk Space"
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -ge 10) {
        Write-Output "  PASSED - Disk space: $freeSpaceGB GB"
    } else {
        Write-Output "  FAILED - Disk space: $freeSpaceGB GB (minimum 10 GB)"
        $validationPassed = $false
        $validationNotes += "Low disk space: $freeSpaceGB GB"
    }
    Write-Output ""

    # VALIDATION SUMMARY
    Write-Output "=========================================="
    if ($validationPassed) {
        Write-Output "STATUS: PASSED"
        Ninja-Property-Set patchValidationStatus "Passed"
    } else {
        Write-Output "STATUS: FAILED"
        Ninja-Property-Set patchValidationStatus "Failed"
    }

    $notesText = if ($validationNotes.Count -gt 0) { $validationNotes -join "; " } else { "All checks passed" }
    Ninja-Property-Set patchValidationNotes $notesText
    Ninja-Property-Set patchValidationDate (Get-Date)

    Write-Output "Notes: $notesText"
    Write-Output "=========================================="

    if (-not $validationPassed) { exit 1 }
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set patchValidationStatus "Error"
    exit 1
}
