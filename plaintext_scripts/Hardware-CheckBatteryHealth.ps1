#Requires -Version 5.1

<#
.SYNOPSIS
    Checks laptop battery health and reports wear level and capacity.

.DESCRIPTION
    This script queries laptop battery information using WMI to determine battery health status, 
    design capacity, current capacity, and wear level percentage. It helps identify batteries 
    that need replacement due to degradation.
    
    Battery wear affects laptop runtime and reliability. Monitoring battery health allows 
    proactive replacement before unexpected failures occur.

.PARAMETER WearThreshold
    Battery wear percentage threshold for alerting. Default: 20 (alert if wear >= 20%)

.PARAMETER SaveToCustomField
    Name of a custom field to save the battery health report.

.EXAMPLE
    -WearThreshold 25

    [Info] Checking battery health...
    Battery Name: Primary Battery
    Design Capacity: 50000 mWh
    Current Capacity: 42000 mWh
    Wear Level: 16%
    [Info] Battery health is acceptable

.EXAMPLE
    -WearThreshold 15 -SaveToCustomField "BatteryHealth"

    [Info] Checking battery health...
    Battery Name: Primary Battery
    Wear Level: 22%
    [Alert] Battery wear exceeds threshold of 15% - replacement recommended
    [Info] Report saved to custom field 'BatteryHealth'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016 (laptops only)
    Release notes: Initial release for WAF v3.0
    Note: Only applicable to laptops with batteries
    
.COMPONENT
    Win32_Battery - WMI battery information class
    
.LINK
    https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-battery

.FUNCTIONALITY
    - Queries WMI for battery information
    - Calculates battery wear percentage
    - Reports design capacity vs current capacity
    - Alerts when wear exceeds threshold
    - Can save battery health report to custom fields
    - Detects systems without batteries (desktops)
#>

[CmdletBinding()]
param(
    [int]$WearThreshold = 20,
    [string]$SaveToCustomField
)

begin {
    if ($env:wearThreshold -and $env:wearThreshold -notlike "null") {
        $WearThreshold = [int]$env:wearThreshold
    }
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
        Write-Host "[Info] Checking battery health..."
        
        $Battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

        if (-not $Battery) {
            Write-Host "[Info] No battery detected - system may be a desktop or battery is not accessible"
            exit 0
        }

        $DesignCapacity = $Battery.DesignCapacity
        $FullChargeCapacity = $Battery.FullChargeCapacity

        if ($DesignCapacity -and $FullChargeCapacity) {
            $WearLevel = [Math]::Round((($DesignCapacity - $FullChargeCapacity) / $DesignCapacity) * 100, 2)
            
            Write-Host "Battery Name: $($Battery.Name)"
            Write-Host "Design Capacity: $DesignCapacity mWh"
            Write-Host "Current Capacity: $FullChargeCapacity mWh"
            Write-Host "Wear Level: $WearLevel%"

            $Report = "Battery: $($Battery.Name) | Wear: $WearLevel% | Design: $DesignCapacity mWh | Current: $FullChargeCapacity mWh"

            if ($WearLevel -ge $WearThreshold) {
                Write-Host "[Alert] Battery wear exceeds threshold of $WearThreshold% - replacement recommended"
                $ExitCode = 1
            }
            else {
                Write-Host "[Info] Battery health is acceptable"
            }

            if ($SaveToCustomField) {
                try {
                    $Report | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Host "[Info] Report saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Host "[Error] Failed to save to custom field: $_"
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Host "[Warn] Unable to retrieve battery capacity information"
        }
    }
    catch {
        Write-Host "[Error] Failed to check battery health: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
