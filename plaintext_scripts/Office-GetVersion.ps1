#Requires -Version 5.1

<#
.SYNOPSIS
    Detects installed Microsoft Office version and update channel.

.DESCRIPTION
    This script queries the registry to determine which version of Microsoft Office is installed, 
    including the specific build number, update channel, and product edition (e.g., Office 365 
    ProPlus, Office 2019, Office 2016). This information is critical for patch management, 
    compatibility planning, and software inventory.
    
    The script detects:
    - Office version (2016, 2019, 2021, 365)
    - Build number and release ID
    - Update channel (Monthly, Semi-Annual, etc.)
    - Installation type (Click-to-Run vs MSI)
    - Product edition and licensing

.PARAMETER SaveToCustomField
    Name of a custom field to save the Office version information.

.EXAMPLE
    .\Office-GetVersion.ps1

    [2026-02-10 01:52:15] [INFO] Detecting Microsoft Office installation...
    [2026-02-10 01:52:15] [INFO] Office Version: Microsoft 365 Apps for Enterprise
    [2026-02-10 01:52:15] [INFO] Build: 16.0.14332.20447
    [2026-02-10 01:52:15] [INFO] Update Channel: Monthly Enterprise Channel
    [2026-02-10 01:52:15] [INFO] Installation Type: Click-to-Run

.EXAMPLE
    .\Office-GetVersion.ps1 -SaveToCustomField "OfficeVersion"

    [2026-02-10 01:52:15] [INFO] Detecting Microsoft Office installation...
    [2026-02-10 01:52:15] [INFO] Office Version: Office Professional Plus 2019
    [2026-02-10 01:52:15] [INFO] Build: 16.0.10392.20029
    [2026-02-10 01:52:15] [SUCCESS] Results saved to custom field 'OfficeVersion'

.OUTPUTS
    System.Int32
    Exit code: 0 for success, 1 for failure

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes:
    (v3.0.0) 2026-02-10 - Upgraded to script-scoped exit code handling
    (v3.0) 2026-02-10 - Upgraded to V3 standards: Write-Log function, execution tracking, enhanced error handling
    (v2.0) 2025-12-01 - Initial release for WAF v2.0
    
