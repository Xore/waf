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
    -SaveToCustomField "DiskHealth"

    [Info] Querying S.M.A.R.T. status for physical disks...
    Disk 0: Healthy
    Disk 1: Healthy
    [Info] All disks reporting healthy status
    [Info] S.M.A.R.T. status saved to custom field 'DiskHealth'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
.COMPONENT
    MSFT_PhysicalDisk - Storage WMI class for disk health
    
.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/storage/msft-physicaldisk

.FUNCTIONALITY
    - Queries MSFT_PhysicalDisk for S.M.A.R.T. health status
    - Reports predictive failure indicators
    - Identifies disks requiring immediate replacement
    - Provides health status for all physical disks
    - Can save health report to custom fields for monitoring
#>

[CmdletBinding()]
param(
    [string]$SaveToCustomField
)

begin {
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
}

process {
    try {
        Write-Host "[Info] Querying S.M.A.R.T. status for physical disks..."
        
        $PhysicalDisks = Get-PhysicalDisk -ErrorAction Stop
        $DiskStatuses = @()

        foreach ($Disk in $PhysicalDisks) {
            $HealthStatus = $Disk.HealthStatus
            $OperationalStatus = $Disk.OperationalStatus
            
            Write-Host "Disk $($Disk.DeviceId): $HealthStatus ($OperationalStatus)"
            $DiskStatuses += "Disk $($Disk.DeviceId): $HealthStatus"

            if ($HealthStatus -ne "Healthy") {
                Write-Host "[Alert] Disk $($Disk.DeviceId) is reporting unhealthy status: $HealthStatus"
                $ExitCode = 1
            }
        }

        if ($ExitCode -eq 0) {
            Write-Host "[Info] All disks reporting healthy status"
        }

        if ($SaveToCustomField) {
            try {
                $DiskStatuses -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] S.M.A.R.T. status saved to custom field '$SaveToCustomField'"
            }
            catch {
                Write-Host "[Error] Failed to save to custom field: $_"
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to query S.M.A.R.T. status: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
