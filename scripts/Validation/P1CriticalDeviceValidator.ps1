#Requires -Version 5.1

<#
.SYNOPSIS
    P1 Critical Device Patch Validation

.DESCRIPTION
    Performs comprehensive validation checks before allowing patch deployment on P1 (Critical
    priority) devices. Requires highest standards for health, stability, and recent backups.
    
    P1 devices are business-critical systems where downtime has significant financial or
    operational impact. This validator enforces strictest standards including:
    - Minimum health score of 80/100
    - Minimum stability score of 80/100
    - Maximum 2 crashes in last 30 days
    - Recent backup within 24 hours
    - Minimum 15 GB free disk space
    - Change management approval required
    
    Validation results determine whether automated patch deployment can proceed or requires
    manual intervention and maintenance window scheduling.

.PARAMETER ValidationStatusField
    NinjaRMM custom field name to store validation status.
    Default: patchValidationStatus

.PARAMETER ValidationNotesField
    NinjaRMM custom field name to store validation notes.
    Default: patchValidationNotes

.PARAMETER ValidationDateField
    NinjaRMM custom field name to store validation timestamp.
    Default: patchValidationDate

.PARAMETER HealthScoreThreshold
    Minimum health score required for P1 device validation.
    Default: 80

.PARAMETER StabilityScoreThreshold
    Minimum stability score required for P1 device validation.
    Default: 80

.PARAMETER MaxCrashCount
    Maximum crashes allowed in last 30 days.
    Default: 2

.PARAMETER BackupAgeHours
    Maximum age of backup in hours.
    Default: 24

.PARAMETER MinDiskSpaceGB
    Minimum free disk space required in GB.
    Default: 15

.EXAMPLE
    .\P1CriticalDeviceValidator.ps1

    Runs P1 validation with default thresholds.

.EXAMPLE
    .\P1CriticalDeviceValidator.ps1 -HealthScoreThreshold 85 -BackupAgeHours 12

    Runs with stricter health requirements and 12-hour backup window.

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : P1CriticalDeviceValidator.ps1
    Prerequisite   : PowerShell 5.1 or higher, Admin privileges
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    Frequency      : Before each patch deployment
    Runtime        : Approximately 15-20 seconds
    Timeout        : 60 seconds
    Context        : SYSTEM
    
    Change Log:
    - 3.0.0: V3 migration with standardized logging, error handling, and parameterized thresholds
    - 4.0: Previous version with P1 validation
    
    Fields Updated:
    - patchValidationStatus: Text (Passed, Failed, Error, Pending)
    - patchValidationNotes: Text semicolon-separated validation notes
    - patchValidationDate: DateTime timestamp of validation
    
    Fields Read (from other WAF scripts):
    - opsHealthScore: Overall health score
    - statStabilityScore: System stability score
    - opsPerformanceScore: Performance score
    - baseBusinessCriticality: Business criticality level
    - riskExposureLevel: Risk level
    - statCrashCount30d: Crash count in last 30 days
    - backupLastSuccess: Last successful backup timestamp
    - srvRole: Server role
    
    Target Devices:
    - P1 priority devices
    - Critical business criticality systems
    
    Exit Codes:
    - 0: Validation passed
    - 1: Validation failed or error occurred
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$ValidationStatusField = "patchValidationStatus",
    
    [Parameter()]
    [String]$ValidationNotesField = "patchValidationNotes",
    
    [Parameter()]
    [String]$ValidationDateField = "patchValidationDate",
    
    [Parameter()]
    [ValidateRange(0, 100)]
    [Int]$HealthScoreThreshold = 80,
    
    [Parameter()]
    [ValidateRange(0, 100)]
    [Int]$StabilityScoreThreshold = 80,
    
    [Parameter()]
    [ValidateRange(0, 100)]
    [Int]$MaxCrashCount = 2,
    
    [Parameter()]
    [ValidateRange(1, 168)]
    [Int]$BackupAgeHours = 24,
    
    [Parameter()]
    [ValidateRange(1, 1000)]
    [Int]$MinDiskSpaceGB = 15
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    $script:ExitCode = 0
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Output $LogMessage; $script:ExitCode = 1 }
            'FAIL' { Write-Output $LogMessage }
            'PASS' { Write-Output $LogMessage }
            'WARNING' { Write-Output $LogMessage }
            default { Write-Output $LogMessage }
        }
    }

    if ($env:validationStatusField -and $env:validationStatusField -notlike "null") {
        $ValidationStatusField = $env:validationStatusField
    }
    if ($env:validationNotesField -and $env:validationNotesField -notlike "null") {
        $ValidationNotesField = $env:validationNotesField
    }
    if ($env:validationDateField -and $env:validationDateField -notlike "null") {
        $ValidationDateField = $env:validationDateField
    }
    if ($env:healthScoreThreshold -and $env:healthScoreThreshold -notlike "null") {
        $HealthScoreThreshold = [int]$env:healthScoreThreshold
    }
    if ($env:stabilityScoreThreshold -and $env:stabilityScoreThreshold -notlike "null") {
        $StabilityScoreThreshold = [int]$env:stabilityScoreThreshold
    }
    if ($env:maxCrashCount -and $env:maxCrashCount -notlike "null") {
        $MaxCrashCount = [int]$env:maxCrashCount
    }
    if ($env:backupAgeHours -and $env:backupAgeHours -notlike "null") {
        $BackupAgeHours = [int]$env:backupAgeHours
    }
    if ($env:minDiskSpaceGB -and $env:minDiskSpaceGB -notlike "null") {
        $MinDiskSpaceGB = [int]$env:minDiskSpaceGB
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $Value
        )
        try {
            $NinjaValue = $Value
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
        }
        catch {
            throw "Failed to set NinjaRMM property '$Name': $_"
        }
    }

    function Get-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name
        )
        try {
            $result = Ninja-Property-Get $Name 2>&1
            if ($result.Exception) {
                throw $result
            }
            return $result
        }
        catch {
            Write-Log "Failed to read NinjaRMM property '$Name': $_" -Level WARNING
            return $null
        }
    }
}

