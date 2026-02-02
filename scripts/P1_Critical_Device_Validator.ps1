<#
.SYNOPSIS
    P1 Critical Device Patch Validation

.DESCRIPTION
    Performs comprehensive validation checks before allowing patch deployment
    on P1 (Critical priority) devices. Requires highest standards for health,
    stability, and recent backups.

.EXAMPLE
    .\P1_Critical_Device_Validator.ps1

.NOTES
    Frequency: Before each patch deployment
    Runtime: 15-20 seconds
    Context: SYSTEM
    
    Fields Updated:
    - patchValidationStatus (Dropdown: Passed, Failed, Error, Pending)
    - patchValidationNotes (Text)
    - patchValidationDate (DateTime)
    
    Target: Devices with priority P1 or Critical business criticality
    
    Exit Code 0 = Validation passed
    Exit Code 1 = Validation failed
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

try {
    Write-Output "=========================================="
    Write-Output "P1 Critical Device Patch Validation"
    Write-Output "=========================================="
    Write-Output "Device: $env:COMPUTERNAME"
    Write-Output "Priority: P1 (Critical)"
    Write-Output ""

    $validationPassed = $true
    $validationNotes = @()
    $validationDetails = @()

    # GET DEVICE CHARACTERISTICS
    Write-Output "Retrieving device health metrics..."

    $healthScore = Ninja-Property-Get opsHealthScore
    $stabilityScore = Ninja-Property-Get statStabilityScore
    $performanceScore = Ninja-Property-Get opsPerformanceScore
    $businessCriticality = Ninja-Property-Get baseBusinessCriticality
    $riskLevel = Ninja-Property-Get riskExposureLevel
    $crashCount = Ninja-Property-Get statCrashCount30d

    Write-Output "  Health Score: $healthScore"
    Write-Output "  Stability Score: $stabilityScore"
    Write-Output "  Performance Score: $performanceScore"
    Write-Output "  Business Criticality: $businessCriticality"
    Write-Output "  Risk Level: $riskLevel"
    Write-Output "  Recent Crashes (30d): $crashCount"
    Write-Output ""

    # P1 VALIDATION RULES (STRICTEST)
    Write-Output "P1 Validation Checks (Critical Priority):"
    Write-Output ""

    # Rule 1: Health Score >= 80
    Write-Output "Check 1: Health Score Validation"
    if ($healthScore -and $healthScore -ge 80) {
        Write-Output "  PASSED - Health Score: $healthScore (minimum 80)"
        $validationDetails += "Health: $healthScore/100"
    } elseif ($healthScore) {
        Write-Output "  FAILED - Health Score: $healthScore (minimum 80 required)"
        $validationPassed = $false
        $validationNotes += "Health score too low: $healthScore (min 80)"
    } else {
        Write-Output "  WARNING - Health Score not available"
        $validationNotes += "Health score unavailable"
    }
    Write-Output ""

    # Rule 2: Stability Score >= 80
    Write-Output "Check 2: Stability Score Validation"
    if ($stabilityScore -and $stabilityScore -ge 80) {
        Write-Output "  PASSED - Stability Score: $stabilityScore (minimum 80)"
        $validationDetails += "Stability: $stabilityScore/100"
    } elseif ($stabilityScore) {
        Write-Output "  FAILED - Stability Score: $stabilityScore (minimum 80 required)"
        $validationPassed = $false
        $validationNotes += "Stability score too low: $stabilityScore (min 80)"
    } else {
        Write-Output "  WARNING - Stability Score not available"
    }
    Write-Output ""

    # Rule 3: No recent crashes (or very few)
    Write-Output "Check 3: Crash History Validation"
    if ($crashCount -ne $null) {
        if ($crashCount -eq 0) {
            Write-Output "  PASSED - No crashes in last 30 days"
            $validationDetails += "Crashes: 0"
        } elseif ($crashCount -le 2) {
            Write-Output "  WARNING - $crashCount crashes in last 30 days (acceptable)"
            $validationDetails += "Crashes: $crashCount"
        } else {
            Write-Output "  FAILED - $crashCount crashes in last 30 days (maximum 2)"
            $validationPassed = $false
            $validationNotes += "Too many crashes: $crashCount (max 2)"
        }
    }
    Write-Output ""

    # Rule 4: Business Criticality must be Critical
    Write-Output "Check 4: Business Criticality Verification"
    if ($businessCriticality -eq 'Critical') {
        Write-Output "  PASSED - Correctly marked as Critical"
        $validationDetails += "Criticality: Critical"
    } else {
        Write-Output "  WARNING - P1 device not marked as Critical business criticality"
        Write-Output "  Current: $businessCriticality"
        $validationNotes += "Criticality mismatch: $businessCriticality"
    }
    Write-Output ""

    # Rule 5: Recent backup required (within 24 hours)
    Write-Output "Check 5: Backup Recency Validation"
    $lastBackup = Ninja-Property-Get backupLastSuccess

    if ($lastBackup) {
        $backupAge = (Get-Date) - [datetime]$lastBackup
        $backupHours = [math]::Round($backupAge.TotalHours, 1)

        if ($backupHours -le 24) {
            Write-Output "  PASSED - Recent backup: $backupHours hours ago"
            $validationDetails += "Backup: $backupHours hrs ago"
        } elseif ($backupHours -le 48) {
            Write-Output "  WARNING - Backup is $backupHours hours old (recommended: 24 hours)"
            $validationDetails += "Backup: $backupHours hrs ago"
        } else {
            Write-Output "  FAILED - Backup is $backupHours hours old (maximum 24 hours for P1)"
            $validationPassed = $false
            $validationNotes += "Backup too old: $backupHours hours (max 24)"
        }
    } else {
        Write-Output "  FAILED - No backup information available"
        $validationPassed = $false
        $validationNotes += "No backup verification"
    }
    Write-Output ""

    # Rule 6: Disk space >= 15 GB (higher than standard)
    Write-Output "Check 6: Disk Space Validation"
    $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

    if ($freeSpaceGB -ge 15) {
        Write-Output "  PASSED - Disk space: $freeSpaceGB GB (minimum 15 GB)"
        $validationDetails += "Disk: $freeSpaceGB GB free"
    } elseif ($freeSpaceGB -ge 10) {
        Write-Output "  WARNING - Disk space: $freeSpaceGB GB (recommended 15 GB for P1)"
        $validationDetails += "Disk: $freeSpaceGB GB free"
    } else {
        Write-Output "  FAILED - Disk space: $freeSpaceGB GB (minimum 10 GB)"
        $validationPassed = $false
        $validationNotes += "Insufficient disk space: $freeSpaceGB GB (min 10)"
    }
    Write-Output ""

    # Rule 7: Change approval required
    Write-Output "Check 7: Change Management"
    Write-Output "  INFO - P1 Critical systems require change approval"
    Write-Output "  Ensure change ticket is created before deployment"
    $validationNotes += "Change approval required"
    Write-Output ""

    # Rule 8: Maintenance window recommended
    Write-Output "Check 8: Maintenance Window Recommendation"
    $serverRole = Ninja-Property-Get srvRole

    if ($serverRole) {
        Write-Output "  INFO - Server role detected: $serverRole"
        Write-Output "  RECOMMENDATION: Deploy during maintenance window"
        $validationNotes += "Maintenance window recommended"
    }
    Write-Output ""

    # VALIDATION SUMMARY
    Write-Output "=========================================="
    Write-Output "Validation Summary"
    Write-Output "=========================================="

    if ($validationPassed) {
        Write-Output "STATUS: PASSED"
        Write-Output "P1 Critical device meets all validation requirements"
        Ninja-Property-Set patchValidationStatus "Passed"
    } else {
        Write-Output "STATUS: FAILED"
        Write-Output "P1 Critical device does not meet validation requirements"
        Ninja-Property-Set patchValidationStatus "Failed"
    }

    Write-Output ""
    Write-Output "Validation Notes:"
    foreach ($note in $validationNotes) {
        Write-Output "  - $note"
    }

    $notesText = $validationNotes -join "; "
    if (-not $notesText) {
        $notesText = "All checks passed"
    }

    Ninja-Property-Set patchValidationNotes $notesText
    Ninja-Property-Set patchValidationDate (Get-Date)

    Write-Output ""
    Write-Output "=========================================="

    if (-not $validationPassed) {
        exit 1
    }

    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set patchValidationStatus "Error"
    Ninja-Property-Set patchValidationNotes "Validation script error: $($_.Exception.Message)"
    exit 1
}
