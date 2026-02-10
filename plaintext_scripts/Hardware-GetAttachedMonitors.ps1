#Requires -Version 5.1

<#
.SYNOPSIS
    Retrieves information about attached monitors.

.DESCRIPTION
    Queries WMI for connected monitor information including serial numbers,
    monitor names, and year of manufacture. Excludes built-in laptop displays.
    
    The script performs the following:
    - Creates CIM session for WMI queries
    - Queries WmiMonitorID class for monitor information
    - Filters monitors with friendly names (external monitors)
    - Extracts monitor name from UserFriendlyName
    - Extracts serial number from SerialNumberID
    - Retrieves year of manufacture
    - Formats results as readable text
    - Optionally saves to NinjaRMM custom field
    - Cleans up CIM sessions properly
    
    Useful for hardware inventory and asset tracking.

.PARAMETER CustomFieldName
    Name of custom field to save monitor information.
    Default: "attachedMonitors"

.EXAMPLE
    .\Hardware-GetAttachedMonitors.ps1

    [2026-02-10 22:04:00] [INFO] Querying attached monitors
    [2026-02-10 22:04:01] [SUCCESS] Found 2 attached monitor(s)
    
    ### Attached Monitors ###
    Monitor Name: Dell U2720Q
    Serial Number: ABC1234567
    Year of Manufacture: 2023

.EXAMPLE
    .\Hardware-GetAttachedMonitors.ps1 -CustomFieldName "monitorInventory"

    Saves monitor information to specified custom field.

.OUTPUTS
    Console output with monitor details.
    Optional custom field update.

.NOTES
    File Name      : Hardware-GetAttachedMonitors.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Complete V3 standards rewrite with error/warning counters
    - 1.0: Initial release
    
    Execution Context: SYSTEM or Administrator
    Execution Frequency: On-demand or scheduled
    Typical Duration: 1-3 seconds
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A
    
    Hardware Requirements:
        - External monitors connected via HDMI/DisplayPort/VGA/DVI
        - Monitors must support EDID (Extended Display Identification Data)
    
    Limitations:
        - Does not detect built-in laptop displays
        - Requires monitors to provide EDID information
        - Some monitors may not report all fields

.COMPONENT
    WmiMonitorID - WMI class for monitor information
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Queries connected monitor information
    - Retrieves monitor serial numbers
    - Identifies monitor models and manufacturers
    - Tracks monitor age via manufacture year
    - Hardware inventory and asset tracking
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for monitor data")]
    [string]$CustomFieldName = "attachedMonitors"
)

begin {
    Set-StrictMode -Version Latest
    
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Hardware-GetAttachedMonitors"
    
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:MonitorCount = 0

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

    if ($env:customFieldName -and $env:customFieldName -notlike "null") { 
        $CustomFieldName = $env:customFieldName 
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        Write-Log "Querying attached monitors" -Level INFO
        
        $SessionOptions = New-CimSessionOption -Protocol Dcom
        $Session = New-CimSession -OperationTimeoutSec 10 -SessionOption $SessionOptions -ErrorAction Stop
        
        $Monitors = Get-CimInstance -ClassName WmiMonitorID -Namespace root\wmi -CimSession $Session -ErrorAction Stop |
            Where-Object { $_.UserFriendlyNameLength -ne 0 }

        if (-not $Monitors) {
            Write-Log "No external monitors detected" -Level WARN
            Write-Log "This system may only have built-in displays" -Level INFO
            
            if ($CustomFieldName) {
                Ninja-Property-Set -Name $CustomFieldName -Value "No external monitors detected"
            }
            
            $script:ExitCode = 0
            return
        }

        $script:MonitorCount = ($Monitors | Measure-Object).Count
        Write-Log "Found $script:MonitorCount attached monitor(s)" -Level SUCCESS

        $Output = "Monitor Name, Serial Number, Year of Manufacture`n"
        $MonitorDetails = @()

        foreach ($Monitor in $Monitors) {
            $SerialNumber = ($Monitor.SerialNumberID -ne 0 | ForEach-Object { [char]$_ }) -join ""
            $MonitorName = ($Monitor.UserFriendlyName -ne 0 | ForEach-Object { [char]$_ }) -join ""
            $Year = $Monitor.YearOfManufacture

            $Output += "$MonitorName, $SerialNumber, $Year`n"
            
            $MonitorDetails += [PSCustomObject]@{
                'Monitor Name' = $MonitorName
                'Serial Number' = $SerialNumber
                'Year of Manufacture' = $Year
            }
            
            Write-Log "Monitor: $MonitorName (SN: $SerialNumber, Year: $Year)" -Level DEBUG
        }

        Write-Output "`n### Attached Monitors ###"
        $MonitorDetails | ForEach-Object {
            Write-Output "Monitor Name: $($_.'Monitor Name')"
            Write-Output "Serial Number: $($_.'Serial Number')"
            Write-Output "Year of Manufacture: $($_.'Year of Manufacture')"
            Write-Output ""
        }

        if ($CustomFieldName) {
            Write-Log "Saving monitor data to custom field '$CustomFieldName'" -Level INFO
            Ninja-Property-Set -Name $CustomFieldName -Value $Output.Trim()
            Write-Log "Monitor data saved successfully" -Level SUCCESS
        }
        
        Write-Log "Monitor query completed successfully" -Level SUCCESS
    }
    catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:ExitCode = 1
    }
    finally {
        if ($Session) {
            Write-Log "Cleaning up CIM session" -Level DEBUG
            Remove-CimSession -CimSession $Session -ErrorAction SilentlyContinue
        }
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
        Write-Log "  Monitors Found: $script:MonitorCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        
        exit $script:ExitCode
    }
}
