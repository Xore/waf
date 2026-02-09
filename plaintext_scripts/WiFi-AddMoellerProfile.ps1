# PowerShell-Skript zur Erstellung des WLAN-Profils für "PLATZHALTER-NETZWERK" mit EAP-TLS (Computer-Authentifizierung)

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

# Profil als XML-Datei speichern
$ProfilePath = "$env:TEMP\$ProfileName.xml"
$ProfileXML | Out-File -Encoding UTF8 $ProfilePath

# WLAN-Profil hinzufügen
netsh wlan add profile filename="$ProfilePath" user=all

# Optional: Profil als GPO-Startskript verteilen
# Kopiere das Skript in SYSVOL und verknüpfe es als Computerrichtlinien-Startskript

Write-Output "WLAN-Profil erfolgreich erstellt und hinzugefügt."