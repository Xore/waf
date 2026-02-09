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
    Version: 2.0
    Release Notes: Script now functions as an alert/audit for SMBv1. Added support for custom field output.
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
    # Import the custom field name from the script variable
    if ($env:TextCustomFieldName) { $TextCustomFieldName = $env:TextCustomFieldName }

    # Check if the operating system build version is less than 10240 (Windows 10 or Windows Server 2016 minimum requirement)
    if ([System.Environment]::OSVersion.Version.Build -lt 10240) {
        Write-Host -Object "`n[Warning] The minimum OS version supported by this script is Windows 10 (10240) or Windows Server 2016 (14393)."
        Write-Host -Object "[Warning] OS build '$([System.Environment]::OSVersion.Version.Build)' detected. This could lead to errors or unexpected results.`n"
    }

    # Initialize the exit code variable
    $ExitCode = 0

    # Validate TextCustomFieldName
    if ($TextCustomFieldName) {
        if ([string]::IsNullOrWhiteSpace($TextCustomFieldName)) {
            Write-Host -Object "[Error] The value for 'Text Custom Field Name' only contains spaces. Please provide a valid Text custom field name or leave it blank."
            Write-Host -Object "[Error] Writing to the Text custom field will be skipped."
            Write-Host -Object "[Error] https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Field-Setup"
            $TextCustomFieldName = $null
            $ExitCode = 1
            Write-Host -Object ""
        }
        else {
            # Trim the Text Custom Field Name to remove leading and trailing whitespace
            $TextCustomFieldName = $TextCustomFieldName.Trim()

            # Skip writing to the Text custom field if it contains invalid characters
            if ($TextCustomFieldName -match "[^0-9A-Z]") {
                Write-Host -Object "[Error] The value for 'Text Custom Field Name' contains invalid character(s). Please provide a valid Text custom field name."
                Write-Host -Object "[Error] Writing to the Text custom field will be skipped."
                Write-Host -Object "[Error] https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Field-Setup"
                $TextCustomFieldName = $null
                $ExitCode = 1
                Write-Host -Object ""
            }
        }
    }

    function Test-IsElevated {
        [CmdletBinding()]
        param ()

        # Get the current Windows identity of the user running the script
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()

        # Create a WindowsPrincipal object based on the current identity
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)

        # Check if the current user is in the Administrator role
        # The function returns $True if the user has administrative privileges, $False otherwise
        # 544 is the value for the Built In Administrators role
        # Reference: https://learn.microsoft.com/en-us/dotnet/api/system.security.principal.windowsbuiltinrole
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]'544')
    }
}
process {
    # Attempt to determine if the current session is running with Administrator privileges.
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

    # Initialize the restart needed flag
    $restartNeeded = $false

    # Get the status of SMBv1
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
            # If SMBv1 is enabled, alert the user
            Write-Host -Object "[Alert] SMBv1 is enabled on this device."

            # If DisableIfFound is set, attempt to disable SMBv1
            if ($DisableIfFound) {
                try {
                    Write-Host -Object "`n[Info] Disabling SMBv1..."
                    Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol -NoRestart -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
                    Write-Host -Object "[Info] Successfully disabled SMBv1."

                    # If Force Restart is used, set the restart needed flag and update the SMBv1 status
                    # Otherwise, let the user know that a restart is required to complete the process
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
                    $ExitCode = 1
                }
            }
        }
        "DisablePending" {
            # This status means that SMBv1 was disabled previously but the device has not yet been restarted
            Write-Host -Object "[Info] SMBv1 has been disabled but the device needs to restart to complete the process."

            # If Force Restart is used, set the restart needed flag and update the SMBv1 status
            # Otherwise, let the user know that a restart is required to complete the process
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
            $ExitCode = 1
        }
    }

    # Save the SMBv1 status to a text custom field
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
            $ExitCode = 1
        }
    }

    # Restart the device only if it was requested and is needed
    if ($ForceRestart -and $restartNeeded) {
        Write-Host -Object "`n[Info] Restarting the device in 1 minute to apply the changes..."
        shutdown.exe -r -t 60
    }

    exit $ExitCode
}
end {
    
    
    
}