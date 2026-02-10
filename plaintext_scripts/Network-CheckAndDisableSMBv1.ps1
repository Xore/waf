#Requires -Version 5.1

<#
.SYNOPSIS
    Checks for and alerts if SMBv1 is enabled, and optionally disables it if it is enabled. You can also choose to write the status to a custom field.
.DESCRIPTION
    Checks for and alerts if SMBv1 is enabled, and optionally disables it if it is enabled. You can also choose to write the status to a custom field.

.PARAMETER -TextCustomFieldName
    The name of the text custom field to save the SMBv1 status to. If not provided, the script will still produce an alert if SMBv1 is enabled, but will not save the status to a custom field.

.PARAMETER -DisableIfFound
    Disable SMBv1 if it is found to be enabled on the device.

.PARAMETER -ForceRestart
    Force the device to restart after SMBv1 is disabled. This option will also restart the device if SMBv1 was disabled previously but the device has not been restarted yet.

.EXAMPLE
    (No Parameters)

    [Alert] SMBv1 is enabled on this device.

.EXAMPLE
    -DisableIfFound -TextCustomFieldName "SMBv1Status"

    [Alert] SMBv1 is enabled on this device.

    [Info] Disabling SMBv1...
    [Info] Successfully disabled SMBv1.
    [Warning] SMBv1 has been disabled but the device needs to restart to complete the process.

    [Info] Publishing SMBv1 status to the custom field 'SMBv1Status'.
    [Info] Successfully published SMBv1 status to the 'SMBv1Status' custom field.

.EXAMPLE
    -DisableIfFound -TextCustomFieldName "SMBv1Status" -ForceRestart

    [Alert] SMBv1 is enabled on this device.

    [Info] Disabling SMBv1...
    [Info] Successfully disabled SMBv1.

    [Info] Publishing SMBv1 status to the custom field 'SMBv1Status'.
    [Info] Successfully published SMBv1 status to the 'SMBv1Status' custom field.

    [Info] Restarting the device in 1 minute to apply the changes...

.NOTES
    Minimum Supported OS: Windows 10, Windows Server 2016+
    Version: 3.0.0
    Release Notes: v3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$TextCustomFieldName,

    [Parameter()]
    [switch]$DisableIfFound = [System.Convert]::ToBoolean($env:disableIfFound),

    [Parameter()]
    [switch]$ForceRestart = [System.Convert]::ToBoolean($env:forceRestart)
)

begin {
    if ($env:TextCustomFieldName) { $TextCustomFieldName = $env:TextCustomFieldName }

    if ([System.Environment]::OSVersion.Version.Build -lt 10240) {
        Write-Host -Object "`n[Warning] The minimum OS version supported by this script is Windows 10 (10240) or Windows Server 2016 (14393)."
        Write-Host -Object "[Warning] OS build '$([System.Environment]::OSVersion.Version.Build)' detected. This could lead to errors or unexpected results.`n"
    }

    $script:ExitCode = 0

    if ($TextCustomFieldName) {
        if ([string]::IsNullOrWhiteSpace($TextCustomFieldName)) {
            Write-Host -Object "[Error] The value for 'Text Custom Field Name' only contains spaces. Please provide a valid Text custom field name or leave it blank."
            Write-Host -Object "[Error] Writing to the Text custom field will be skipped."
            Write-Host -Object "[Error] https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Field-Setup"
            $TextCustomFieldName = $null
            $script:ExitCode = 1
            Write-Host -Object ""
        }
        else {
            $TextCustomFieldName = $TextCustomFieldName.Trim()

            if ($TextCustomFieldName -match "[^0-9A-Z]") {
                Write-Host -Object "[Error] The value for 'Text Custom Field Name' contains invalid character(s). Please provide a valid Text custom field name."
                Write-Host -Object "[Error] Writing to the Text custom field will be skipped."
                Write-Host -Object "[Error] https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Field-Setup"
                $TextCustomFieldName = $null
                $script:ExitCode = 1
                Write-Host -Object ""
            }
        }
    }

    function Test-IsElevated {
        [CmdletBinding()]
        param ()

        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]'544')
    }
}

process {
    try {
        $IsElevated = Test-IsElevated -ErrorAction Stop
    }
    catch {
        Write-Host -Object "[Error] $($_.Exception.Message)"
        Write-Host -Object "[Error] Unable to determine if the account '$env:Username' is running with Administrator privileges."
        exit 1
    }

    if (!$IsElevated) {
        Write-Host -Object "[Error] Access Denied: The user '$env:Username' does not have administrator privileges, or the script is not running with elevated permissions."
        exit 1
    }

    $restartNeeded = $false

    try {
        $SMBv1Status = (Get-WindowsOptionalFeature -Online -FeatureName smb1protocol -ErrorAction Stop).State
    }
    catch {
        Write-Host -Object "[Error] Error while checking the status of SMBv1."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    switch ($SMBv1Status) {
        "Enabled" {
            Write-Host -Object "[Alert] SMBv1 is enabled on this device."

            if ($DisableIfFound) {
                try {
                    Write-Host -Object "`n[Info] Disabling SMBv1..."
                    Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol -NoRestart -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
                    Write-Host -Object "[Info] Successfully disabled SMBv1."

                    switch ($ForceRestart) {
                        $true {
                            $restartNeeded = $true
                            $SMBv1Status = "Disabled"
                            break
                        }
                        $false {
                            Write-Host -Object "[Warning] SMBv1 has been disabled but the device needs to restart to complete the process."
                            $SMBv1Status = "DisabledPendingRestart"
                            break
                        }
                    }
                }
                catch {
                    Write-Host -Object "[Error] Error while disabling SMBv1."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $script:ExitCode = 1
                }
            }
        }
        "DisablePending" {
            Write-Host -Object "[Info] SMBv1 has been disabled but the device needs to restart to complete the process."

            switch ($ForceRestart) {
                $true {
                    $restartNeeded = $true
                    $SMBv1Status = "Disabled"
                    break
                }
                $false {
                    Write-Host -Object "[Info] Please restart the device manually to fully disable SMBv1."
                    $SMBv1Status = "DisabledPendingRestart"
                    break
                }
            }
        }
        "Disabled" {
            Write-Host -Object "[Info] SMBv1 is not enabled on this device."
        }
        default {
            Write-Host -Object "[Error] SMBv1 has an unknown status: $SMBv1Status"
            $script:ExitCode = 1
        }
    }

    if ($TextCustomFieldName) {
        try {
            $CustomFieldValue = "SMBv1 $SMBv1Status"
            Write-Host -Object "`n[Info] Publishing SMBv1 status to the custom field '$TextCustomFieldName'."
            Set-NinjaProperty -Name $TextCustomFieldName -Value $CustomFieldValue -ErrorAction Stop
            Write-Host -Object "[Info] Successfully published SMBv1 status to the '$TextCustomFieldName' custom field."
        }
        catch {
            Write-Host -Object "[Error] Error while publishing the SMBv1 status to the custom field '$TextCustomFieldName'."
            Write-Host -Object "[Error] $($_.Exception.Message)"
            $script:ExitCode = 1
        }
    }

    if ($ForceRestart -and $restartNeeded) {
        Write-Host -Object "`n[Info] Restarting the device in 1 minute to apply the changes..."
        shutdown.exe -r -t 60
    }

    exit $script:ExitCode
}

end {
    
}
