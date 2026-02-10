#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves S.M.A.R.T. (Self-Monitoring, Analysis and Reporting Technology) disk health status.

.DESCRIPTION
    This script queries physical disk drives for S.M.A.R.T. health status indicators to detect 
    potential drive failures before they occur. It uses WMI to access disk health data and 
    reports the predictive failure status of each drive.
    
    S.M.A.R.T. monitoring is critical for proactive disk failure detection. Drives reporting 
    predictive failure should be replaced immediately to prevent data loss.

.PARAMETER SaveToCustomField
    Name of a custom field to save the S.M.A.R.T. status report.

.EXAMPLE
    .\Disk-GetSMARTStatus.ps1

    Querying S.M.A.R.T. status for physical disks...
    Disk 0: Healthy
    Disk 1: Healthy
    All disks reporting healthy status

.EXAMPLE
    .\Disk-GetSMARTStatus.ps1 -SaveToCustomField "DiskHealth"

    Querying S.M.A.R.T. status for physical disks...
    Disk 0: Healthy
    Disk 1: Healthy
    All disks reporting healthy status
    S.M.A.R.T. status saved to custom field 'DiskHealth'

.OUTPUTS
    None

.NOTES
    File Name      : Disk-GetSMARTStatus.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced SMART monitoring and reporting
    - 1.0: Initial release
    
.COMPONENT
    MSFT_PhysicalDisk - Storage WMI class for disk health
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Queries MSFT_PhysicalDisk for S.M.A.R.T. health status
    - Reports predictive failure indicators
    - Identifies disks requiring immediate replacement
    - Provides health status for all physical disks
    - Can save health report to custom fields for monitoring
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SaveToCustomField
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Disk-GetSMARTStatus"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $ProgressPreference = 'SilentlyContinue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:UnhealthyDiskCount = 0

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS','ALERT')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Write-Output "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
            'ALERT' { $script:ErrorCount++ }
        }
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Name,
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
            $Value
        )
        
        try {
            $CustomField = $Value | Ninja-Property-Set-Piped -Name $Name 2>&1
            if ($CustomField.Exception) {
                throw $CustomField
            }
            Write-Log "Custom field '$Name' set successfully" -Level DEBUG
        } catch {
            Write-Log "Failed to set custom field '$Name': $_" -Level ERROR
            throw
        }
    }

    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
        Write-Log "Using SaveToCustomField from environment: $SaveToCustomField" -Level DEBUG
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        Write-Log "Querying S.M.A.R.T. status for physical disks..." -Level INFO
        
        $PhysicalDisks = Get-PhysicalDisk -ErrorAction Stop
        $DiskStatuses = @()
        $DiskCount = ($PhysicalDisks | Measure-Object).Count
        
        Write-Log "Found $DiskCount physical disk(s)" -Level INFO

        foreach ($Disk in $PhysicalDisks) {
            $HealthStatus = $Disk.HealthStatus
            $OperationalStatus = $Disk.OperationalStatus
            $FriendlyName = $Disk.FriendlyName
            $MediaType = $Disk.MediaType
            $SizeGB = [math]::Round($Disk.Size / 1GB, 2)
            
            $DiskInfo = "Disk $($Disk.DeviceId) ($FriendlyName, $MediaType, $SizeGB GB): $HealthStatus"
            Write-Log $DiskInfo -Level INFO
            
            $DiskStatuses += "Disk $($Disk.DeviceId): $HealthStatus ($OperationalStatus)"

            if ($HealthStatus -ne "Healthy") {
                Write-Log "Disk $($Disk.DeviceId) ($FriendlyName) is reporting unhealthy status: $HealthStatus" -Level ALERT
                $script:UnhealthyDiskCount++
                $script:ExitCode = 1
            }
        }

        if ($script:UnhealthyDiskCount -eq 0) {
            Write-Log "All disks reporting healthy status" -Level SUCCESS
        } else {
            Write-Log "$script:UnhealthyDiskCount disk(s) reporting unhealthy status - immediate attention required!" -Level ALERT
        }

        if ($SaveToCustomField) {
            try {
                $StatusReport = $DiskStatuses -join "; "
                $StatusReport | Set-NinjaProperty -Name $SaveToCustomField
                Write-Log "S.M.A.R.T. status saved to custom field '$SaveToCustomField'" -Level INFO
            } catch {
                Write-Log "Failed to save to custom field: $_" -Level ERROR
                $script:ExitCode = 1
            }
        }
        
        Write-Log "S.M.A.R.T. status check completed" -Level SUCCESS
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
        Write-Log "Unhealthy Disks: $script:UnhealthyDiskCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
