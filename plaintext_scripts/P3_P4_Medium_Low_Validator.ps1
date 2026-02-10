<#
.SYNOPSIS
    P3/P4 Medium and Low Priority Device Patch Validation

.DESCRIPTION
    Performs minimal validation checks before allowing patch deployment
    on P3 (Medium) and P4 (Low) priority devices. Standards are relaxed
    to enable automated patching.

.PARAMETER DevicePriority
    P3 or P4 priority level

.EXAMPLE
    .\P3_P4_Medium_Low_Validator.ps1 -DevicePriority P3

.NOTES
    Frequency: Before each patch deployment
    Runtime: 10 seconds
    Context: SYSTEM
    
    Fields Updated:
    - patchValidationStatus (Dropdown: Passed, Failed, Error, Pending)
    - patchValidationNotes (Text)
    - patchValidationDate (DateTime)
    
    Target: Devices with priority P3 (Medium) or P4 (Low)
    
    Exit Code 0 = Validation passed
    Exit Code 1 = Validation failed
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('P3','P4')]
    [string]$DevicePriority = 'P3'
)

try {
    Write-Output "=========================================="
    Write-Output "$DevicePriority Priority Device Patch Validation"
    Write-Output "=========================================="
    Write-Output "Device: $env:COMPUTERNAME"
    Write-Output "Priority: $DevicePriority"
    Write-Output ""

    $validationPassed = $true
    $validationNotes = @()

    # Get device characteristics
    $healthScore = Ninja-Property-Get opsHealthScore
    $stabilityScore = Ninja-Property-Get statStabilityScore

    Write-Output "Device Metrics:"
    Write-Output "  Health Score: $healthScore"
    Write-Output "  Stability Score: $stabilityScore"
    Write-Output ""

    # P3/P4 VALIDATION RULES (MINIMAL)
    Write-Output "$DevicePriority Validation Checks:"
    Write-Output ""

    if ($DevicePriority -eq 'P3') {
        # P3: Medium priority - standard validation

        # Rule 1: Health Score >= 60
        Write-Output "Check 1: Health Score >= 60"
        if ($healthScore -and $healthScore -ge 60) {
            Write-Output "  PASSED - Health Score: $healthScore"
        } elseif ($healthScore) {
            Write-Output "  FAILED - Health Score: $healthScore (minimum 60)"
            $validationPassed = $false
            $validationNotes += "Health score: $healthScore (min 60)"
        }

        # Rule 2: Stability Score >= 60 (warning only)
        Write-Output "Check 2: Stability Score >= 60"
        if ($stabilityScore -and $stabilityScore -ge 60) {
            Write-Output "  PASSED - Stability Score: $stabilityScore"
        } elseif ($stabilityScore) {
            Write-Output "  WARNING - Stability Score: $stabilityScore (recommended 60)"
            $validationNotes += "Low stability: $stabilityScore"
        }

    } else {
        # P4: Low priority - minimal validation

        # Rule 1: Health Score >= 50
        Write-Output "Check 1: Health Score >= 50"
        if ($healthScore -and $healthScore -ge 50) {
            Write-Output "  PASSED - Health Score: $healthScore"
        } elseif ($healthScore) {
            Write-Output "  FAILED - Health Score: $healthScore (minimum 50)"
            $validationPassed = $false
            $validationNotes += "Health score critically low: $healthScore"
        }

        Write-Output "Check 2: P4 Automated Patching"
        Write-Output "  INFO - P4 devices approved for automated patching"
        $validationNotes += "P4 auto-patch approved"
    }
    Write-Output ""

    # Common check: Disk space >= 10 GB
    Write-Output "Check: Disk Space >= 10 GB"
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
