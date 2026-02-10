#Requires -Version 5.1

<#
.SYNOPSIS
    Detects Windows activation and license status.

.DESCRIPTION
    Condition script that verifies Windows activation and licensing state.
    Queries SoftwareLicensingProduct WMI class and slmgr.vbs to determine
    the current activation status and provides detailed error information
    for KMS/MAK activation issues.
    
    Exit codes indicate the activation state:
    - 0: Activated and Licensed
    - 2: Unlicensed but under grace period
    - 3: Not Activated and Unlicensed
    - 5: Activated but Evaluation license

.EXAMPLE
    .\Licensing-UnlicensedWindowsAlert.ps1
    
    [2026-02-11 00:05:00] [INFO] Checking Windows license status
    [2026-02-11 00:05:01] [INFO] License Status: 1 (Licensed)
    [2026-02-11 00:05:01] [INFO] Windows is activated and licensed
    Exit Code: 0

.EXAMPLE
    .\Licensing-UnlicensedWindowsAlert.ps1
    
    When Windows is unlicensed:
    [2026-02-11 00:05:00] [INFO] Checking Windows license status
    [2026-02-11 00:05:01] [WARNING] License Status: 0 (Unlicensed)
    [2026-02-11 00:05:01] [ERROR] KMS Activation Error Found
    Exit Code: 3

.OUTPUTS
    System.Int32
    Exit code indicating activation status.

.NOTES
    File Name      : Licensing-UnlicensedWindowsAlert.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Output only logging
    - 1.1: Renamed script
    - 1.0: Initial version
    
.LINK
    https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/dn502528(v=ws.11)

.FUNCTIONALITY
    - Checks Windows activation status via WMI
    - Queries slmgr.vbs for detailed license information
    - Detects KMS/MAK activation errors
    - Provides troubleshooting guidance for common activation issues
    - Returns appropriate exit codes for automation
#>

