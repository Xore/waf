#Requires -Version 5.1

<#
.SYNOPSIS
    Removes pre-installed Microsoft Store apps (bloatware) from Windows.

.DESCRIPTION
    This script uninstalls common pre-installed Windows Store applications that are often 
    considered bloatware. It targets non-essential Microsoft apps like Xbox, 3D Builder, 
    Solitaire, and other consumer-focused applications that may not be needed in enterprise 
    or professional environments.
    
    The script uses Get-AppxPackage and Remove-AppxPackage cmdlets to cleanly uninstall 
    these applications for the current user. This can free up disk space and reduce 
    background processes.

.PARAMETER AppList
    Comma-separated list of app package name patterns to remove. Default includes common bloatware.

.EXAMPLE
    No Parameters (removes default bloatware list)

    [Info] Removing Microsoft bloatware applications...
    [Info] Removed: Microsoft.Xbox.TCUI
    [Info] Removed: Microsoft.XboxGamingOverlay
    [Info] Removed: Microsoft.3DBuilder
    [Info] Bloatware removal complete

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    User interaction: None
    Restart behavior: N/A - No restart required
    Typical duration: 10-30 seconds depending on number of apps
    
.COMPONENT
    Appx - Windows Store app management cmdlets
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/appx/remove-appxpackage

.FUNCTIONALITY
    - Enumerates installed Windows Store apps for current user
    - Removes pre-selected bloatware applications
    - Targets Xbox, 3D Builder, Office Hub, Solitaire, and other non-essential apps
    - Uses package name pattern matching for removal
    - Reports successful removals and any errors
#>

[CmdletBinding()]
param(
    [string[]]$AppList = @(
        "*Xbox*",
        "*3DBuilder*",
        "*Solitaire*",
        "*CandyCrush*",
        "*BingNews*",
        "*OneNote*",
        "*People*",
        "*SkypeApp*",
        "*MicrosoftOfficeHub*"
    )
)

begin {
    $ExitCode = 0
    $RemovedCount = 0
}

process {
    try {
        Write-Host "[Info] Scanning for bloatware applications to remove..."

        foreach ($AppPattern in $AppList) {
            $Apps = Get-AppxPackage -Name $AppPattern -ErrorAction SilentlyContinue

            foreach ($App in $Apps) {
                try {
                    Write-Host "[Info] Removing: $($App.Name)"
                    Remove-AppxPackage -Package $App.PackageFullName -ErrorAction Stop
                    Write-Host "[Info] Successfully removed: $($App.Name)"
                    $RemovedCount++
                }
                catch {
                    Write-Host "[Warn] Failed to remove $($App.Name): $_"
                }
            }
        }

        if ($RemovedCount -gt 0) {
            Write-Host "[Info] Bloatware removal complete. Removed $RemovedCount application(s)"
        }
        else {
            Write-Host "[Info] No bloatware applications found to remove"
        }
    }
    catch {
        Write-Host "[Error] Bloatware removal failed: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
