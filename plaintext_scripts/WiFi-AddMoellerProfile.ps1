#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Adds Moeller WiFi profile.
.DESCRIPTION
    Creates and adds a WiFi profile for Moeller-Wifi network with WPA3 Enterprise authentication.
    Uses EAP-TLS with computer authentication.
.EXAMPLE
    No parameters needed
    Adds Moeller WiFi profile to the system.
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

    $ProfileXML = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>Moeller-Wifi</name>
	<SSIDConfig>
		<SSID>
			<hex>4D6F656C6C65722D57696669</hex>
			<name>Moeller-Wifi</name>
		</SSID>
		<nonBroadcast>false</nonBroadcast>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<autoSwitch>false</autoSwitch>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA3ENT</authentication>
				<encryption>AES</encryption>
				<useOneX>true</useOneX>
				<FIPSMode xmlns="http://www.microsoft.com/networking/WLAN/profile/v2">false</FIPSMode>
			</authEncryption>
			<PMKCacheMode>enabled</PMKCacheMode>
			<PMKCacheTTL>720</PMKCacheTTL>
			<PMKCacheSize>128</PMKCacheSize>
			<preAuthMode>disabled</preAuthMode>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<authMode>machine</authMode>
				<EAPConfig><EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><EapMethod><Type xmlns="http://www.microsoft.com/provisioning/EapCommon">13</Type><VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId><VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType><AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId></EapMethod><Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1"><Type>13</Type><EapType xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1"><CredentialsSource><CertificateStore><SimpleCertSelection>true</SimpleCertSelection></CertificateStore></CredentialsSource><ServerValidation><DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation><ServerNames></ServerNames><TrustedRootCA>60 9d cb 17 c2 31 73 2e d5 7d 1b 6a 11 fa b5 c2 ea eb d2 a8 </TrustedRootCA><TrustedRootCA>60 9d cb 17 c2 31 73 2e d5 7d 1b 6a 11 fa b5 c2 ea eb d2 a8 </TrustedRootCA><TrustedRootCA>0b cc f2 f4 e2 8b 74 2d 13 23 15 38 72 ef b5 75 43 c0 46 3f </TrustedRootCA></ServerValidation><DifferentUsername>false</DifferentUsername><PerformServerValidation xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">true</PerformServerValidation><AcceptServerName xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">false</AcceptServerName></EapType></Eap></Config></EapHostConfig></EAPConfig>
			</OneX>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
		<randomizationSeed>760922326</randomizationSeed>
	</MacRandomization>
</WLANProfile>
"@
}

process {
    if (-not (Test-IsElevated)) {
        Write-Log "Access Denied. Please run with Administrator privileges." -Level Error
        exit 1
    }

    try {
        $ProfileName = "Moeller-Wifi"
        $ProfilePath = "$env:TEMP\$ProfileName.xml"

        Write-Log "Creating WiFi profile XML file: $ProfilePath"
        $ProfileXML | Out-File -Encoding UTF8 $ProfilePath -Force

        Write-Log "Adding WiFi profile to system..."
        $Result = netsh wlan add profile filename="$ProfilePath" user=all 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "WiFi profile added successfully"
        }
        else {
            Write-Log "Failed to add WiFi profile: $Result" -Level Error
            exit 1
        }

        Write-Log "Cleaning up temporary profile file"
        Remove-Item -Path $ProfilePath -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Failed to add WiFi profile: $_" -Level Error
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
