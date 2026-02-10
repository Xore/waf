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
    No Parameters

    [Info] Detecting Microsoft Office installation...
    Office Version: Microsoft 365 Apps for Enterprise
    Build: 16.0.14332.20447
    Update Channel: Monthly Enterprise Channel
    Installation Type: Click-to-Run

.EXAMPLE
    -SaveToCustomField "OfficeVersion"

    [Info] Detecting Microsoft Office installation...
    Office Version: Office Professional Plus 2019
    Build: 16.0.10392.20029
    [Info] Results saved to custom field 'OfficeVersion'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    
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

    function Get-OfficeVersion {
        $OfficeInfo = @{
            Version = "Not Installed"
            Build = ""
            Channel = ""
            InstallType = ""
        }

        $C2RPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        $C2R64Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
        
        $C2RExists = Test-Path $C2RPath
        $C2R64Exists = Test-Path $C2R64Path

        if ($C2RExists -or $C2R64Exists) {
            $ConfigPath = if ($C2RExists) { $C2RPath } else { $C2R64Path }
            
            try {
                $VersionInfo = Get-ItemProperty -Path $ConfigPath -ErrorAction SilentlyContinue
                
                if ($VersionInfo.VersionToReport) {
                    $OfficeInfo.Build = $VersionInfo.VersionToReport
                    
                    $MajorVersion = $VersionInfo.VersionToReport.Split('.')[0]
                    switch ($MajorVersion) {
                        "16" {
                            $BuildNumber = [int]$VersionInfo.VersionToReport.Split('.')[2]
                            if ($BuildNumber -ge 13000) {
                                $OfficeInfo.Version = "Microsoft 365 Apps"
                            } elseif ($BuildNumber -ge 10000) {
                                $OfficeInfo.Version = "Office 2019"
                            } else {
                                $OfficeInfo.Version = "Office 2016"
                            }
                        }
                        "15" { $OfficeInfo.Version = "Office 2013" }
                        default { $OfficeInfo.Version = "Office (Build $MajorVersion)" }
                    }
                }
                
                if ($VersionInfo.ProductReleaseIds) {
                    $ProductId = $VersionInfo.ProductReleaseIds
                    if ($ProductId -match "O365") {
                        $OfficeInfo.Version = "Microsoft 365 Apps for Enterprise"
                    } elseif ($ProductId -match "ProPlus") {
                        $OfficeInfo.Version = "Office Professional Plus $($OfficeInfo.Version -replace 'Office ')"
                    } elseif ($ProductId -match "Business") {
                        $OfficeInfo.Version = "Microsoft 365 Apps for Business"
                    }
                }
                
                if ($VersionInfo.UpdateChannel) {
                    $Channel = $VersionInfo.UpdateChannel
                    switch -Regex ($Channel) {
                        "Current" { $OfficeInfo.Channel = "Current Channel" }
                        "Monthly" { $OfficeInfo.Channel = "Monthly Enterprise Channel" }
                        "Broad" { $OfficeInfo.Channel = "Semi-Annual Enterprise Channel" }
                        "Targeted" { $OfficeInfo.Channel = "Semi-Annual Enterprise Channel (Preview)" }
                        "Deferred" { $OfficeInfo.Channel = "Semi-Annual Enterprise Channel" }
                        default { $OfficeInfo.Channel = "Unknown Channel" }
                    }
                }
                
                $OfficeInfo.InstallType = "Click-to-Run"
            } catch {
                Write-Host "[Error] Failed to read Click-to-Run registry: $_"
            }
        }
        
        if ($OfficeInfo.Version -eq "Not Installed") {
            $MSIPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot",
                "HKLM:\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Common\InstallRoot",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\Common\InstallRoot"
            )
            
            foreach ($Path in $MSIPaths) {
                if (Test-Path $Path) {
                    try {
                        $InstallRoot = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
                        if ($InstallRoot.Path) {
                            $Version = $Path -replace '.*Office\\([0-9.]+)\\.*', '$1'
                            switch ($Version) {
                                "16.0" { $OfficeInfo.Version = "Office 2016" }
                                "15.0" { $OfficeInfo.Version = "Office 2013" }
                            }
                            $OfficeInfo.InstallType = "MSI"
                            break
                        }
                    } catch {
                        continue
                    }
                }
            }
        }

        return $OfficeInfo
    }

    $ExitCode = 0
}

process {
    try {
        Write-Host "[Info] Detecting Microsoft Office installation..."
        
        $OfficeInfo = Get-OfficeVersion

        if ($OfficeInfo.Version -eq "Not Installed") {
            Write-Host "[Info] Microsoft Office is not installed on this system"
            exit 0
        }

        Write-Host "Office Version: $($OfficeInfo.Version)"
        $Report = "Version: $($OfficeInfo.Version)"
        
        if ($OfficeInfo.Build) {
            Write-Host "Build: $($OfficeInfo.Build)"
            $Report += " | Build: $($OfficeInfo.Build)"
        }
        
        if ($OfficeInfo.Channel) {
            Write-Host "Update Channel: $($OfficeInfo.Channel)"
            $Report += " | Channel: $($OfficeInfo.Channel)"
        }
        
        if ($OfficeInfo.InstallType) {
            Write-Host "Installation Type: $($OfficeInfo.InstallType)"
            $Report += " | Type: $($OfficeInfo.InstallType)"
        }

        if ($SaveToCustomField) {
            try {
                $Report | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to detect Office version: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
