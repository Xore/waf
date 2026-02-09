#Requires -Version 2

<#
.SYNOPSIS
    Upgrades PowerShell to version 5.1.
.DESCRIPTION
    NOTICE - Multiple reboots may be required to continue with the install in the case
    where 3.0 is installed.
    This requires the user to log back in manually after the reboot before continuing.

    The script will upgrade powershell to 5.1 on the following OS'
        Windows Server 2012 R2
        Windows 8.1

    This script WILL NOT run if Exchange Server is installed!

    A log of this process is created in $env:Temp\upgrade_powershell.log
    This log can used to see how the script faired after an automatic reboot.
.EXAMPLE
    -Restart
PARAMETER: -Restart
    Restart even if a restart isn't required.

.EXAMPLE
    # upgrade to 5.1 with defaults and manual login and reboots
    (No Parameters)

.OUTPUTS
    None
.NOTES
    Minium Supported OS: Windows 8.1, Server 2012 R2
    Release Notes: Renamed script and added Script Variable support
By using this script, you indicate your acceptance of the following legal terms as well as our Terms of Use at https://www.ninjaone.com/terms-of-use.
    Ownership Rights: NinjaOne owns and will continue to own all right, title, and interest in and to the script (including the copyright). NinjaOne is giving you a limited license to use the script in accordance with these legal terms. 
    Use Limitation: You may only use the script for your legitimate personal or internal business purposes, and you may not share the script with another party. 
    Republication Prohibition: Under no circumstances are you permitted to re-publish the script in any script library or website belonging to or under the control of any other software provider. 
    Warranty Disclaimer: The script is provided “as is” and “as available”, without warranty of any kind. NinjaOne makes no promise or guarantee that the script will be free from defects or that it will meet your specific needs or expectations. 
    Assumption of Risk: Your use of the script is at your own risk. You acknowledge that there are certain inherent risks in using the script, and you understand and assume each of those risks. 
    Waiver and Release: You will not hold NinjaOne responsible for any adverse or unintended consequences resulting from your use of the script, and you waive any legal or equitable rights or remedies you may have against NinjaOne relating to your use of the script. 
    EULA: If you are a NinjaOne customer, your use of the script is subject to the End User License Agreement applicable to you (EULA).
#>

[CmdletBinding()]
Param(
    [string]$Version = "5.1",
    [switch]$ForceRestart = [System.Convert]::ToBoolean($env:ForceRestart)
)

