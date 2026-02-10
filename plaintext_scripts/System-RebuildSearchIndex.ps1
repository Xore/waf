#Requires -Version 5.1 -RunAsAdministrator

<#
.SYNOPSIS
    Rebuilds the Windows Search Index by deleting existing index files and forcing recreation.

.DESCRIPTION
    This script stops the Windows Search service, removes existing search index database files, 
    resets the setup completion registry flag, and restarts the service to force a complete 
    index rebuild. This resolves issues with corrupted search indexes or incomplete search results.
    
    Index corruption can cause Windows Search to return incomplete or incorrect results. Rebuilding 
    the index removes all cached data and forces Windows to re-crawl and re-index all configured 
    locations, typically completing within several hours depending on data volume.

.EXAMPLE
    No Parameters

    [Info] Stopping Windows Search service...
    [Info] Successfully stopped Windows Search service
    [Info] Removing search index files from: C:\ProgramData\Microsoft\Search\Data\Applications\Windows
    [Info] Resetting search setup completion flag
    [Info] Starting Windows Search service...
    [Info] Successfully started Windows Search service
    [Info] Windows Search Index rebuild initiated

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: v3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
    User interaction: None - fully automated process
    Restart behavior: N/A - Service restart only, no system reboot
    Typical duration: 5-15 seconds to initiate (rebuild takes hours in background)
    
.COMPONENT
    Windows Search Service (wsearch)
    
.LINK
    https://learn.microsoft.com/en-us/windows/win32/search/-search-3x-wds-overview

.FUNCTIONALITY
    - Validates Windows Search service exists and is not disabled
    - Stops Windows Search service with retry logic (up to 4 attempts)
    - Deletes .db and .edb index files from search data directory
    - Resets SetupCompletedSuccessfully registry flag to force rebuild
    - Restarts Windows Search service with retry logic
    - Validates service state transitions before proceeding
#>

[CmdletBinding()]
param ()

begin {
    $MaxAttempts = 4
    $AttemptDelay = 1

    if (-not (Get-Service -Name "wsearch" -ErrorAction SilentlyContinue)) {
        Write-Host "[Error] Windows Search service does not exist. Nothing to rebuild"
        exit 1
    }

    $StartType = Get-Service -Name "wsearch" | Select-Object -ExpandProperty StartType
    if ($StartType -eq "Disabled") {
        Write-Host "[Error] Windows Search service is disabled. Enable the service before rebuilding"
        exit 1
    }

    function Set-RegKey {
        [CmdletBinding()]
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )

        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        if (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "[Error] Unable to set registry key for $Name: $($_.Message)"
                exit 1
            }
            Write-Host "[Info] $Path\$Name changed from $CurrentValue to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
        else {
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "[Error] Unable to set registry key for $Name: $($_.Exception.Message)"
                exit 1
            }
            Write-Host "[Info] Set $Path\$Name to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    $script:ExitCode = 0
}

process {
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges"
        exit 1
    }

    Write-Host "[Info] Stopping Windows Search service..."
    $Attempt = 1
    do {
        try {
            Write-Host "[Info] Attempt $Attempt of $MaxAttempts"
            Get-Service -Name "wsearch" | Stop-Service -ErrorAction Stop
        }
        catch {
            Write-Host "[Warn] Failed to stop service: $($_.Exception.Message)"
        }

        Start-Sleep -Seconds $AttemptDelay
        $Status = Get-Service -Name "wsearch" | Select-Object -ExpandProperty Status
        $Attempt++
    } while ($Status -ne "Stopped" -and $Attempt -le $MaxAttempts)

    if ($Status -ne "Stopped") {
        Write-Host "[Error] Windows Search service failed to stop after $MaxAttempts attempts"
        Get-Service -Name "wsearch" | Format-Table | Out-String | Write-Host
        exit 1
    }
    Write-Host "[Info] Successfully stopped Windows Search service"

    $SearchDataPath = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows"
    Write-Host "[Info] Removing search index files from: $SearchDataPath"
    
    try {
        Get-ChildItem -Path $SearchDataPath -File -Filter "*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -Confirm:$false
        Get-ChildItem -Path $SearchDataPath -File -Filter "*.edb" -ErrorAction SilentlyContinue | Remove-Item -Force -Confirm:$false
        Write-Host "[Info] Search index files removed successfully"
    }
    catch {
        Write-Host "[Warn] Some index files could not be removed: $_"
    }

    Write-Host "[Info] Resetting search setup completion flag"
    Set-RegKey -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Search" -Name "SetupCompletedSuccessfully" -Value 0

    Write-Host "[Info] Starting Windows Search service..."
    $Attempt = 1
    do {
        Start-Sleep -Seconds $AttemptDelay

        try {
            Write-Host "[Info] Attempt $Attempt of $MaxAttempts"
            Get-Service -Name "wsearch" | Start-Service -ErrorAction Stop
        }
        catch {
            Write-Host "[Warn] Failed to start service: $($_.Exception.Message)"
        }

        $Attempt++
        $Status = Get-Service -Name "wsearch" | Select-Object -ExpandProperty Status
    } while ($Status -ne "Running" -and $Attempt -le $MaxAttempts)

    if ($Status -ne "Running") {
        Write-Host "[Error] Windows Search service failed to start after $MaxAttempts attempts"
        Get-Service -Name "wsearch" | Format-Table | Out-String | Write-Host
        exit 1
    }
    
    Write-Host "[Info] Successfully started Windows Search service"
    Write-Host "[Info] Windows Search Index rebuild initiated. This process will continue in the background and may take several hours to complete."

    exit $script:ExitCode
}

end {
}
