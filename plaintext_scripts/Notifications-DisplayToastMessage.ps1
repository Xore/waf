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
    
    Toast notifications support:
    - Custom title and message text
    - Urgent scenario for immediate display
    - Auto-expiration after 1 minute
    - Custom application identification

.PARAMETER Title
    The toast notification title.
    Maximum 42 characters recommended for proper display.
    Required parameter.

.PARAMETER Message
    The toast notification message body.
    Maximum 254 characters recommended for proper display.
    Required parameter.

.PARAMETER ApplicationId
    Optional application identifier for the toast notification.
    Defaults to NINJA_COMPANY_NAME environment variable or 'NinjaOne RMM'.
    Spaces in the ApplicationId are replaced with dots for registry compatibility.

.EXAMPLE
    .\Notifications-DisplayToastMessage.ps1 -Title "Update Available" -Message "Please restart your computer"
    
    [2026-02-11 00:07:00] [INFO] Display Name: NinjaOne RMM
    [2026-02-11 00:07:00] [INFO] Application ID: NinjaOne.RMM
    [2026-02-11 00:07:01] [INFO] Sending toast notification
    [2026-02-11 00:07:01] [INFO] Toast notification sent successfully

.EXAMPLE
    .\Notifications-DisplayToastMessage.ps1 -Title "Alert" -Message "System maintenance required" -ApplicationId "MyCompany"
    
    Displays a toast notification with a custom ApplicationId.

.OUTPUTS
    None. Status information is written to the console.

.NOTES
    File Name      : Notifications-DisplayToastMessage.ps1
    Prerequisite   : PowerShell 5.1 or higher, Windows 10 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Output only logging
    - 1.0: Initial release
    
.LINK
    https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/

.FUNCTIONALITY
    - Displays Windows toast notifications to logged-in users
    - Creates registry entries for notification permissions
    - Validates user context (must not run as SYSTEM)
    - Supports custom application branding
    - Auto-expires notifications after 1 minute
    - Validates message length constraints
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Toast notification title (max 42 chars)")]
    [string]$Title,
    
    [Parameter(Mandatory = $false, HelpMessage = "Toast notification message (max 254 chars)")]
    [string]$Message,
    
    [Parameter(Mandatory = $false, HelpMessage = "Application identifier")]
    [string]$ApplicationId
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = 'INFO'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $LogMessage = "[$Timestamp] [$Level] $Message"
        Write-Output $LogMessage
        
        if ($Level -eq 'ERROR') { $script:ErrorCount++ }
        if ($Level -eq 'WARNING') { $script:WarningCount++ }
    }

    function Test-IsSystem {
        <#
        .SYNOPSIS
            Checks if the current process is running as SYSTEM.
        #>
        try {
            $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            return ($Identity.Name -like 'NT AUTHORITY*' -or $Identity.IsSystem)
        }
        catch {
            Write-Log "Failed to determine user context: $_" -Level 'WARNING'
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
                Write-Log "Created registry path: $Path" -Level 'DEBUG'
            }

            $ExistingValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            
            if ($ExistingValue) {
                $CurrentValue = $ExistingValue.$Name
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -ErrorAction Stop | Out-Null
                Write-Log "Updated $Path\$Name from '$CurrentValue' to '$Value'" -Level 'DEBUG'
            }
            else {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -ErrorAction Stop | Out-Null
                Write-Log "Created $Path\$Name with value '$Value'" -Level 'DEBUG'
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
        # Verify not running as SYSTEM
        if (Test-IsSystem) {
            Write-Log "This script must run as 'Current Logged on User', not SYSTEM" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        # Environment variable overrides
        if ($env:title -and $env:title -notlike 'null') { $Title = $env:title }
        if ($env:message -and $env:message -notlike 'null') { $Message = $env:message }
        if ($env:applicationId -and $env:applicationId -notlike 'null') { $ApplicationId = $env:applicationId }

        # Set default ApplicationId
        if (-not $ApplicationId) {
            $ApplicationId = if ($env:NINJA_COMPANY_NAME) { $env:NINJA_COMPANY_NAME } else { 'NinjaOne RMM' }
        }

        # Validate required parameters
        if ([string]::IsNullOrWhiteSpace($Title)) {
            Write-Log 'Title parameter is required' -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        if ([string]::IsNullOrWhiteSpace($Message)) {
            Write-Log 'Message parameter is required' -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        # Validate length constraints
        if ($Title.Length -gt 42) {
            Write-Log 'Title exceeds 42 characters and may be truncated by Windows' -Level 'WARNING'
        }

        if ($Message.Length -gt 254) {
            Write-Log 'Message exceeds 254 characters and may be truncated by Windows' -Level 'WARNING'
        }

        # Prepare application identity
        $Application = [PSCustomObject]@{
            DisplayName = $ApplicationId
            AppId       = $ApplicationId -replace '\s+', '.'
        }

        Write-Log "Display Name: $($Application.DisplayName)"
        Write-Log "Application ID: $($Application.AppId)"

        # Configure registry for toast notifications
        Set-RegKey -Path "HKCU:\SOFTWARE\Classes\AppUserModelId\$($Application.AppId)" `
                   -Name 'DisplayName' `
                   -Value $Application.DisplayName `
                   -PropertyType String

        Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\$($Application.AppId)" `
                   -Name 'AllowUrgentNotifications' `
                   -Value 1 `
                   -PropertyType DWord

        Write-Log 'Sending toast notification'
        
        $NotificationParams = @{
            ToastTitle    = $Title
            ToastText     = $Message
            ApplicationId = $Application.AppId
        }
        
        Show-Notification @NotificationParams
        
        Write-Log 'Toast notification sent successfully'
    }
    catch {
        Write-Log "Failed to send toast notification: $_" -Level 'ERROR'
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output "`n========================================"
        Write-Output "Execution Summary"
        Write-Output "========================================"
        Write-Output "Script: Notifications-DisplayToastMessage.ps1"
        Write-Output "Duration: $Duration seconds"
        Write-Output "Errors: $script:ErrorCount"
        Write-Output "Warnings: $script:WarningCount"
        Write-Output "Exit Code: $script:ExitCode"
        Write-Output "========================================"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
