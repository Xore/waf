#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Installs or updates Sysmon with configuration.
.DESCRIPTION
    Downloads Sysmon executables and installs Sysmon64.exe with a configuration file.
    If Sysmon is already installed, updates the configuration.
.EXAMPLE
    No parameters needed
    Installs or updates Sysmon with configuration.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param ()

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

    $ServiceName = 'Sysmon64'
    $Path = $env:TEMP
    $SysmonConfigUrl = 'https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml'
}

process {
    if (-not (Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    try {
        if (-not (Test-Path $Path)) {
            Write-Log "Creating temporary directory: $Path"
            New-Item -ItemType Directory -Force -Path $Path | Out-Null
        }

        Set-Location $Path

        $SysmonService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($SysmonService -and $SysmonService.Status -eq 'Running') {
            Write-Log "Sysmon is already installed. Updating configuration..."
            Invoke-WebRequest -Uri $SysmonConfigUrl -OutFile sysmonconfig-export.xml -UseBasicParsing
            Start-Process -NoNewWindow -FilePath "$env:SystemRoot\sysmon64.exe" -ArgumentList "-c sysmonconfig-export.xml" -Wait
            Write-Log "Configuration updated successfully"
            exit 0
        }

        Write-Log "Cleaning up old files..."
        if (Test-Path "$Path\sysmon.zip") {
            Remove-Item "$Path\sysmon.zip" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$Path\sysmon") {
            Remove-Item "$Path\sysmon" -Force -Recurse -ErrorAction SilentlyContinue
        }

        Write-Log "Downloading Sysmon..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri https://download.sysinternals.com/files/Sysmon.zip -OutFile Sysmon.zip -UseBasicParsing

        Write-Log "Extracting Sysmon archive..."
        Expand-Archive Sysmon.zip -Force

        Set-Location "$Path\Sysmon"

        Write-Log "Downloading configuration file..."
        Invoke-WebRequest -Uri $SysmonConfigUrl -OutFile sysmonconfig-export.xml -UseBasicParsing

        Write-Log "Installing Sysmon..."
        Start-Process -NoNewWindow -FilePath ".\sysmon64.exe" -ArgumentList "-accepteula -i sysmonconfig-export.xml" -Wait

        $SysmonInstalled = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($SysmonInstalled) {
            Write-Log "Sysmon installed successfully"
        }
        else {
            Write-Log "Sysmon installation verification failed" -Level Error
            exit 1
        }
    }
    catch {
        Write-Log "Failed to install Sysmon: $_" -Level Error
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
