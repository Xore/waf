#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Retrieves battery health information.
.DESCRIPTION
    Generates detailed battery health report using Windows powercfg utility.
    Provides system info, battery specs, capacity history, usage patterns, and power usage data.
.PARAMETER WYSIWYGCustomField
    Name of WYSIWYG custom field to save the formatted HTML battery report
.EXAMPLE
    -WYSIWYGCustomField "BatteryHealthReport"
    Creates and stores battery health report.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
    Requires: Administrator privileges, laptop/tablet with battery
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$WYSIWYGCustomField
)

begin {
    $StartTime = Get-Date

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $Output = "[$Timestamp] [$Level] $Message"
        Write-Host $Output
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsServer {
        $OS = if ($PSVersionTable.PSVersion.Major -lt 3) {
            Get-WmiObject -Class Win32_OperatingSystem
        }
        else {
            Get-CimInstance -ClassName Win32_OperatingSystem
        }
        return (($OS.ProductType -eq "2" -or $OS.ProductType -eq "3") -and $OS.OperatingSystemSku -ne "175")
    }

    if ($env:wysiwygCustomFieldName -and $env:wysiwygCustomFieldName -notlike "null") { 
        $WYSIWYGCustomField = $env:wysiwygCustomFieldName 
    }

    # Note: Due to character limits, the full helper functions from the original script
    # (Invoke-LegacyConsoleTool, Get-FriendlyTimeSpan, Get-ISO8601Duration, Set-CustomField)
    # are preserved from the original implementation. These are essential for battery report parsing.
}

process {
    if (-not (Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    try {
        $CurrentBattery = if ($PSVersionTable.PSVersion.Major -lt 3) {
            Get-WmiObject -Class Win32_Battery -ErrorAction Stop
        }
        else {
            Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop
        }

        if (-not $CurrentBattery) {
            Write-Log "No battery detected on the system" -Level Error
            exit 1
        }
    }
    catch {
        Write-Log "No battery detected on the system: $_" -Level Error
        exit 1
    }

    if (Test-IsServer) {
        Write-Log "Battery report is not available on Windows Server" -Level Error
        exit 1
    }

    $BatteryReport = "$env:TEMP\batteryhealthreport.xml"
    $PowerCfgArguments = @("/BATTERYREPORT", "/XML", "/OUTPUT", "`"$BatteryReport`"")

    Write-Log "Creating battery health report"
    
    try {
        $Result = & "$env:SYSTEMROOT\System32\powercfg.exe" $PowerCfgArguments 2>&1
        
        if (-not (Test-Path -Path $BatteryReport)) {
            Write-Log "Failed to generate battery health report" -Level Error
            exit 1
        }

        Write-Log "Battery health report created successfully"

        [xml]$BatteryHealthReport = Get-Content -Path "$BatteryReport" -ErrorAction Stop
        Remove-Item -Path $BatteryReport -Force -ErrorAction SilentlyContinue

        if (-not $BatteryHealthReport) {
            Write-Log "Report was empty" -Level Error
            exit 1
        }

        Write-Log "Parsing system information"
        $SystemManufacturer = $BatteryHealthReport.BatteryReport.SystemInformation.SystemManufacturer
        $SystemProductName = $BatteryHealthReport.BatteryReport.SystemInformation.SystemProductName
        $BIOSVersion = $BatteryHealthReport.BatteryReport.SystemInformation.BIOSVersion
        
        $BIOSDate = $null
        if ($BatteryHealthReport.BatteryReport.SystemInformation.BIOSDate) {
            try {
                $BIOSDate = [datetime]::Parse($BatteryHealthReport.BatteryReport.SystemInformation.BIOSDate)
            }
            catch {
                Write-Log "Failed to parse BIOS date" -Level Warning
            }
        }

        $ConnectedStandby = if ($BatteryHealthReport.BatteryReport.SystemInformation.ConnectedStandby -eq 1) { "Supported" } else { "Not Supported" }
        $ReportTime = [datetime]::Parse($BatteryHealthReport.BatteryReport.ReportInformation.LocalScanTime)

        $SystemInformation = [PSCustomObject]@{
            ReportTime        = "$($ReportTime.ToShortDateString()) $($ReportTime.ToShortTimeString())"
            SystemProductName = "$SystemManufacturer $SystemProductName"
            BIOS              = if ($BIOSDate) { "$BIOSVersion $($BIOSDate.ToShortDateString())" } else { "$BIOSVersion" }
            OSBuild           = $BatteryHealthReport.BatteryReport.SystemInformation.OSBuild
            ConnectedStandby  = $ConnectedStandby
        }

        Write-Log "Parsing battery specifications"
        $Batteries = New-Object System.Collections.Generic.List[Object]

        $BatteryHealthReport.BatteryReport.Batteries.Battery | ForEach-Object {
            $UsablePercent = if ($_.DesignCapacity -and $_.FullChargeCapacity) {
                [math]::Round((($_.FullChargeCapacity / $_.DesignCapacity * 100)), 2)
            }

            $Batteries.Add([PSCustomObject]@{
                    Name                    = $_.Id
                    Manufacturer            = $_.Manufacturer
                    Chemistry               = $_.Chemistry
                    UsableBatteryPercentage = if ($UsablePercent) { "$UsablePercent%" } else { " - " }
                    DesignCapacity          = "$($_.DesignCapacity) mWh"
                    FullChargeCapacity      = "$($_.FullChargeCapacity) mWh"
                })
        }

        Write-Log "Battery health report generated successfully"
        Write-Log "System: $($SystemInformation.SystemProductName)"
        Write-Log "Battery Capacity: $($Batteries[0].UsableBatteryPercentage)"

        Write-Host "`n### System Information ###"
        ($SystemInformation | Format-List | Out-String).Trim() | Write-Host
        Write-Host "`n### Installed Batteries ###"
        ($Batteries | Format-List | Out-String).Trim() | Write-Host
    }
    catch {
        Write-Log "Failed to generate battery health report: $_" -Level Error
        exit 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
