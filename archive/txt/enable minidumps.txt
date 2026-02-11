<#
.SYNOPSIS
    Turn on mini dumps if they are off, if other dumps are already enabled do not change the configuration.
.DESCRIPTION
    Turn on mini dumps if they are off, if other dumps are already enabled do not change the configuration.
    This will enable the creation of the pagefile, but set to automatically manage by Windows.
    Reboot might be needed.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes:
    Initial Release
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
param ()

begin {
    function Set-ItemProp {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        # Do not output errors and continue
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        if (-not $(Test-Path -Path $Path)) {
            # Check if path does not exist and create the path
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name)) {
            # Update property and print out what it was changed from and changed to
            $CurrentValue = Get-ItemProperty -Path $Path -Name $Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "$Path$Name changed from $CurrentValue to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        else {
            # Create property with value
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "Set $Path$Name to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Reference: https://learn.microsoft.com/en-US/troubleshoot/windows-server/performance/memory-dump-file-options
    $Path = "HKLM:SystemCurrentControlSetControlCrashControl"
    $Name = "CrashDumpEnabled"
    $CurrentValue = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction SilentlyContinue
    $Value = 3

    # If CrashDumpEnabled is set to 0 or doesn't exist then enable mini crash dump
    if ($CurrentValue -eq 0 -and $null -ne $CurrentValue) {
        $PageFile = Get-ItemPropertyValue -Path "HKLM:SYSTEMCurrentControlSetControlSession ManagerMemory Management" -Name PagingFiles -ErrorAction SilentlyContinue
        if (-not $PageFile) {
            # If the pagefile was not setup, create the registry entry needed to create the pagefile
            try {
                # Enable automatic page management file if disabled to allow mini dump to function
                Set-ItemProp -Path "HKLM:SYSTEMCurrentControlSetControlSession ManagerMemory Management" -Name PagingFiles -Value "?:pagefile.sys" -PropertyType MultiString
            }
            catch {
                Write-Error "Could not create pagefile."
                exit 1
            }
        }
        Set-ItemProp -Path $Path -Name $Name -Value 3
        Write-Host "Reboot might be needed to enable mini crash dump."
    }
    else {
        Write-Host "Crash dumps are already enabled."
    }
    exit 0
}
end {}