[CmdletBinding()]
param ()

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

    $NotificationReasons = @(
        [PSCustomObject]@{
            ErrorCode            = '0xC004C001'
            ErrorMessage         = 'The activation server determined the specified product key is invalid'
            ActivationType       = 'MAK'
            PossibleCause        = 'An invalid MAK was entered.'
            TroubleshootingSteps = 'Verify that the key is the MAK provided by Microsoft. Contact the Microsoft Activation Call Center to verify that the MAK is valid.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004C003'
            ErrorMessage         = 'The activation server determined the specified product key has been blocked'
            ActivationType       = 'MAK'
            PossibleCause        = 'The MAK is blocked on the activation server.'
            TroubleshootingSteps = 'Contact the Microsoft Activation Call Center to obtain a new MAK and install/activate the system.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004C008'
            ErrorMessage         = 'The activation server reported that the product key has exceeded its unlock limit.'
            ActivationType       = 'KMS'
            PossibleCause        = 'The KMS key has exceeded the activation limit.'
            TroubleshootingSteps = 'KMS host keys will activate up to 10 times on six different computers. If more activations are necessary, contact the Microsoft Activation Call Center.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004C020'
            ErrorMessage         = 'The activation server reported that the Multiple Activation Key has exceeded its limit.'
            ActivationType       = 'MAK'
            PossibleCause        = 'The MAK has exceeded the activation limit.'
            TroubleshootingSteps = 'MAKs by design have a limited number of activations. Contact the Microsoft Activation Call Center.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004C021'
            ErrorMessage         = 'The activation server reported that the Multiple Activation Key extension limit has been exceeded.'
            ActivationType       = 'MAK'
            PossibleCause        = 'The MAK has exceeded the activation limit.'
            TroubleshootingSteps = 'MAKs by design have a limited number of activations. Contact the Microsoft Activation Call Center.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F009'
            ErrorMessage         = 'The Software Protection Service reported that the grace period expired.'
            ActivationType       = 'MAK'
            PossibleCause        = 'The grace period expired before the system was activated. Now, the system is in the Notifications state.'
            TroubleshootingSteps = 'Activate the system using MAK or KMS activation.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F00F'
            ErrorMessage         = 'The Software Licensing Server reported that the hardware ID binding is beyond level the of tolerance.'
            ActivationType       = 'MAK/KMS client/KMS host'
            PossibleCause        = 'The hardware has changed or the drivers were updated on the system.'
            TroubleshootingSteps = 'MAK: Reactivate the system during the OOT grace period using either online or phone activation. KMS: Restart, or run slmgr.vbs /ato.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F014'
            ErrorMessage         = 'The Software Protection Service reported that the product key is not available'
            ActivationType       = 'MAK/KMS client'
            PossibleCause        = 'No product keys are installed on the system.'
            TroubleshootingSteps = 'Install a MAK product key, or install a KMS Setup key found in \sources\Product.ini on the installation media.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F02C'
            ErrorMessage         = 'The Software Protection Service reported that the format for the offline activation data is incorrect.'
            ActivationType       = 'MAK/KMS client'
            PossibleCause        = 'The system has detected that the data entered during phone activation is not valid.'
            TroubleshootingSteps = 'Verify that the CID is correctly entered.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F038'
            ErrorMessage         = 'The Software Protection Service reported that the computer could not be activated. The count reported by your Key Management Service (KMS) is insufficient. Please contact your system administrator.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'The count on the KMS host is not high enough. The KMS count must be >=5 for Windows Server or >=25 for Windows client.'
            TroubleshootingSteps = 'More computers are needed in the KMS pool for KMS clients to activate. Run Slmgr.vbs /dli to get the current count on the KMS host.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F039'
            ErrorMessage         = 'The Software Protection Service reported that the computer could not be activated. The Key Management Service (KMS) is not enabled.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'This error occurs when a KMS request is not answered.'
            TroubleshootingSteps = 'Troubleshoot the network connection between the KMS host and the client. Make sure that TCP port 1688 (default) is not blocked by a firewall or otherwise filtered.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F041'
            ErrorMessage         = 'The Software Licensing Service determined that the Key Management Service (KMS) is not activated. KMS needs to be activated. Please contact system administrator.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'The KMS host is not activated.'
            TroubleshootingSteps = 'Activate the KMS host with either online or phone activation.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F042'
            ErrorMessage         = 'The Software Protection Service determined that the specified Key Management Service (KMS) cannot be used.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'Mismatch between the KMS client and the KMS host.'
            TroubleshootingSteps = 'This error occurs when a KMS client contacts a KMS host that cannot activate the client software. This can be common in mixed environments that contain application and operating system-specific KMS hosts, for example.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F050'
            ErrorMessage         = 'The Software Protection Service reported that the product key is invalid.'
            ActivationType       = 'KMS, KMS client, MAK'
            PossibleCause        = 'This can be caused by a typo in the KMS key or by typing in a Beta key on a Released version of the operating system.'
            TroubleshootingSteps = 'Install the appropriate KMS key on the corresponding version of Windows. Check the spelling. If the key is being copied and pasted, make sure that em dashes have not been substituted for the dashes in the key.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F051'
            ErrorMessage         = 'The Software Protection Service reported that the product key is blocked.'
            ActivationType       = 'MAK/KMS'
            PossibleCause        = 'The product key on the activation server is blocked by Microsoft.'
            TroubleshootingSteps = 'Obtain a new MAK/KMS key, install it on the system, and activate.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F074'
            ErrorMessage         = 'The Software Protection Service reported that the computer could not be activated. No Key Management Service (KMS) could be contacted. Please see the Application Event Log for additional information.'
            ActivationType       = 'KMS Client'
            PossibleCause        = 'All KMS host systems  returned an error.'
            TroubleshootingSteps = 'Troubleshoot errors from each event ID 12288 associated with the activation attempt.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0xC004F06C'
            ErrorMessage         = 'The Software Protection Service reported that the computer could not be activated. The Key Management Service (KMS) determined that the request timestamp is invalid.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'The system time on the client computer is too different from the time on the KMS host.'
            TroubleshootingSteps = 'Time sync is important to system and network security for a variety of reasons. Fix this issue by changing the system time on the client to sync with the KMS. Use of a Network Time Protocol (NTP) time source or Active Directory Domain Services for time synchronization is recommended. This issue uses UTP time and is independent of Time Zone selection.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0x80070005'
            ErrorMessage         = 'Access denied. The requested action requires elevated privileges.'
            ActivationType       = 'KMS client/MAK/KMS host'
            PossibleCause        = 'User Account Control (UAC) prohibits activation processes from running in a non-elevated command prompt.'
            TroubleshootingSteps = 'Run slmgr.vbs from an elevated command prompt. Right-click cmd.exe, and then click Run as Administrator.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0x8007232A'
            ErrorMessage         = 'DNS server failure.'
            ActivationType       = 'KMS host'
            PossibleCause        = 'The system has network or DNS issues.'
            TroubleshootingSteps = 'Troubleshoot network and DNS.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0x8007232B'
            ErrorMessage         = 'DNS name does not exist.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'The KMS client cannot find KMS SRV RRs in DNS. If a KMS host does not exist on the network, a MAK should be installed.'
            TroubleshootingSteps = 'Confirm that a KMS host has been installed and DNS publishing is enabled (default). If DNS is unavailable, point the KMS client to the KMS host by using slmgr.vbs /skms <kms_host_name>. Optionally, obtain and install a MAK; then, activate the system. Finally, troubleshoot DNS.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0x800706BA'
            ErrorMessage         = 'The RPC server is unavailable.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'Firewall settings are not configured on the KMS host, or DNS SRV records are stale.'
            TroubleshootingSteps = 'Ensure the Key Management Service firewall exception is enabled on the KMS host computer. Ensure that SRV records point to a valid KMS host. Troubleshoot network connections.'
        }
        [PSCustomObject]@{
            ErrorCode            = '0x8007251D'
            ErrorMessage         = 'No records found for given DNS query.'
            ActivationType       = 'KMS client'
            PossibleCause        = 'The KMS client cannot find KMS SRV RRs in DNS.'
            TroubleshootingSteps = 'Troubleshoot network connections and DNS.'
        }
    )
}

