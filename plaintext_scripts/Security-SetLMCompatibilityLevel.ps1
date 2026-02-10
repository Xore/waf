#Requires -Version 5.1 -RunAsAdministrator

<#
.SYNOPSIS
    Configures the LAN Manager authentication compatibility level for enhanced security.

.DESCRIPTION
    This script sets the LMCompatibilityLevel registry value to enforce NTLMv2 authentication 
    and reject LM and NTLM protocols. This security hardening measure prevents legacy 
    authentication protocols that are vulnerable to pass-the-hash and relay attacks.
    
    Setting LMCompatibilityLevel to 5 configures Windows to:
    - Send only NTLMv2 responses
    - Refuse LM and NTLM authentication
    - Require NTLMv2 session security
    This is the recommended setting for modern Active Directory environments.

.PARAMETER CompatibilityLevel
    LAN Manager authentication level (0-5). Default: 5 (Send NTLMv2 only, refuse LM/NTLM)
    0 = Send LM & NTLM responses
    1 = Send LM & NTLM, use NTLMv2 if negotiated
    2 = Send NTLM only
    3 = Send NTLMv2 only
    4 = Send NTLMv2 only, refuse LM
    5 = Send NTLMv2 only, refuse LM & NTLM (Most Secure)

.EXAMPLE
    -CompatibilityLevel 5

    [Info] Setting LMCompatibilityLevel to 5 (Send NTLMv2 only, refuse LM and NTLM)
    [Info] LMCompatibilityLevel successfully set to 5
    [Info] Restart required for changes to take effect

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2012 R2
    Release notes: v3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
    User interaction: None
    Restart behavior: System restart required for changes to take effect
    Typical duration: < 1 second
    
.COMPONENT
    Registry - HKLM:\SYSTEM\CurrentControlSet\Control\Lsa
    
.LINK
    https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-security-lan-manager-authentication-level

.FUNCTIONALITY
    - Validates compatibility level parameter (0-5)
    - Sets LMCompatibilityLevel registry value in LSA configuration
    - Enforces NTLMv2-only authentication when set to level 5
    - Enhances security by disabling legacy LM and NTLM protocols
    - Requires system restart to apply changes
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(0, 5)]
    [int]$CompatibilityLevel = 5
)

begin {
    if ($env:compatibilityLevel -and $env:compatibilityLevel -notlike "null") {
        $CompatibilityLevel = [int]$env:compatibilityLevel
    }

    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $RegName = "LMCompatibilityLevel"
    $script:ExitCode = 0

    $LevelDescriptions = @{
        0 = "Send LM and NTLM responses"
        1 = "Send LM and NTLM, use NTLMv2 if negotiated"
        2 = "Send NTLM response only"
        3 = "Send NTLMv2 response only"
        4 = "Send NTLMv2 only, refuse LM"
        5 = "Send NTLMv2 only, refuse LM and NTLM"
    }
}

process {
    try {
        Write-Host "[Info] Setting LMCompatibilityLevel to $CompatibilityLevel ($($LevelDescriptions[$CompatibilityLevel]))"

        if (-not (Test-Path $RegPath)) {
            New-Item -Path $RegPath -Force | Out-Null
        }

        Set-ItemProperty -Path $RegPath -Name $RegName -Value $CompatibilityLevel -Type DWord -Force -Confirm:$false

        $CurrentValue = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue).$RegName
        if ($CurrentValue -eq $CompatibilityLevel) {
            Write-Host "[Info] LMCompatibilityLevel successfully set to $CompatibilityLevel"
            Write-Host "[Info] Restart required for changes to take effect"
        }
        else {
            Write-Host "[Error] Failed to set LMCompatibilityLevel. Current value: $CurrentValue"
            $script:ExitCode = 1
        }
    }
    catch {
        Write-Host "[Error] Failed to configure LMCompatibilityLevel: $_"
        $script:ExitCode = 1
    }

    exit $script:ExitCode
}

end {
}
