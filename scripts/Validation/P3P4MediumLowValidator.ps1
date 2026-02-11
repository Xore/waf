#Requires -Version 5.1

<#
.SYNOPSIS
    P3/P4 Medium and Low Priority Device Patch Validation

.DESCRIPTION
    Performs minimal validation checks before allowing patch deployment on P3 (Medium) and P4
    (Low) priority devices. Standards are relaxed to enable automated patching with minimal
    friction while ensuring basic system health.

.PARAMETER DevicePriority
    Priority level - P3 (Medium) or P4 (Low). Default: P3

.PARAMETER ValidationStatusField
    NinjaRMM custom field name to store validation status. Default: patchValidationStatus

.PARAMETER ValidationNotesField
    NinjaRMM custom field name to store validation notes. Default: patchValidationNotes

.PARAMETER ValidationDateField
    NinjaRMM custom field name to store validation timestamp. Default: patchValidationDate

.PARAMETER P3HealthThreshold
    Minimum health score for P3 devices. Default: 60

.PARAMETER P3StabilityThreshold
    Minimum stability score for P3 devices (warning only). Default: 60

.PARAMETER P4HealthThreshold
    Minimum health score for P4 devices. Default: 50

.PARAMETER MinDiskSpaceGB
    Minimum free disk space required in GB. Default: 10

.EXAMPLE
    .\P3P4MediumLowValidator.ps1 -DevicePriority P3

.EXAMPLE
    .\P3P4MediumLowValidator.ps1 -DevicePriority P4 -P4HealthThreshold 40

.OUTPUTS
    None. Results are written to console and NinjaRMM custom fields.

.NOTES
    File Name      : P3P4MediumLowValidator.ps1
    Version        : 3.0.0
    Author         : WAF Team
    Framework      : V3
    
    Exit Codes:
    - 0: Validation passed
    - 1: Validation failed or error occurred
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('P3', 'P4')]
    [String]$DevicePriority = 'P3',
    
    [Parameter()]
    [String]$ValidationStatusField = "patchValidationStatus",
    
    [Parameter()]
    [String]$ValidationNotesField = "patchValidationNotes",
    
    [Parameter()]
    [String]$ValidationDateField = "patchValidationDate",
    
    [Parameter()]
    [ValidateRange(0, 100)]
    [Int]$P3HealthThreshold = 60,
    
    [Parameter()]
    [ValidateRange(0, 100)]
    [Int]$P3StabilityThreshold = 60,
    
    [Parameter()]
    [ValidateRange(0, 100)]
    [Int]$P4HealthThreshold = 50,
    
    [Parameter()]
    [ValidateRange(1, 1000)]
    [Int]$MinDiskSpaceGB = 10
)

begin {
    $ErrorActionPreference = 'Stop'
    $StartTime = Get-Date
    $script:ExitCode = 0
    
    function Write-Log { param([string]$Message, [string]$Level = 'INFO'); Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"; if ($Level -eq 'ERROR') { $script:ExitCode = 1 } }
    function Set-NinjaProperty { param([string]$Name, $Value); try { $Value | Ninja-Property-Set-Piped -Name $Name } catch { throw "Failed to set NinjaRMM property '$Name': $_" } }
    function Get-NinjaProperty { param([string]$Name); try { Ninja-Property-Get $Name } catch { Write-Log "Failed to read property '$Name': $_" -Level WARNING; return $null } }
    
    if ($env:devicePriority -and $env:devicePriority -notlike "null") { $DevicePriority = $env:devicePriority }
    if ($env:p3HealthThreshold -and $env:p3HealthThreshold -notlike "null") { $P3HealthThreshold = [int]$env:p3HealthThreshold }
    if ($env:p3StabilityThreshold -and $env:p3StabilityThreshold -notlike "null") { $P3StabilityThreshold = [int]$env:p3StabilityThreshold }
    if ($env:p4HealthThreshold -and $env:p4HealthThreshold -notlike "null") { $P4HealthThreshold = [int]$env:p4HealthThreshold }
    if ($env:minDiskSpaceGB -and $env:minDiskSpaceGB -notlike "null") { $MinDiskSpaceGB = [int]$env:minDiskSpaceGB }
}

process {
    try {
        Write-Log "========================================"
        Write-Log "$DevicePriority Priority Device Patch Validation"
        Write-Log "Device: $env:COMPUTERNAME | Priority: $DevicePriority"
        Write-Log "========================================"
        
        $validationPassed = $true
        $validationNotes = @()

        $healthScore = Get-NinjaProperty "opsHealthScore"
        $stabilityScore = Get-NinjaProperty "statStabilityScore"

        Write-Log "Metrics: Health=$healthScore, Stability=$stabilityScore"

        if ($DevicePriority -eq 'P3') {
            Write-Log "P3 MEDIUM PRIORITY VALIDATION"
            
            Write-Log "Check 1: Health Score (minimum $P3HealthThreshold)"
            if ($null -ne $healthScore -and $healthScore -ge $P3HealthThreshold) {
                Write-Log "Health Score: $healthScore/$P3HealthThreshold" -Level PASS
            } elseif ($null -ne $healthScore) {
                Write-Log "Health Score: $healthScore/$P3HealthThreshold - BELOW THRESHOLD" -Level FAIL
                $validationPassed = $false
                $validationNotes += "Health: $healthScore (min $P3HealthThreshold)"
            }

            Write-Log "Check 2: Stability Score (minimum $P3StabilityThreshold - warning only)"
            if ($null -ne $stabilityScore -and $stabilityScore -ge $P3StabilityThreshold) {
                Write-Log "Stability Score: $stabilityScore/$P3StabilityThreshold" -Level PASS
            } elseif ($null -ne $stabilityScore) {
                Write-Log "Stability Score: $stabilityScore/$P3StabilityThreshold - LOW" -Level WARNING
                $validationNotes += "Low stability: $stabilityScore"
            }
        } 
        else {
            Write-Log "P4 LOW PRIORITY VALIDATION"
            
            Write-Log "Check 1: Health Score (minimum $P4HealthThreshold)"
            if ($null -ne $healthScore -and $healthScore -ge $P4HealthThreshold) {
                Write-Log "Health Score: $healthScore/$P4HealthThreshold" -Level PASS
            } elseif ($null -ne $healthScore) {
                Write-Log "Health Score: $healthScore/$P4HealthThreshold - CRITICALLY LOW" -Level FAIL
                $validationPassed = $false
                $validationNotes += "Critical health: $healthScore"
            }

            Write-Log "P4 devices approved for automated patching"
            $validationNotes += "P4 auto-patch approved"
        }

        Write-Log "Check: Disk Space (minimum $MinDiskSpaceGB GB)"
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