process {
    try {
        Write-Log 'Checking Windows license status'

        $LicenseStatus = Get-CimInstance -ClassName 'SoftwareLicensingProduct' -Filter "Name like 'Windows%'" -ErrorAction SilentlyContinue |
            Where-Object { $_.PartialProductKey } |
            Select-Object -ExpandProperty LicenseStatus

        $StatusText = switch ($LicenseStatus) {
            0 { 'Unlicensed' }
            1 { 'Licensed' }
            2 { 'Out-of-Box Grace Period' }
            3 { 'Out-of-Tolerance Grace Period' }
            4 { 'Non-Genuine Grace Period' }
            5 { 'Notification' }
            6 { 'Extended Grace' }
            default { 'Unknown' }
        }
        
        Write-Log "License Status: $LicenseStatus ($StatusText)"

        $ActivationNumber = switch ($LicenseStatus) {
            0 { 3 }  # Unlicensed
            1 { 0 }  # Licensed
            2 { 2 }  # Out-of-Box Grace Period
            3 { 2 }  # Out-of-Tolerance Grace Period
            4 { 3 }  # Non-Genuine Grace Period
            5 { 3 }  # Notification
            6 { 2 }  # Extended Grace
            default { 3 }
        }

        $SlmgrPath = Join-Path $env:SystemRoot 'System32\slmgr.vbs'
        
        if (-not (Test-Path -Path $SlmgrPath)) {
            Write-Log 'slmgr.vbs not found in expected location' -Level 'WARNING'
            $script:ExitCode = $ActivationNumber
            return
        }

        $Result = cscript.exe $SlmgrPath -dli 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log 'Failed to execute slmgr.vbs' -Level 'WARNING'
            $script:ExitCode = $ActivationNumber
            return
        }

        $SlmgrOutput = $Result | Select-Object -Skip 4 | Out-String
        Write-Output $SlmgrOutput
        
        $Notification = $Result -split [System.Environment]::NewLine | Where-Object { $_ -match '^Notification Reason: .*' }
        
        if ($Notification) {
            $NotificationCode = $($($Notification -split ': ')[1] -split '\.')[0]
            Write-Log 'KMS Activation Error Found' -Level 'ERROR'
            
            if ($NotificationCode -like '0xC004F200') {
                Write-Log 'Error Type: Non-Genuine'
            }
            elseif ($NotificationCode -like '0xC004F009') {
                Write-Log 'Error Type: Grace Time Expired'
            }
            else {
                $ErrorDetails = $NotificationReasons | Where-Object { $_.ErrorCode -like $NotificationCode }
                
                if ($ErrorDetails) {
                    Write-Log "Error Code: $($ErrorDetails.ErrorCode)"
                    Write-Log "Error Message: $($ErrorDetails.ErrorMessage)"
                    Write-Log "Activation Type: $($ErrorDetails.ActivationType)"
                    Write-Log "Possible Cause: $($ErrorDetails.PossibleCause)"
                    Write-Log "Troubleshooting: $($ErrorDetails.TroubleshootingSteps)"
                }
                else {
                    Write-Log "Unknown notification code: $NotificationCode" -Level 'WARNING'
                }
            }
        }
        
        if ($Result -like '*Eval*') {
            Write-Log 'Windows is running as Evaluation license' -Level 'WARNING'
            $script:ExitCode = 5
        }
        else {
            $script:ExitCode = $ActivationNumber
        }
    }
    catch {
        Write-Log "Failed to check license status: $_" -Level 'ERROR'
        $script:ExitCode = 3
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output "`n========================================"
        Write-Output "Execution Summary"
        Write-Output "========================================"
        Write-Output "Script: Licensing-UnlicensedWindowsAlert.ps1"
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
