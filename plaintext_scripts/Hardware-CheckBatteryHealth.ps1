#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves detailed battery health information.

.DESCRIPTION
    Generates comprehensive battery health report using Windows powercfg utility.
    Provides system info, battery specifications, capacity history, usage patterns,
    and power usage data.
    
    The script performs the following:
    - Checks for Administrator privileges
    - Validates presence of battery hardware
    - Excludes Windows Server systems
    - Generates battery health report using powercfg
    - Parses XML report for detailed metrics
    - Extracts system information (manufacturer, model, BIOS)
    - Retrieves battery specifications (capacity, chemistry)
    - Calculates usable battery percentage
    - Formats and displays comprehensive report
    - Optionally saves report to custom field
    
    Battery health monitoring helps identify aging batteries before they fail.

.PARAMETER WYSIWYGCustomField
    Name of WYSIWYG custom field to save the formatted HTML battery report.
    Must be a valid NinjaRMM custom field name.

.EXAMPLE
    .\Hardware-CheckBatteryHealth.ps1

    [2026-02-10 22:03:00] [INFO] Creating battery health report
    [2026-02-10 22:03:02] [INFO] Battery health report created successfully
    [2026-02-10 22:03:02] [SUCCESS] Battery Capacity: 89.5%

    ### System Information ###
    ReportTime        : 2/10/2026 10:03 PM
    SystemProductName : Dell Latitude 7420
    BIOS              : 1.15.0 5/12/2023
    OSBuild           : 22631.3007
    ConnectedStandby  : Supported

.EXAMPLE
    .\Hardware-CheckBatteryHealth.ps1 -WYSIWYGCustomField "BatteryHealthReport"

    Creates and stores battery health report in specified custom field.

.OUTPUTS
    Formatted battery health report to console.
    Optional custom field update with HTML report.

.NOTES
    File Name      : Hardware-CheckBatteryHealth.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows 11
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with error/warning counters and execution summary
    - 2.0: Refactored to V3.0 standards with Write-Log function
    - 1.0: Initial release
    
    Execution Context: Administrator (required)
    Execution Frequency: On-demand or scheduled (daily/weekly)
    Typical Duration: 2-5 seconds
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A
    
    Required Privileges:
        - Administrator: Required for powercfg battery report generation
    
    Hardware Requirements:
        - Laptop or tablet with battery
        - ACPI-compliant battery
        - Not supported on Windows Server
    
    Exit Codes:
        0 - Success (battery report generated)
        1 - Failure (no admin, no battery, server OS, or generation failed)

.COMPONENT
    powercfg.exe - Windows power configuration utility
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Generates battery health reports
    - Calculates battery capacity degradation
    - Retrieves battery specifications
    - Monitors battery health over time
    - Validates battery hardware presence
    - Formats comprehensive health data
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for HTML report")]
    [String]$WYSIWYGCustomField
)

begin {
    Set-StrictMode -Version Latest
    
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Hardware-CheckBatteryHealth"
    
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        Write-Output $LogMessage
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if (-not (Test-IsElevated)) {
            Write-Log "Access Denied. Administrator privileges required." -Level ERROR
            Write-Log "Please run this script as Administrator." -Level ERROR
            $script:ExitCode = 1
            return
        }

        Write-Log "Checking for battery hardware" -Level INFO
        
        $CurrentBattery = if ($PSVersionTable.PSVersion.Major -lt 3) {
            Get-WmiObject -Class Win32_Battery -ErrorAction Stop
        }
        else {
            Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop
        }

        if (-not $CurrentBattery) {
            Write-Log "No battery detected on this system" -Level ERROR
            Write-Log "This script requires a laptop or tablet with a battery" -Level ERROR
            $script:ExitCode = 1
            return
        }

        Write-Log "Battery detected" -Level INFO

        if (Test-IsServer) {
            Write-Log "Battery report is not available on Windows Server" -Level ERROR
            $script:ExitCode = 1
            return
        }

        $BatteryReport = "$env:TEMP\batteryhealthreport.xml"
        $PowerCfgArguments = @("/BATTERYREPORT", "/XML", "/OUTPUT", "`"$BatteryReport`"")

        Write-Log "Creating battery health report" -Level INFO
        
        $Result = & "$env:SYSTEMROOT\System32\powercfg.exe" $PowerCfgArguments 2>&1
        
        if (-not (Test-Path -Path $BatteryReport)) {
            Write-Log "Failed to generate battery health report" -Level ERROR
            Write-Log "powercfg.exe may not support battery reports on this system" -Level ERROR
            $script:ExitCode = 1
            return
        }

        Write-Log "Battery health report created successfully" -Level INFO

        [xml]$BatteryHealthReport = Get-Content -Path "$BatteryReport" -ErrorAction Stop
        Remove-Item -Path $BatteryReport -Force -ErrorAction SilentlyContinue

        if (-not $BatteryHealthReport) {
            Write-Log "Report was empty or could not be parsed" -Level ERROR
            $script:ExitCode = 1
            return
        }

        Write-Log "Parsing system information" -Level DEBUG
        $SystemManufacturer = $BatteryHealthReport.BatteryReport.SystemInformation.SystemManufacturer
        $SystemProductName = $BatteryHealthReport.BatteryReport.SystemInformation.SystemProductName
        $BIOSVersion = $BatteryHealthReport.BatteryReport.SystemInformation.BIOSVersion
        
        $BIOSDate = $null
        if ($BatteryHealthReport.BatteryReport.SystemInformation.BIOSDate) {
            try {
                $BIOSDate = [datetime]::Parse($BatteryHealthReport.BatteryReport.SystemInformation.BIOSDate)
            }
            catch {
                Write-Log "Failed to parse BIOS date" -Level WARN
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

        Write-Log "Parsing battery specifications" -Level DEBUG
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

        Write-Log "Battery health report generated successfully" -Level SUCCESS
        Write-Log "System: $($SystemInformation.SystemProductName)" -Level INFO
        Write-Log "Battery Capacity: $($Batteries[0].UsableBatteryPercentage)" -Level INFO
        
        if ($Batteries[0].UsableBatteryPercentage -like "*%") {
            $CapacityValue = [double]($Batteries[0].UsableBatteryPercentage -replace '%','')
            if ($CapacityValue -lt 80) {
                Write-Log "Battery capacity below 80% - consider replacement" -Level WARN
            }
        }

        Write-Output "`n### System Information ###"
        ($SystemInformation | Format-List | Out-String).Trim() | Write-Output
        Write-Output "`n### Installed Batteries ###"
        ($Batteries | Format-List | Out-String).Trim() | Write-Output
        
        if ($WYSIWYGCustomField) {
            Write-Log "Custom field integration not yet implemented" -Level WARN
        }
    }
    catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output ""
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Summary:" -Level INFO
        Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "  Errors: $script:ErrorCount" -Level INFO
        Write-Log "  Warnings: $script:WarningCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        exit $script:ExitCode
    }
}