begin {

    # Modified version from: https://github.com/jborean93/ansible-windows/tree/master/scripts
    #
    # LICENSE: https://github.com/jborean93/ansible-windows/blob/master/LICENSE
    # MIT License
    #
    # Copyright (c) 2017 Jordan Borean
    #
    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to deal
    # in the Software without restriction, including without limitation the rights
    # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    # copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:
    #
    # The above copyright notice and this permission notice shall be included in all
    # copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    # SOFTWARE.


    $ErrorActionPreference = 'Stop'
    if ([System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference) {
        $VerbosePreference = "Continue"
    }

    if ([System.Convert]::ToBoolean($env:Verbose)) {
        $Verbose = $true
    }

    # Don't upgrade PowerShell if Exchange is installed, this needs manual intervention to not cause problems.
    if ($(Get-Service -Name MSExchangeServiceHost -ErrorAction SilentlyContinue) -or $(Get-Command Exsetup.exe -ErrorAction SilentlyContinue | ForEach-Object { $_.FileVersionInfo })) {
        Write-Host "Exchange looks to be installed. Aborting PowerShell upgrade."
        exit 1
    }

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    $tmp_dir = $env:temp
    if (-not (Test-Path -Path $tmp_dir)) {
        New-Item -Path $tmp_dir -ItemType Directory > $null
    }

    Function Write-Log($message, $level = "INFO") {
        # Poor man's implementation of Log4Net
        $date_stamp = Get-Date -Format s
        $log_entry = "$date_stamp - $level - $message"
        $log_file = "$tmp_dir\upgrade_powershell.log"
        Write-Host -Message $log_entry
        Add-Content -Path $log_file -Value $log_entry
    }

    Function Invoke-Reboot {

        Write-Log -message "need to reboot server to continue powershell upgrade"

        shutdown.exe /r /t 30
    }

    Function Invoke-RunProcess($executable, $arguments) {
        $process = New-Object -TypeName System.Diagnostics.Process
        $psi = $process.StartInfo
        $psi.FileName = $executable
        $psi.Arguments = $arguments
        Write-Log -message "starting new process '$executable $arguments'"
        $process.Start() | Out-Null
    
        $process.WaitForExit() | Out-Null
        $exit_code = $process.ExitCode
        Write-Log -message "process completed with exit code '$exit_code'"

        return $exit_code
    }

    Function Invoke-DownloadFile($url, $path) {
        Write-Log -message "downloading url '$url' to '$path'"
        $client = New-Object -TypeName System.Net.WebClient
        $client.DownloadFile($url, $path)
    }

    Write-Log -message "starting script"
    # on PS v1.0, upgrade to 2.0 and then run the script again
    if ($PSVersionTable -eq $null) {
        Write-Log -message "upgrading powershell v1.0 to v2.0"
        $architecture = $env:PROCESSOR_ARCHITECTURE
        if ($architecture -eq "AMD64") {
            $url = "https://download.microsoft.com/download/2/8/6/28686477-3242-4E96-9009-30B16BED89AF/Windows6.0-KB968930-x64.msu"
        }
        else {
            $url = "https://download.microsoft.com/download/F/9/E/F9EF6ACB-2BA8-4845-9C10-85FC4A69B207/Windows6.0-KB968930-x86.msu"
        }
        $filename = $url.Split("/")[-1]
        $file = "$tmp_dir\$filename"
        Invoke-DownloadFile -url $url -path $file
        $exit_code = Invoke-RunProcess -executable $file -arguments "/quiet /norestart"
        if ($exit_code -ne 0 -and $exit_code -ne 3010) {
            $error_msg = "failed to update Powershell from 1.0 to 2.0: exit code $exit_code"
            Write-Log -message $error_msg -level "ERROR"
            throw $error_msg
        }
        Invoke-Reboot
    }

    # exit if the target version is the same as the actual version
    $current_ps_version = [version]"$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
    if ($current_ps_version -eq [version]$Version) {
        Write-Log -message "current and target PS version are the same, no action is required"
        exit 0
    }

    $os_version = [Version](Get-Item -Path "$env:SystemRoot\System32\kernel32.dll").VersionInfo.ProductVersion
    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ($architecture -eq "AMD64") {
        $architecture = "x64"
    }
    else {
        $architecture = "x86"
    }
}

process {
    $actions = @()
    switch ($Version) {
        "5.1" {
            if ($os_version -lt [version]"6.3") {
                $error_msg = "cannot upgrade Server 2008 to Powershell v5.1, v3 is the latest supported"
                Write-Log -message $error_msg -level "ERROR"
                throw $error_msg
            }
            # check if WMF 3 is installed, need to be uninstalled before 5.1
            if ($os_version.Minor -lt 2) {
                $wmf3_installed = Get-HotFix -Id "KB2506143" -ErrorAction SilentlyContinue
                if ($wmf3_installed) {
                    $error_msg = "cannot upgrade to Powershell v5.1, this needs manual intervention."
                    Write-Log -message $error_msg -level "ERROR"
                    throw $error_msg
                }
            }
            $actions += "5.1"
            break
        }
        default {
            $error_msg = "version '$Version' is not supported in this upgrade script"
            Write-Log -message $error_msg -level "ERROR"
            throw $error_msg
        }
    }

    # detect if .NET 4.5.2 is not installed and add to the actions
    $dotnet_path = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
    if (-not $(Test-Path -Path $dotnet_path -ErrorAction SilentlyContinue)) {
        $dotnet_upgrade_needed = $true
    }
    else {
        $dotnet_version = Get-ItemProperty -Path $dotnet_path -Name Release -ErrorAction SilentlyContinue
        if ($dotnet_version) {
            # 379893 == 4.5.2
            if ($dotnet_version.Release -lt 379893) {
                $dotnet_upgrade_needed = $true
            }        
        }
        else {
            $dotnet_upgrade_needed = $true
        }
    }
    if ($dotnet_upgrade_needed) {
        $actions = @("dotnet") + $actions
    }

    Write-Log -message "The following actions will be performed: $($actions -join ", ")"
    foreach ($action in $actions) {
        $url = $null
        $file = $null
        $arguments = "/quiet /norestart"

        switch ($action) {
            "dotnet" {
                Write-Log -message "running .NET update to 4.5.2"
                $url = "https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
                $error_msg = "failed to update .NET to 4.5.2"
                $arguments = "/q /norestart"
                break
            }
            "5.1" {
                Write-Log -message "running powershell update to version 5.1"
                if ($os_version.Minor -eq 2) {
                    # Server 2012
                    $url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/W2K12-KB3191565-x64.msu"
                }
                else {
                    # Server 2012 R2 and Windows 8.1
                    if ($architecture -eq "x64") {
                        $url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu"
                    }
                    else {
                        $url = "http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu"
                    }
                }
                break
            }
            default {
                $error_msg = "unknown action '$action'"
                Write-Log -message $error_msg -level "ERROR"
            }
        }

        if ($null -eq $file) {
            $filename = $url.Split("/")[-1]
            $file = "$tmp_dir\$filename"
        }
        if ($null -ne $url) {
            Invoke-DownloadFile -url $url -path $file
        }
    
        $exit_code = Invoke-RunProcess -executable $file -arguments $arguments
        if ($exit_code -ne 0 -and $exit_code -ne 3010) {
            $log_msg = "$($error_msg): exit code $exit_code"
            Write-Log -message $log_msg -level "ERROR"
            throw $log_msg
        }
        if ($exit_code -eq 3010) {
            $log_msg = "Reboot is required!"
            Write-Log -message $log_msg -level "WARN"
            break
        }
    }
    if ($ForceRestart) {
        Invoke-Reboot
    }
}
end {
    
    
    
}