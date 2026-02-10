#Requires -Version 5.1

<#
.SYNOPSIS
    Displays a toast notification to the currently logged-on user.

.DESCRIPTION
    Sends a Windows toast notification to the currently logged-in user.
    The script must be executed as the 'Current Logged on User' context.
    
    Creates or updates registry entries to enable toast notifications for the
    specified ApplicationId. The ApplicationId defaults to NINJA_COMPANY_NAME
    environment variable or 'NinjaOne RMM' if not set.

.PARAMETER Title
    The toast notification title (max 42 characters recommended).

.PARAMETER Message
    The toast notification message body (max 254 characters recommended).

.PARAMETER ApplicationId
    Optional application identifier for the toast notification.
    Defaults to NINJA_COMPANY_NAME environment variable or 'NinjaOne RMM'.

.EXAMPLE
    Notifications-DisplayToastMessage.ps1 -Title "Update Available" -Message "Please restart your computer"
    Displays a toast notification with the specified title and message.

.EXAMPLE
    Notifications-DisplayToastMessage.ps1 -Title "Alert" -Message "System maintenance required" -ApplicationId "MyCompany"
    Displays a toast notification with a custom ApplicationId.

.OUTPUTS
    System.Int32
    Exit code 0 on success, 1 on failure.

.NOTES
    File Name      : Notifications-DisplayToastMessage.ps1
    Prerequisite   : PowerShell 5.1, Windows 10 or higher
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 format with enhanced error handling
    - 1.0: Initial release
    
.LINK
    https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Title,
    
    [Parameter(Mandatory = $false)]
    [string]$Message,
    
    [Parameter(Mandatory = $false)]
    [string]$ApplicationId
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    
    Set-StrictMode -Version Latest

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        
        switch ($Level) {
            'ERROR' { Write-Error $logMessage }
            'WARNING' { Write-Warning $logMessage }
            default { Write-Host $logMessage }
        }
    }

    function Test-IsSystem {
        <#
        .SYNOPSIS
            Checks if the current process is running as SYSTEM.
        #>
        try {
            $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            return ($identity.Name -like 'NT AUTHORITY*' -or $identity.IsSystem)
        }
        catch {
            Write-Log "Failed to determine user context: $_" -Level WARNING
            return $false
        }
    }

    function Set-RegKey {
        <#
        .SYNOPSIS
            Creates or updates a registry key value.
        #>
        param (
            [Parameter(Mandatory = $true)]
            [string]$Path,
            
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true)]
            $Value,
            
            [Parameter(Mandatory = $false)]
            [ValidateSet('DWord', 'QWord', 'String', 'ExpandedString', 'Binary', 'MultiString', 'Unknown')]
            [string]$PropertyType = 'DWord'
        )
        
        try {
            if (-not (Test-Path -Path $Path)) {
                New-Item -Path $Path -Force | Out-Null
                Write-Log "Created registry path: $Path"
            }

            $existingValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            
            if ($existingValue) {
                $currentValue = $existingValue.$Name
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction Stop | Out-Null
                Write-Log "Updated $Path\$Name from '$currentValue' to '$Value'"
            }
            else {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction Stop | Out-Null
                Write-Log "Created $Path\$Name with value '$Value'"
            }
        }
        catch {
            throw "Failed to set registry key $Path\$Name: $_"
        }
    }

    function Show-Notification {
        <#
        .SYNOPSIS
            Displays a Windows toast notification.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [string]$ApplicationId,
            
            [Parameter(Mandatory = $true)]
            [string]$ToastTitle,
            
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [string]$ToastText
        )

        try {
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
            [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
            [Windows.System.User, Windows.System, ContentType = WindowsRuntime] > $null
            [Windows.System.UserType, Windows.System, ContentType = WindowsRuntime] > $null
            [Windows.System.UserAuthenticationStatus, Windows.System, ContentType = WindowsRuntime] > $null
            [Windows.Storage.ApplicationData, Windows.Storage, ContentType = WindowsRuntime] > $null
        }
        catch {
            throw "Failed to load required Windows Runtime libraries: $_"
        }

        try {
            $ToastNotifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($ApplicationId)
        }
        catch {
            throw "Failed to create toast notifier: $_"
        }

        $RawXml = [xml]@"
<toast scenario='urgent'>
    <visual>
        <binding template='ToastGeneric'>
            <text hint-maxLines='1'>$ToastTitle</text>
            <text>$ToastText</text>
        </binding>
    </visual>
</toast>
"@

        $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $SerializedXml.LoadXml($RawXml.OuterXml)

        $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
        $Toast.Tag = 'PowerShell'
        $Toast.Group = 'PowerShell'
        $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

        $ToastNotifier.Show($Toast)
    }
}

process {
    try {
        if (Test-IsSystem) {
            Write-Log "This script must run as 'Current Logged on User', not SYSTEM" -Level ERROR
            exit 1
        }

        if ($env:title -and $env:title -notlike 'null') { $Title = $env:title }
        if ($env:message -and $env:message -notlike 'null') { $Message = $env:message }
        if ($env:applicationId -and $env:applicationId -notlike 'null') { $ApplicationId = $env:applicationId }

        if (-not $ApplicationId) {
            $ApplicationId = if ($env:NINJA_COMPANY_NAME) { $env:NINJA_COMPANY_NAME } else { 'NinjaOne RMM' }
        }

        if ([string]::IsNullOrWhiteSpace($Title)) {
            Write-Log 'Title parameter is required' -Level ERROR
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($Message)) {
            Write-Log 'Message parameter is required' -Level ERROR
            exit 1
        }

        if ($Title.Length -gt 42) {
            Write-Log 'Title exceeds 42 characters and may be truncated by Windows' -Level WARNING
        }

        if ($Message.Length -gt 254) {
            Write-Log 'Message exceeds 254 characters and may be truncated by Windows' -Level WARNING
        }

        $Application = [PSCustomObject]@{
            DisplayName = $ApplicationId
            AppId       = $ApplicationId -replace '\s+', '.'
        }

        Write-Log "Display Name: $($Application.DisplayName)"
        Write-Log "Application ID: $($Application.AppId)"

        Set-RegKey -Path "HKCU:\SOFTWARE\Classes\AppUserModelId\$($Application.AppId)" `
                   -Name 'DisplayName' `
                   -Value $Application.DisplayName `
                   -PropertyType String

        Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\$($Application.AppId)" `
                   -Name 'AllowUrgentNotifications' `
                   -Value 1 `
                   -PropertyType DWord

        Write-Log 'Sending toast notification...'
        
        $notificationParams = @{
            ToastTitle    = $Title
            ToastText     = $Message
            ApplicationId = $Application.AppId
        }
        
        Show-Notification @notificationParams
        
        Write-Log 'Toast notification sent successfully'
        exit 0
    }
    catch {
        Write-Log "Failed to send toast notification: $_" -Level ERROR
        exit 1
    }
}

end {
    [System.GC]::Collect()
}