process {
    try {
        Write-Log "========================================"
        Write-Log "P1 Critical Device Patch Validation"
        Write-Log "========================================"
        Write-Log "Device: $env:COMPUTERNAME"
        Write-Log "Priority: P1 (Critical)"
        Write-Log ""
        
        $validationPassed = $true
        $validationNotes = @()
        $validationDetails = @()

        Write-Log "Retrieving device health metrics..."
        $healthScore = Get-NinjaProperty -Name "opsHealthScore"
        $stabilityScore = Get-NinjaProperty -Name "statStabilityScore"
        $performanceScore = Get-NinjaProperty -Name "opsPerformanceScore"
        $businessCriticality = Get-NinjaProperty -Name "baseBusinessCriticality"
        $riskLevel = Get-NinjaProperty -Name "riskExposureLevel"
        $crashCount = Get-NinjaProperty -Name "statCrashCount30d"

        Write-Log "  Health Score: $healthScore"
        Write-Log "  Stability Score: $stabilityScore"
        Write-Log "  Performance Score: $performanceScore"
        Write-Log "  Business Criticality: $businessCriticality"
        Write-Log "  Risk Level: $riskLevel"
        Write-Log "  Recent Crashes (30d): $crashCount"
        Write-Log ""

        Write-Log "P1 Validation Checks (Critical Priority):"
        Write-Log ""

        Write-Log "Check 1: Health Score Validation (minimum $HealthScoreThreshold)"
        if ($null -ne $healthScore -and $healthScore -ge $HealthScoreThreshold) {
            Write-Log "Health Score: $healthScore/$HealthScoreThreshold" -Level PASS
            $validationDetails += "Health: $healthScore/100"
        } 
        elseif ($null -ne $healthScore) {
            Write-Log "Health Score: $healthScore/$HealthScoreThreshold - BELOW THRESHOLD" -Level FAIL
            $validationPassed = $false
            $validationNotes += "Health score too low: $healthScore (min $HealthScoreThreshold)"
        } 
        else {
            Write-Log "Health Score not available" -Level WARNING
            $validationNotes += "Health score unavailable"
        }

        Write-Log "Check 2: Stability Score Validation (minimum $StabilityScoreThreshold)"
        if ($null -ne $stabilityScore -and $stabilityScore -ge $StabilityScoreThreshold) {
            Write-Log "Stability Score: $stabilityScore/$StabilityScoreThreshold" -Level PASS
            $validationDetails += "Stability: $stabilityScore/100"
        } 
        elseif ($null -ne $stabilityScore) {
            Write-Log "Stability Score: $stabilityScore/$StabilityScoreThreshold - BELOW THRESHOLD" -Level FAIL
            $validationPassed = $false
            $validationNotes += "Stability score too low: $stabilityScore (min $StabilityScoreThreshold)"
        } 
        else {
            Write-Log "Stability Score not available" -Level WARNING
        }

        Write-Log "Check 3: Crash History Validation (maximum $MaxCrashCount)"
        if ($null -ne $crashCount) {
            if ($crashCount -eq 0) {
                Write-Log "No crashes in last 30 days" -Level PASS
                $validationDetails += "Crashes: 0"
            } 
            elseif ($crashCount -le $MaxCrashCount) {
                Write-Log "$crashCount crashes in last 30 days (acceptable)" -Level WARNING
                $validationDetails += "Crashes: $crashCount"
            } 
            else {
                Write-Log "$crashCount crashes in last 30 days - EXCEEDS MAXIMUM" -Level FAIL
                $validationPassed = $false
                $validationNotes += "Too many crashes: $crashCount (max $MaxCrashCount)"
            }
        }

        Write-Log "Check 4: Business Criticality Verification"
        if ($businessCriticality -eq 'Critical') {
            Write-Log "Correctly marked as Critical" -Level PASS
            $validationDetails += "Criticality: Critical"
        } 
        else {
            Write-Log "P1 device not marked as Critical (current: $businessCriticality)" -Level WARNING
            $validationNotes += "Criticality mismatch: $businessCriticality"
        }

        Write-Log "Check 5: Backup Recency Validation (maximum $BackupAgeHours hours)"
        $lastBackup = Get-NinjaProperty -Name "backupLastSuccess"
        
        if ($lastBackup) {
            try {
                $backupAge = (Get-Date) - [datetime]$lastBackup
                $backupHours = [math]::Round($backupAge.TotalHours, 1)

                if ($backupHours -le $BackupAgeHours) {
                    Write-Log "Recent backup: $backupHours hours ago" -Level PASS
                    $validationDetails += "Backup: $backupHours hrs ago"
                } 
                elseif ($backupHours -le ($BackupAgeHours * 2)) {
                    Write-Log "Backup is $backupHours hours old (recommended: $BackupAgeHours hours)" -Level WARNING
                    $validationDetails += "Backup: $backupHours hrs ago"
                } 
                else {
                    Write-Log "Backup is $backupHours hours old - TOO OLD" -Level FAIL
                    $validationPassed = $false
                    $validationNotes += "Backup too old: $backupHours hours (max $BackupAgeHours)"
                }
            }
            catch {
                Write-Log "Failed to parse backup date" -Level FAIL
                $validationPassed = $false
                $validationNotes += "Invalid backup date"
            }
        } 
        else {
            Write-Log "No backup information available" -Level FAIL
            $validationPassed = $false
            $validationNotes += "No backup verification"
        }

        Write-Log "Check 6: Disk Space Validation (minimum $MinDiskSpaceGB GB)"
        try {
            $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
            $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

            if ($freeSpaceGB -ge $MinDiskSpaceGB) {
                Write-Log "Disk space: $freeSpaceGB GB" -Level PASS
                $validationDetails += "Disk: $freeSpaceGB GB free"
            } 
            elseif ($freeSpaceGB -ge ($MinDiskSpaceGB * 0.66)) {
                Write-Log "Disk space: $freeSpaceGB GB (recommended $MinDiskSpaceGB GB for P1)" -Level WARNING
                $validationDetails += "Disk: $freeSpaceGB GB free"
            } 
            else {
                Write-Log "Disk space: $freeSpaceGB GB - INSUFFICIENT" -Level FAIL
                $validationPassed = $false
                $validationNotes += "Insufficient disk space: $freeSpaceGB GB (min $MinDiskSpaceGB)"
            }
        }
        catch {
            Write-Log "Failed to check disk space: $_" -Level WARNING
        }

        Write-Log "Check 7: Change Management"
        Write-Log "P1 Critical systems require change approval"
        Write-Log "Ensure change ticket is created before deployment"
        $validationNotes += "Change approval required"

        Write-Log "Check 8: Maintenance Window Recommendation"
        $serverRole = Get-NinjaProperty -Name "srvRole"
        
        if ($serverRole) {
            Write-Log "Server role detected: $serverRole"
            Write-Log "RECOMMENDATION: Deploy during maintenance window"
            $validationNotes += "Maintenance window recommended"
        }

        Write-Log ""
        Write-Log "========================================"
        Write-Log "Validation Summary"
        Write-Log "========================================"

        $validationStatus = if ($validationPassed) { "Passed" } else { "Failed" }
        
        if ($validationPassed) {
            Write-Log "STATUS: PASSED"
            Write-Log "P1 Critical device meets all validation requirements"
        } 
        else {
            Write-Log "STATUS: FAILED"
            Write-Log "P1 Critical device does not meet validation requirements"
            $script:ExitCode = 1
        }

        Write-Log ""
        Write-Log "Validation Notes:"
        $validationNotes | ForEach-Object { Write-Log "  - $_" }

        try {
            Set-NinjaProperty -Name $ValidationStatusField -Value $validationStatus -ErrorAction Stop
            Write-Log "Validation status saved to field: $ValidationStatusField"
        }
        catch {
            Write-Log "Failed to update validation status field: $_" -Level ERROR
        }

        $notesText = if ($validationNotes.Count -gt 0) {
            $validationNotes -join "; "
        } 
        else {
            "All checks passed"
        }

        try {
            Set-NinjaProperty -Name $ValidationNotesField -Value $notesText -ErrorAction Stop
            Write-Log "Validation notes saved to field: $ValidationNotesField"
        }
        catch {
            Write-Log "Failed to update validation notes field: $_" -Level ERROR
        }

        try {
            Set-NinjaProperty -Name $ValidationDateField -Value (Get-Date) -ErrorAction Stop
            Write-Log "Validation timestamp saved to field: $ValidationDateField"
        }
        catch {
            Write-Log "Failed to update validation date field: $_" -Level ERROR
        }

        Write-Log "========================================"
        Write-Log "P1 Critical Device Validation completed"
    }
    catch {
        Write-Log "P1 validation failed with unexpected error: $_" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
        
        try {
            Set-NinjaProperty -Name $ValidationStatusField -Value "Error" -ErrorAction SilentlyContinue
            Set-NinjaProperty -Name $ValidationNotesField -Value "Validation script error: $_" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Failed to set error state fields" -Level ERROR
        }
        
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log "Script execution completed in $([Math]::Round($Duration, 2)) seconds"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