.COMPONENT
    Registry - Windows Registry queries
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Detects Microsoft Office installations
    - Identifies Office version (2016, 2019, 2021, 365)
    - Reports build number and release information
    - Determines update channel configuration
    - Distinguishes Click-to-Run vs MSI installations
    - Reports product edition and licensing type
    - Can save version information to custom fields
    - Useful for software inventory and patch management
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SaveToCustomField
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    Set-StrictMode -Version Latest
    
    $startTime = Get-Date
    $script:exitCode = 0

    function Write-Log {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG')]
            [string]$Level = 'INFO'
        )
        
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR'   { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default   { Write-Host $logMessage }
        }
    }

    function Set-NinjaField {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$FieldName,
            
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [AllowEmptyString()]
            [AllowNull()]
            $Value
        )
        
        process {
            try {
                Write-Log "Setting custom field '$FieldName' to: $Value" -Level DEBUG
                $result = $Value | Ninja-Property-Set-Piped -Name $FieldName 2>&1
                
                if ($result.Exception) {
                    throw $result.Exception
                }
                
                Write-Log "Successfully set custom field '$FieldName'" -Level DEBUG
                return $true
            }
            catch {
                Write-Log "Primary method failed, attempting CLI fallback for field '$FieldName'" -Level DEBUG
                
                try {
                    $cliPath = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
                    
                    if (Test-Path $cliPath) {
                        $process = Start-Process -FilePath $cliPath -ArgumentList "set", $FieldName, $Value -NoNewWindow -Wait -PassThru
                        
                        if ($process.ExitCode -eq 0) {
                            Write-Log "Successfully set custom field '$FieldName' via CLI" -Level DEBUG
                            return $true
                        }
                        else {
                            throw "CLI process exited with code $($process.ExitCode)"
                        }
                    }
                    else {
                        throw "NinjaRMM CLI not found at $cliPath"
                    }
                }
                catch {
                    Write-Log "Failed to set custom field '$FieldName': $($_.Exception.Message)" -Level ERROR
                    return $false
                }
            }
        }
    }

    function Get-OfficeVersion {
        [CmdletBinding()]
        param()
        
        $officeInfo = @{
            Version     = "Not Installed"
            Build       = ""
            Channel     = ""
            InstallType = ""
        }

        $c2rPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        $c2r64Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
        
        $c2rExists = Test-Path -Path $c2rPath -ErrorAction SilentlyContinue
        $c2r64Exists = Test-Path -Path $c2r64Path -ErrorAction SilentlyContinue

        if ($c2rExists -or $c2r64Exists) {
            $configPath = if ($c2rExists) { $c2rPath } else { $c2r64Path }
            Write-Log "Found Click-to-Run installation at: $configPath" -Level DEBUG
            
            try {
                $versionInfo = Get-ItemProperty -Path $configPath -ErrorAction SilentlyContinue
                
                if ($versionInfo.VersionToReport) {
                    $officeInfo.Build = $versionInfo.VersionToReport
                    
                    $majorVersion = $versionInfo.VersionToReport.Split('.')[0]
                    switch ($majorVersion) {
                        "16" {
                            $buildNumber = [int]$versionInfo.VersionToReport.Split('.')[2]
                            if ($buildNumber -ge 13000) {
                                $officeInfo.Version = "Microsoft 365 Apps"
                            }
                            elseif ($buildNumber -ge 10000) {
                                $officeInfo.Version = "Office 2019"
                            }
                            else {
                                $officeInfo.Version = "Office 2016"
                            }
                        }
                        "15" { $officeInfo.Version = "Office 2013" }
                        default { $officeInfo.Version = "Office (Build $majorVersion)" }
                    }
                }
                
                if ($versionInfo.ProductReleaseIds) {
                    $productId = $versionInfo.ProductReleaseIds
                    if ($productId -match "O365") {
                        $officeInfo.Version = "Microsoft 365 Apps for Enterprise"
                    }
                    elseif ($productId -match "ProPlus") {
                        $officeInfo.Version = "Office Professional Plus $($officeInfo.Version -replace 'Office ')"
                    }
                    elseif ($productId -match "Business") {
                        $officeInfo.Version = "Microsoft 365 Apps for Business"
                    }
                }
                
                if ($versionInfo.UpdateChannel) {
                    $channel = $versionInfo.UpdateChannel
                    switch -Regex ($channel) {
                        "Current"  { $officeInfo.Channel = "Current Channel" }
                        "Monthly"  { $officeInfo.Channel = "Monthly Enterprise Channel" }
                        "Broad"    { $officeInfo.Channel = "Semi-Annual Enterprise Channel" }
                        "Targeted" { $officeInfo.Channel = "Semi-Annual Enterprise Channel (Preview)" }
                        "Deferred" { $officeInfo.Channel = "Semi-Annual Enterprise Channel" }
                        default    { $officeInfo.Channel = "Unknown Channel ($channel)" }
                    }
                }
                
                $officeInfo.InstallType = "Click-to-Run"
            }
            catch {
                Write-Log "Failed to read Click-to-Run registry: $($_.Exception.Message)" -Level WARNING
            }
        }
        
        if ($officeInfo.Version -eq "Not Installed") {
            Write-Log "Click-to-Run installation not found, checking for MSI installation" -Level DEBUG
            
            $msiPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot",
                "HKLM:\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Common\InstallRoot",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\Common\InstallRoot"
            )
            
            foreach ($path in $msiPaths) {
                if (Test-Path -Path $path -ErrorAction SilentlyContinue) {
                    try {
                        $installRoot = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                        if ($installRoot.Path) {
                            Write-Log "Found MSI installation at: $path" -Level DEBUG
                            
                            $version = $path -replace '.*Office\\([0-9.]+)\\.*', '$1'
                            switch ($version) {
                                "16.0" { $officeInfo.Version = "Office 2016" }
                                "15.0" { $officeInfo.Version = "Office 2013" }
                            }
                            $officeInfo.InstallType = "MSI"
                            break
                        }
                    }
                    catch {
                        Write-Log "Failed to read MSI path $path : $($_.Exception.Message)" -Level DEBUG
                        continue
                    }
                }
            }
        }

        return $officeInfo
    }

    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
        Write-Log "Custom field parameter from environment: $SaveToCustomField" -Level DEBUG
    }
}

process {
    try {
        Write-Log "Detecting Microsoft Office installation..."
        
        $officeInfo = Get-OfficeVersion

        if ($officeInfo.Version -eq "Not Installed") {
            Write-Log "Microsoft Office is not installed on this system"
            $script:exitCode = 0
        }
        else {
            Write-Log "Office Version: $($officeInfo.Version)"
            $report = "Version: $($officeInfo.Version)"
            
            if ($officeInfo.Build) {
                Write-Log "Build: $($officeInfo.Build)"
                $report += " | Build: $($officeInfo.Build)"
            }
            
            if ($officeInfo.Channel) {
                Write-Log "Update Channel: $($officeInfo.Channel)"
                $report += " | Channel: $($officeInfo.Channel)"
            }
            
            if ($officeInfo.InstallType) {
                Write-Log "Installation Type: $($officeInfo.InstallType)"
                $report += " | Type: $($officeInfo.InstallType)"
            }

            if ($SaveToCustomField) {
                Write-Log "Attempting to save results to custom field: $SaveToCustomField" -Level DEBUG
                
                $success = $report | Set-NinjaField -FieldName $SaveToCustomField
                
                if ($success) {
                    Write-Log "Results saved to custom field '$SaveToCustomField'" -Level SUCCESS
                }
                else {
                    Write-Log "Failed to save to custom field '$SaveToCustomField'" -Level WARNING
                    $script:exitCode = 1
                }
            }
            
            $script:exitCode = 0
        }
    }
    catch {
        Write-Log "Failed to detect Office version: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        $script:exitCode = 1
    }
}

end {
}

finally {
    $duration = (Get-Date) - $startTime
    Write-Log "Script execution completed in $($duration.TotalSeconds) seconds" -Level DEBUG
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $exitCode
}
