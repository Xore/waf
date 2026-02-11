#Requires -Version 5.1

<#
.SYNOPSIS
    P2 High Priority Device Patch Validation

.DESCRIPTION
    Performs balanced validation checks before allowing patch deployment on P2 (High priority)
    devices. Standards are high but less strict than P1. Balances safety with deployment velocity.

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
    Minimum health score required. Default: 70

.PARAMETER StabilityScoreThreshold
    Minimum stability score required. Default: 70

.PARAMETER MaxCrashCount
    Maximum crashes allowed in last 30 days. Default: 5

.PARAMETER BackupAgeHours
    Maximum age of backup in hours. Default: 72

.PARAMETER MinDiskSpaceGB
    Minimum free disk space required in GB. Default: 10

.EXAMPLE
    .\P2HighPriorityValidator.ps1

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : P2HighPriorityValidator.ps1
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    
    Exit Codes:
    - 0: Validation passed
    - 1: Validation failed or error occurred
#>

[CmdletBinding()]
param (
    [String]$ValidationStatusField = "patchValidationStatus",
    [String]$ValidationNotesField = "patchValidationNotes",
    [String]$ValidationDateField = "patchValidationDate",
    [ValidateRange(0, 100)][Int]$HealthScoreThreshold = 70,
    [ValidateRange(0, 100)][Int]$StabilityScoreThreshold = 70,
    [ValidateRange(0, 100)][Int]$MaxCrashCount = 5,
    [ValidateRange(1, 168)][Int]$BackupAgeHours = 72,
    [ValidateRange(1, 1000)][Int]$MinDiskSpaceGB = 10
)

begin {
    $ErrorActionPreference = 'Stop'
    $StartTime = Get-Date
    $script:ExitCode = 0
    
    function Write-Log { param([string]$Message, [string]$Level = 'INFO'); Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"; if ($Level -eq 'ERROR') { $script:ExitCode = 1 } }
    function Set-NinjaProperty { param([string]$Name, $Value); try { $Value | Ninja-Property-Set-Piped -Name $Name } catch { throw "Failed to set NinjaRMM property '$Name': $_" } }
    function Get-NinjaProperty { param([string]$Name); try { Ninja-Property-Get $Name } catch { Write-Log "Failed to read property '$Name': $_" -Level WARNING; return $null } }
}

process {
    try {
        Write-Log "========================================"
        Write-Log "P2 High Priority Device Patch Validation"
        Write-Log "Device: $env:COMPUTERNAME | Priority: P2 (High)"
        Write-Log "========================================"
        
        $validationPassed = $true
        $validationNotes = @()

        $healthScore = Get-NinjaProperty "opsHealthScore"
        $stabilityScore = Get-NinjaProperty "statStabilityScore"
        $businessCriticality = Get-NinjaProperty "baseBusinessCriticality"
        $crashCount = Get-NinjaProperty "statCrashCount30d"

        Write-Log "Metrics: Health=$healthScore, Stability=$stabilityScore, Criticality=$businessCriticality, Crashes=$crashCount"

        if ($null -ne $healthScore -and $healthScore -ge $HealthScoreThreshold) {
            Write-Log "Health Score: $healthScore/$HealthScoreThreshold" -Level PASS
        } elseif ($null -ne $healthScore) {
            Write-Log "Health Score: $healthScore/$HealthScoreThreshold - BELOW THRESHOLD" -Level FAIL
            $validationPassed = $false
            $validationNotes += "Health: $healthScore (min $HealthScoreThreshold)"
        }

        if ($null -ne $stabilityScore -and $stabilityScore -ge $StabilityScoreThreshold) {
            Write-Log "Stability Score: $stabilityScore/$StabilityScoreThreshold" -Level PASS
        } elseif ($null -ne $stabilityScore) {
            Write-Log "Stability Score: $stabilityScore/$StabilityScoreThreshold - BELOW THRESHOLD" -Level FAIL
            $validationPassed = $false
            $validationNotes += "Stability: $stabilityScore (min $StabilityScoreThreshold)"
        }

        if ($null -ne $crashCount -and $crashCount -le $MaxCrashCount) {
            Write-Log "Crash Count: $crashCount (max $MaxCrashCount)" -Level PASS
        } elseif ($null -ne $crashCount) {
            Write-Log "Crash Count: $crashCount (max $MaxCrashCount)" -Level WARNING
            $validationNotes += "Crashes: $crashCount"
        }

        $lastBackup = Get-NinjaProperty "backupLastSuccess"
        if ($lastBackup) {
            $backupHours = [math]::Round(((Get-Date) - [datetime]$lastBackup).TotalHours, 1)
            if ($backupHours -le $BackupAgeHours) {
                Write-Log "Backup: $backupHours hours ago" -Level PASS
            } else {
                Write-Log "Backup: $backupHours hours old" -Level WARNING
                $validationNotes += "Backup: $backupHours hrs"
            }
        }

        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -ge $MinDiskSpaceGB) {
            Write-Log "Disk Space: $freeSpaceGB GB" -Level PASS
        } else {
            Write-Log "Disk Space: $freeSpaceGB GB - INSUFFICIENT" -Level FAIL
            $validationPassed = $false
            $validationNotes += "Disk: $freeSpaceGB GB (min $MinDiskSpaceGB)"
        }

        $status = if ($validationPassed) { "Passed" } else { "Failed"; $script:ExitCode = 1 }
        Write-Log "STATUS: $status"

        Set-NinjaProperty $ValidationStatusField $status
        Set-NinjaProperty $ValidationNotesField (if ($validationNotes) { $validationNotes -join "; " } else { "All checks passed" })
        Set-NinjaProperty $ValidationDateField (Get-Date)

        Write-Log "========================================"
    } catch {
        Write-Log "Validation failed: $_" -Level ERROR
        Set-NinjaProperty $ValidationStatusField "Error"
        $script:ExitCode = 1
    }
}

end {
    exit $script:ExitCode
}
