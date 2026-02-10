#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Discovers and reports all mapped network drives across user profiles

.DESCRIPTION
    Scans registry for mapped network drives across all user profiles and reports
    the mappings with associated usernames, drive letters, and UNC paths.
    
    The script performs the following:
    - Scans HKEY_USERS registry for network drive mappings
    - Translates SIDs to usernames
    - Compiles list of all mapped drives per user
    - Reports findings to NinjaRMM custom field
    - Handles cases with no mapped drives
    
    This script runs unattended without user interaction.

.PARAMETER CustomField
    Name of NinjaRMM custom field to store mapped drive report.
    Default: "networkDrives"

.PARAMETER OutputFormat
    Format for output display.
    Valid values: List, Table
    Default: List

.EXAMPLE
    .\Network-MapDrives.ps1
    
    Scans for mapped drives and reports to default field.

.EXAMPLE
    .\Network-MapDrives.ps1 -CustomField "mappedDrives"
    
    Scans and reports to specified custom field.

.EXAMPLE
    .\Network-MapDrives.ps1 -OutputFormat Table
    
    Displays results in table format.

.NOTES
    File Name      : Network-MapDrives.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced registry scanning and error handling
    - 2.0: Added NinjaRMM integration
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: Daily or on-demand
    Typical Duration: 1-3 seconds
    Timeout Setting: 30 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    NinjaRMM Fields Updated:
        - networkDrives (or CustomField) - Mapped drive report
        - mappedDrivesStatus (Success/NoDrives/Failed)
        - mappedDrivesCount (number of drives found)
        - mappedDrivesDate (timestamp)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Registry access permissions
    
    Environment Variables (Optional):
        - customFieldName: Override -CustomField parameter
        - outputFormat: Override -OutputFormat parameter
    
    Exit Codes:
        0 - Success (scan completed, with or without drives found)
        1 - Failure (registry access denied or script error)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field name for drive report")]
    [ValidateNotNullOrEmpty()]
    [string]$CustomField = "networkDrives",
    
    [Parameter(Mandatory=$false, HelpMessage="Output format for display")]
    [ValidateSet('List','Table')]
    [string]$OutputFormat = 'List'
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Network-MapDrives"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:CLIFallbackCount = 0
    
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

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
        Write-Output "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }

    function Set-NinjaField {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$FieldName,
            [Parameter(Mandatory=$true)]
            [AllowNull()]
            $Value
        )
        
        if ($null -eq $Value -or $Value -eq "") {
            Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
            return
        }
        
        $ValueString = $Value.ToString()
        
        try {
            if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
                Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
                Write-Log "Field '$FieldName' set successfully" -Level DEBUG
                return
            } else {
                throw "Ninja-Property-Set cmdlet not available"
            }
        } catch {
            Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
            
            try {
                if (-not (Test-Path $NinjaRMMCLI)) {
                    throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
                }
                
                $CLIArgs = @("set", $FieldName, $ValueString)
                $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
                }
                
                Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
                $script:CLIFallbackCount++
                
            } catch {
                Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
            }
        }
    }

    function Test-IsElevated {
        $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
        return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:customFieldName -and $env:customFieldName -notlike "null") {
            $CustomField = $env:customFieldName
            Write-Log "Using custom field from environment: $CustomField" -Level INFO
        }
        
        if ($env:outputFormat -and $env:outputFormat -notlike "null") {
            $OutputFormat = $env:outputFormat
            Write-Log "Using output format from environment: $OutputFormat" -Level INFO
        }
        
        Write-Log "Output format: $OutputFormat" -Level INFO
        
        if (-not (Test-IsElevated)) {
            throw "Administrator privileges required to access user registry hives"
        }
        Write-Log "Administrator privileges verified" -Level INFO
        
        Write-Log "Scanning registry for mapped network drives" -Level INFO
        
        try {
            $RegistryDrives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*" -ErrorAction Stop
        } catch {
            Write-Log "No mapped drives found in registry" -Level INFO
            $RegistryDrives = $null
        }
        
        if ($RegistryDrives) {
            Write-Log "Processing mapped drive entries" -Level INFO
            
            $MappedDrives = foreach ($Drive in $RegistryDrives) {
                try {
                    $SID = ($Drive.PSParentPath -split '\\')[2]
                    Write-Log "Processing drive for SID: $SID" -Level DEBUG
                    
                    try {
                        $Username = ([System.Security.Principal.SecurityIdentifier]$SID).Translate([System.Security.Principal.NTAccount]).Value
                    } catch {
                        Write-Log "Failed to translate SID $SID to username" -Level WARN
                        $Username = $SID
                    }
                    
                    [PSCustomObject]@{
                        Username    = $Username
                        DriveLetter = $Drive.PSChildName
                        RemotePath  = $Drive.RemotePath
                        SID         = $SID
                    }
                    
                    Write-Log "Found drive: $Username - $($Drive.PSChildName) -> $($Drive.RemotePath)" -Level INFO
                    
                } catch {
                    Write-Log "Error processing drive entry: $_" -Level ERROR
                }
            }
            
            if (-not $MappedDrives) {
                Write-Log "No valid mapped drives found after processing" -Level WARN
                
                $ReportText = "No mapped network drives found"
                Set-NinjaField -FieldName $CustomField -Value $ReportText
                Set-NinjaField -FieldName "mappedDrivesStatus" -Value "NoDrives"
                Set-NinjaField -FieldName "mappedDrivesCount" -Value 0
                Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                
                Write-Log $ReportText -Level INFO
                $script:ExitCode = 0
                return
            }
            
            $DriveCount = ($MappedDrives | Measure-Object).Count
            Write-Log "Found $DriveCount mapped network drive(s)" -Level SUCCESS
            
            $OutputText = switch ($OutputFormat) {
                'Table' {
                    $MappedDrives | Sort-Object Username, DriveLetter | Format-Table -AutoSize | Out-String
                }
                'List' {
                    $Lines = foreach ($Drive in ($MappedDrives | Sort-Object Username, DriveLetter)) {
                        "User: $($Drive.Username) - Drive: $($Drive.DriveLetter): - Path: $($Drive.RemotePath)"
                    }
                    $Lines -join "`n"
                }
            }
            
            Write-Log "Mapped Network Drives:" -Level INFO
            Write-Log $OutputText -Level INFO
            
            Set-NinjaField -FieldName $CustomField -Value $OutputText
            Set-NinjaField -FieldName "mappedDrivesStatus" -Value "Success"
            Set-NinjaField -FieldName "mappedDrivesCount" -Value $DriveCount
            Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            Write-Log "Mapped drive report stored in field: $CustomField" -Level SUCCESS
            
        } else {
            Write-Log "No mapped network drives found" -Level INFO
            
            $ReportText = "No mapped network drives found"
            Set-NinjaField -FieldName $CustomField -Value $ReportText
            Set-NinjaField -FieldName "mappedDrivesStatus" -Value "NoDrives"
            Set-NinjaField -FieldName "mappedDrivesCount" -Value 0
            Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            
            Write-Log $ReportText -Level INFO
        }
        
        Write-Log "Mapped drive scan completed successfully" -Level SUCCESS
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        
        Set-NinjaField -FieldName "mappedDrivesStatus" -Value "Failed"
        Set-NinjaField -FieldName "mappedDrivesDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
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
        
        if ($script:CLIFallbackCount -gt 0) {
            Write-Log "CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
        }
        
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
