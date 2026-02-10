#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Reports Credential Guard status.
.DESCRIPTION
    Reports whether Credential Guard is configured and running on the device.
.PARAMETER TextCustomFieldName
    Name of the text custom field where Credential Guard information will be stored.
.EXAMPLE
    No parameters
    Reports Credential Guard configuration and running status.
.EXAMPLE
    -TextCustomFieldName "CredGuardStatus"
    Reports status and stores in custom field.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$TextCustomFieldName
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

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter()]
            [String]$Type,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        try {
            $Value | Ninja-Property-Set -Name $Name 2>&1 | Out-Null
        }
        catch {
            throw "Failed to set custom field: $_"
        }
    }

    function Test-IsCredentialGuardRunning {
        if ($PSVersionTable.PSVersion.Major -lt 3) {
            $CGRunning = (Get-WmiObject -Class Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue).SecurityServicesRunning
        }
        else {
            $CGRunning = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue).SecurityServicesRunning
        }
        return ($CGRunning -contains 1)
    }

    if ($env:TextCustomFieldName -and $env:TextCustomFieldName -ne 'null') {
        $TextCustomFieldName = $env:TextCustomFieldName
    }
}

process {
    if (-not (Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    try {
        $OS = if ($PSVersionTable.PSVersion.Major -lt 3) {
            Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        }
        else {
            Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        }

        $SupportedOS = $true

        if ($OS.Caption -match "Windows (10|11)" -and $OS.Caption -notmatch "Enterprise|Education") {
            $RegKeyValue = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\" -ErrorAction SilentlyContinue).IsolatedCredentialsRootSecret
            if ([string]::IsNullOrWhiteSpace($RegKeyValue)) {
                $SupportedOS = $false
            }
        }
        elseif ($OS.Caption -notmatch "Windows.+(Enterprise|Education|Server (2016|2019|[2-9]0[2-9][0-9]))") {
            $SupportedOS = $false
        }

        if (-not $SupportedOS) {
            Write-Log "Credential Guard is not supported on this OS" -Level Error
            Write-Log "Supported: Windows 10/11 Enterprise/Education, Windows Server 2016+"
            
            if ($TextCustomFieldName) {
                try {
                    Write-Log "Setting custom field $TextCustomFieldName to 'Incompatible with System'"
                    Set-NinjaProperty -Name $TextCustomFieldName -Type "Text" -Value "Incompatible with System"
                }
                catch {
                    Write-Log "Failed to set custom field: $_" -Level Error
                }
            }
            exit 1
        }

        $CGRunningStatus = if (Test-IsCredentialGuardRunning) { "Running" } else { "Not running" }

        $CGConfiguration = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" -ErrorAction Stop).LsaCfgFlags
        if ($null -eq $CGConfiguration) {
            $CGConfiguration = (Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" -ErrorAction Stop).LsaCfgFlagsDefault
        }

        $CGConfigurationStatus = switch ($CGConfiguration) {
            0 { "Disabled" }
            1 { "Enabled with UEFI lock" }
            2 { "Enabled without UEFI lock" }
            default { "Unable to Determine" }
        }

        if ($TextCustomFieldName) {
            $Value = "$CGConfigurationStatus | $CGRunningStatus"
            try {
                Write-Log "Setting custom field $TextCustomFieldName to '$Value'"
                Set-NinjaProperty -Name $TextCustomFieldName -Type "Text" -Value $Value
            }
            catch {
                Write-Log "Failed to set custom field: $_" -Level Error
            }
        }

        if ($CGConfigurationStatus -eq "Disabled" -and $CGRunningStatus -eq "Running") {
            Write-Log "Credential Guard is disabled in registry but currently running" -Level Warning
            Write-Log "Restart may be needed or Credential Guard is UEFI locked"
        }

        Write-Log "Configuration: $CGConfigurationStatus | Running: $CGRunningStatus"
        
        [PSCustomObject]@{
            "CredentialGuardConfiguration" = $CGConfigurationStatus
            "CredentialGuardRunning"        = $CGRunningStatus
        } | Format-Table -AutoSize | Out-String | Write-Host
    }
    catch {
        Write-Log "Failed to check Credential Guard status: $_" -Level Error
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
