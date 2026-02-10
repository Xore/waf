#Requires -Version 5.1

<#
.SYNOPSIS
    Verify Windows 11 upgrade compatibility for hardware and firmware

.DESCRIPTION
    Comprehensive hardware readiness assessment for Windows 11 upgrade eligibility.
    Evaluates system components against Microsoft's official Windows 11 minimum
    requirements and returns detailed compatibility results.
    
    Technical Implementation:
    This script implements Microsoft's official hardware readiness validation logic
    from the HardwareReadiness.ps1 script (https://aka.ms/HWReadinessScript).
    Modified for NinjaRMM integration with custom field support.
    
    Windows 11 Minimum Requirements Validated:
    
    1. Storage Requirements:
       - Minimum OS disk size: 64 GB
       - Checks SystemDrive capacity (typically C:)
       - Uses Win32_LogicalDisk WMI class for size detection
    
    2. Memory Requirements:
       - Minimum RAM: 4 GB
       - Sums all physical memory modules
       - Uses Win32_PhysicalMemory for accurate capacity
    
    3. TPM (Trusted Platform Module) Requirements:
       - TPM version 2.0 required
       - Validates TPM presence using Get-Tpm cmdlet
       - Checks SpecVersion from Win32_Tpm WMI class
       - TPM must be enabled and functional
    
    4. Processor Requirements:
       - 64-bit processor (AddressWidth = 64)
       - Minimum clock speed: 1 GHz (1000 MHz)
       - Minimum logical cores: 2
       - Specific CPU family/model validation
       
       Supported Processors:
       - Intel: 8th generation or newer (with exceptions)
         * Special validation for 6th/7th gen Coffee Lake CPUs
         * Platform ID checks for specific models (142, 158)
         * Exception: i7-7820HQ in Surface Studio 2 or Precision 5520
       
       - AMD: Ryzen 2000 series or newer
         * Family 23 (Zen+) or higher
         * Excludes Family 23 Model 1 and 17 (early Zen)
       
       - Qualcomm: Snapdragon processors with ARMv8.1 atomic instructions
         * Validates ARM v8.1 support via IsProcessorFeaturePresent
         * Checks CP 4030 registry value for atomic instruction support
    
    5. Secure Boot Requirements:
       - UEFI firmware with Secure Boot capability
       - Uses Confirm-SecureBootUEFI cmdlet
       - Validates Secure Boot can be enabled (not necessarily enabled)
       - Legacy BIOS systems automatically fail this check
    
    CPU Family Validation Logic:
    The script includes inline C# code (compiled at runtime) for low-level
    CPU detection using P/Invoke calls to kernel32.dll:
    
    - GetNativeSystemInfo: Retrieves processor architecture and details
    - IsProcessorFeaturePresent: Checks ARM instruction set support
    - Registry queries for platform-specific validation
    
    Return Codes and Meanings:
    
    0 = CAPABLE
        All requirements met, system can upgrade to Windows 11
    
    1 = NOT CAPABLE
        One or more requirements not met, upgrade blocked
        returnReason field contains list of failed checks
    
    -1 = UNDETERMINED
        Unable to determine compatibility (permissions, WMI errors)
        Manual validation recommended
    
    -2 = FAILED TO RUN
        Script encountered fatal error before completing checks
    
    Output Structure:
    The script returns JSON object with:
    - returnCode: Numeric result code (0, 1, -1, -2)
    - returnResult: Text result (CAPABLE, NOT CAPABLE, UNDETERMINED, FAILED TO RUN)
    - returnReason: Comma-separated list of failed requirement categories
    - logging: Detailed log of all checks performed
    
    NinjaRMM Integration:
    Results are written to custom field "Win11Upgrade" with values:
    - Capable
    - Not Capable
    - Undetermined
    - Failed To Run
    - Unknown (default/error state)
    
    Special Cases and Exceptions:
    
    1. Surface Studio 2 with i7-7820HQ:
       Officially supported despite being 7th generation Intel
       Model string checked: "surface studio 2"
    
    2. Dell Precision 5520 with i7-7820HQ:
       Officially supported workstation configuration
       Model string checked: "precision 5520"
    
    3. Intel Coffee Lake Refresh:
       Models 142 and 158 with stepping 9 require platform ID validation
       Registry key: Platform Specific Field 1
       Valid values: Model 142 = 16, Model 158 = 8
    
    Limitations and Considerations:
    - Does not check Windows version (only hardware/firmware)
    - Requires administrator privileges for TPM and Secure Boot checks
    - WMI/CIM queries may timeout on slow systems
    - Virtual machines may report inaccurate hardware details
    - Hyper-V VMs without vTPM will fail TPM requirement
    
    Use Cases:
    - Pre-deployment Windows 11 readiness assessment
    - Hardware inventory and compliance reporting
    - Upgrade planning and device lifecycle management
    - Identifying devices requiring hardware upgrades
    - Capacity planning for Windows 11 migration

.PARAMETER CustomField
    Name of NinjaRMM custom field to store results (default: Win11Upgrade)

.EXAMPLE
    .\Windows-CheckWin11UpgradeCompatibility.ps1
    
    Checks Windows 11 compatibility and stores result in default field.

.EXAMPLE
    .\Windows-CheckWin11UpgradeCompatibility.ps1 -CustomField "Windows11Ready"
    
    Checks compatibility and stores result in custom field "Windows11Ready".

.NOTES
    File Name      : Windows-CheckWin11UpgradeCompatibility.ps1
    Prerequisite   : PowerShell 5.1 or higher
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team (Based on Microsoft HardwareReadiness.ps1)
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and enhanced logging
    - 3.0: Enhanced documentation and NinjaRMM integration
    - 2.0: Added comprehensive hardware validation
    - 1.0: Initial release
    
    Execution Context: SYSTEM (recommended for TPM/SecureBoot checks)
    Execution Frequency: Weekly or monthly for inventory updates
    Typical Duration: 5-15 seconds
    Timeout Setting: 120 seconds recommended
    
    User Interaction: None (runs silently in background)
    Restart Behavior: N/A (no system restart)
    
    NinjaRMM Fields Updated:
        - Win11Upgrade (or custom field specified)
          Possible values: Capable, Not Capable, Undetermined, Failed To Run
    
    Dependencies:
        - Windows 10 or later (Get-Tpm cmdlet)
        - Administrator privileges (for TPM and Secure Boot checks)
        - WMI/CIM service running
    
    Exit Codes:
        0 - System is capable of Windows 11 upgrade
        1 - System is not capable of Windows 11 upgrade
        -1 - Compatibility undetermined (check failures)
        -2 - Script failed to run (fatal error)

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://aka.ms/HWReadinessScript
    
.LINK
    https://learn.microsoft.com/en-us/windows/whats-new/windows-11-requirements
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$CustomField = "Win11Upgrade"
)

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "Windows-CheckWin11UpgradeCompatibility"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = -2

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$false)]
            [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
            [string]$Level = 'INFO'
        )
        
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Write-Output "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            'WARN'  { $script:WarningCount++ }
            'ERROR' { $script:ErrorCount++ }
        }
    }

    function Get-HardwareReadiness {
        <#
        .SYNOPSIS
            Microsoft's official hardware readiness validation logic
        .DESCRIPTION
            Modified copy of https://aka.ms/HWReadinessScript (as of 7/26/2023)
            Only modification: Replaced Get-WmiObject with Get-CimInstance for PowerShell 7 compatibility
            Source: https://techcommunity.microsoft.com/t5/microsoft-endpoint-manager-blog/understanding-readiness-for-windows-11-with-microsoft-endpoint/ba-p/2770866
        #>

        [int]$MinOSDiskSizeGB = 64
        [int]$MinMemoryGB = 4
        [Uint32]$MinClockSpeedMHz = 1000
        [Uint32]$MinLogicalCores = 2
        [Uint16]$RequiredAddressWidth = 64

        $PASS_STRING = "PASS"
        $FAIL_STRING = "FAIL"
        $FAILED_TO_RUN_STRING = "FAILED TO RUN"
        $UNDETERMINED_CAPS_STRING = "UNDETERMINED"
        $UNDETERMINED_STRING = "Undetermined"
        $CAPABLE_STRING = "Capable"
        $NOT_CAPABLE_STRING = "Not capable"
        $CAPABLE_CAPS_STRING = "CAPABLE"
        $NOT_CAPABLE_CAPS_STRING = "NOT CAPABLE"
        $STORAGE_STRING = "Storage"
        $OS_DISK_SIZE_STRING = "OSDiskSize"
        $MEMORY_STRING = "Memory"
        $SYSTEM_MEMORY_STRING = "System_Memory"
        $GB_UNIT_STRING = "GB"
        $TPM_STRING = "TPM"
        $TPM_VERSION_STRING = "TPMVersion"
        $PROCESSOR_STRING = "Processor"
        $SECUREBOOT_STRING = "SecureBoot"
        $I7_7820HQ_CPU_STRING = "i7-7820hq CPU"

        $logFormat = '{0}: {1}={2}. {3}; '
        $logFormatWithUnit = '{0}: {1}={2}{3}. {4}; '
        $logFormatReturnReason = '{0}, '
        $logFormatException = '{0}; '
        $logFormatWithBlob = '{0}: {1}. {2}; '

        $outObject = @{ returnCode = -2; returnResult = $FAILED_TO_RUN_STRING; returnReason = ""; logging = "" }

        function Private:UpdateReturnCode {
            param(
                [Parameter(Mandatory=$true)]
                [ValidateRange(-2, 1)]
                [int]$ReturnCode
            )

            Switch ($ReturnCode) {
                0 {
                    if ($outObject.returnCode -eq -2) {
                        $outObject.returnCode = $ReturnCode
                    }
                }
                1 {
                    $outObject.returnCode = $ReturnCode
                }
                -1 {
                    if ($outObject.returnCode -ne 1) {
                        $outObject.returnCode = $ReturnCode
                    }
                }
            }
        }

        $Source = @"
using Microsoft.Win32;
using System;
using System.Runtime.InteropServices;

public class CpuFamilyResult
{
    public bool IsValid { get; set; }
    public string Message { get; set; }
}

public class CpuFamily
{
    [StructLayout(LayoutKind.Sequential)]
    public struct SYSTEM_INFO
    {
        public ushort ProcessorArchitecture;
        ushort Reserved;
        public uint PageSize;
        public IntPtr MinimumApplicationAddress;
        public IntPtr MaximumApplicationAddress;
        public IntPtr ActiveProcessorMask;
        public uint NumberOfProcessors;
        public uint ProcessorType;
        public uint AllocationGranularity;
        public ushort ProcessorLevel;
        public ushort ProcessorRevision;
    }

    [DllImport("kernel32.dll")]
    internal static extern void GetNativeSystemInfo(ref SYSTEM_INFO lpSystemInfo);

    public enum ProcessorFeature : uint
    {
        ARM_SUPPORTED_INSTRUCTIONS = 34
    }

    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool IsProcessorFeaturePresent(ProcessorFeature processorFeature);

    private const ushort PROCESSOR_ARCHITECTURE_X86 = 0;
    private const ushort PROCESSOR_ARCHITECTURE_ARM64 = 12;
    private const ushort PROCESSOR_ARCHITECTURE_X64 = 9;

    private const string INTEL_MANUFACTURER = "GenuineIntel";
    private const string AMD_MANUFACTURER = "AuthenticAMD";
    private const string QUALCOMM_MANUFACTURER = "Qualcomm Technologies Inc";

    public static CpuFamilyResult Validate(string manufacturer, ushort processorArchitecture)
    {
        CpuFamilyResult cpuFamilyResult = new CpuFamilyResult();

        if (string.IsNullOrWhiteSpace(manufacturer))
        {
            cpuFamilyResult.IsValid = false;
            cpuFamilyResult.Message = "Manufacturer is null or empty";
            return cpuFamilyResult;
        }

        string registryPath = "HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0";
        SYSTEM_INFO sysInfo = new SYSTEM_INFO();
        GetNativeSystemInfo(ref sysInfo);

        switch (processorArchitecture)
        {
            case PROCESSOR_ARCHITECTURE_ARM64:

                if (manufacturer.Equals(QUALCOMM_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                {
                    bool isArmv81Supported = IsProcessorFeaturePresent(ProcessorFeature.ARM_SUPPORTED_INSTRUCTIONS);

                    if (!isArmv81Supported)
                    {
                        string registryName = "CP 4030";
                        long registryValue = (long)Registry.GetValue(registryPath, registryName, -1);
                        long atomicResult = (registryValue >> 20) & 0xF;

                        if (atomicResult >= 2)
                        {
                            isArmv81Supported = true;
                        }
                    }

                    cpuFamilyResult.IsValid = isArmv81Supported;
                    cpuFamilyResult.Message = isArmv81Supported ? "" : "Processor does not implement ARM v8.1 atomic instruction";
                }
                else
                {
                    cpuFamilyResult.IsValid = false;
                    cpuFamilyResult.Message = "The processor isn't currently supported for Windows 11";
                }

                break;

            case PROCESSOR_ARCHITECTURE_X64:
            case PROCESSOR_ARCHITECTURE_X86:

                int cpuFamily = sysInfo.ProcessorLevel;
                int cpuModel = (sysInfo.ProcessorRevision >> 8) & 0xFF;
                int cpuStepping = sysInfo.ProcessorRevision & 0xFF;

                if (manufacturer.Equals(INTEL_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                {
                    try
                    {
                        cpuFamilyResult.IsValid = true;
                        cpuFamilyResult.Message = "";

                        if (cpuFamily >= 6 && cpuModel <= 95 && !(cpuFamily == 6 && cpuModel == 85))
                        {
                            cpuFamilyResult.IsValid = false;
                            cpuFamilyResult.Message = "";
                        }
                        else if (cpuFamily == 6 && (cpuModel == 142 || cpuModel == 158) && cpuStepping == 9)
                        {
                            string registryName = "Platform Specific Field 1";
                            int registryValue = (int)Registry.GetValue(registryPath, registryName, -1);

                            if ((cpuModel == 142 && registryValue != 16) || (cpuModel == 158 && registryValue != 8))
                            {
                                cpuFamilyResult.IsValid = false;
                            }
                            cpuFamilyResult.Message = "PlatformId " + registryValue;
                        }
                    }
                    catch (Exception ex)
                    {
                        cpuFamilyResult.IsValid = false;
                        cpuFamilyResult.Message = "Exception:" + ex.GetType().Name;
                    }
                }
                else if (manufacturer.Equals(AMD_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                {
                    cpuFamilyResult.IsValid = true;
                    cpuFamilyResult.Message = "";

                    if (cpuFamily < 23 || (cpuFamily == 23 && (cpuModel == 1 || cpuModel == 17)))
                    {
                        cpuFamilyResult.IsValid = false;
                    }
                }
                else
                {
                    cpuFamilyResult.IsValid = false;
                    cpuFamilyResult.Message = "Unsupported Manufacturer: " + manufacturer + ", Architecture: " + processorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                }

                break;

            default:
                cpuFamilyResult.IsValid = false;
                cpuFamilyResult.Message = "Unsupported CPU category. Manufacturer: " + manufacturer + ", Architecture: " + processorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                break;
        }
        return cpuFamilyResult;
    }
}
"@

        $exitCode = 0

        try {
            $osDrive = Get-CimInstance -Class Win32_OperatingSystem | Select-Object -Property SystemDrive
            $osDriveSize = Get-CimInstance -Class Win32_LogicalDisk -Filter "DeviceID='$($osDrive.SystemDrive)'" | Select-Object @{Name="SizeGB"; Expression={$_.Size / 1GB -as [int]}}

            if ($null -eq $osDriveSize) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $STORAGE_STRING
                $outObject.logging += $logFormatWithBlob -f $STORAGE_STRING, "Storage is null", $FAIL_STRING
                $exitCode = 1
            }
            elseif ($osDriveSize.SizeGB -lt $MinOSDiskSizeGB) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $STORAGE_STRING
                $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
                $exitCode = 1
            }
            else {
                $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $PASS_STRING
                UpdateReturnCode -ReturnCode 0
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        try {
            $memory = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{Name="SizeGB"; Expression={$_.Sum / 1GB -as [int]}}

            if ($null -eq $memory) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
                $outObject.logging += $logFormatWithBlob -f $MEMORY_STRING, "Memory is null", $FAIL_STRING
                $exitCode = 1
            }
            elseif ($memory.SizeGB -lt $MinMemoryGB) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
                $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
                $exitCode = 1
            }
            else {
                $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $PASS_STRING
                UpdateReturnCode -ReturnCode 0
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        try {
            $tpm = Get-Tpm

            if ($null -eq $tpm) {
                UpdateReturnCode -ReturnCode 1
                $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                $outObject.logging += $logFormatWithBlob -f $TPM_STRING, "TPM is null", $FAIL_STRING
                $exitCode = 1
            }
            elseif ($tpm.TpmPresent) {
                $tpmVersion = Get-CimInstance -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm | Select-Object -Property SpecVersion

                if ($null -eq $tpmVersion.SpecVersion) {
                    UpdateReturnCode -ReturnCode 1
                    $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, "null", $FAIL_STRING
                    $exitCode = 1
                }

                $majorVersion = $tpmVersion.SpecVersion.Split(",")[0] -as [int]
                if ($majorVersion -lt 2) {
                    UpdateReturnCode -ReturnCode 1
                    $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $FAIL_STRING
                    $exitCode = 1
                }
                else {
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $PASS_STRING
                    UpdateReturnCode -ReturnCode 0
                }
            }
            else {
                if ($tpm.GetType().Name -eq "String") {
                    UpdateReturnCode -ReturnCode -1
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
                    $outObject.logging += $logFormatException -f $tpm
                }
                else {
                    UpdateReturnCode -ReturnCode 1
                    $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
                    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpm.TpmPresent), $FAIL_STRING
                }
                $exitCode = 1
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        $cpuDetails = $null
        try {
            $cpuDetails = @(Get-CimInstance -Class Win32_Processor)[0]

            if ($null -eq $cpuDetails) {
                UpdateReturnCode -ReturnCode 1
                $exitCode = 1
                $outObject.returnReason += $logFormatReturnReason -f $PROCESSOR_STRING
                $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, "CpuDetails is null", $FAIL_STRING
            }
            else {
                $processorCheckFailed = $false

                if ($null -eq $cpuDetails.AddressWidth -or $cpuDetails.AddressWidth -ne $RequiredAddressWidth) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }

                if ($null -eq $cpuDetails.MaxClockSpeed -or $cpuDetails.MaxClockSpeed -le $MinClockSpeedMHz) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }

                if ($null -eq $cpuDetails.NumberOfLogicalProcessors -or $cpuDetails.NumberOfLogicalProcessors -lt $MinLogicalCores) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }

                Add-Type -TypeDefinition $Source
                $cpuFamilyResult = [CpuFamily]::Validate([String]$cpuDetails.Manufacturer, [uint16]$cpuDetails.Architecture)

                $cpuDetailsLog = "{AddressWidth=$($cpuDetails.AddressWidth); MaxClockSpeed=$($cpuDetails.MaxClockSpeed); NumberOfLogicalCores=$($cpuDetails.NumberOfLogicalProcessors); Manufacturer=$($cpuDetails.Manufacturer); Caption=$($cpuDetails.Caption); $($cpuFamilyResult.Message)}"

                if (!$cpuFamilyResult.IsValid) {
                    UpdateReturnCode -ReturnCode 1
                    $processorCheckFailed = $true
                    $exitCode = 1
                }

                if ($processorCheckFailed) {
                    $outObject.returnReason += $logFormatReturnReason -f $PROCESSOR_STRING
                    $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $FAIL_STRING
                }
                else {
                    $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $PASS_STRING
                    UpdateReturnCode -ReturnCode 0
                }
            }
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $PROCESSOR_STRING, $PROCESSOR_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        try {
            $isSecureBootEnabled = Confirm-SecureBootUEFI
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $CAPABLE_STRING, $PASS_STRING
            UpdateReturnCode -ReturnCode 0
        }
        catch [System.PlatformNotSupportedException] {
            UpdateReturnCode -ReturnCode 1
            $outObject.returnReason += $logFormatReturnReason -f $SECUREBOOT_STRING
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $NOT_CAPABLE_STRING, $FAIL_STRING
            $exitCode = 1
        }
        catch [System.UnauthorizedAccessException] {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }
        catch {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
            $exitCode = 1
        }

        try {
            $supportedDevices = @('surface studio 2', 'precision 5520')
            $systemInfo = @(Get-CimInstance -Class Win32_ComputerSystem)[0]

            if ($null -ne $cpuDetails) {
                if ($cpuDetails.Name -match 'i7-7820hq cpu @ 2.90ghz') {
                    $modelOrSKUCheckLog = $systemInfo.Model.Trim()
                    if ($supportedDevices -contains $modelOrSKUCheckLog) {
                        $outObject.logging += $logFormatWithBlob -f $I7_7820HQ_CPU_STRING, $modelOrSKUCheckLog, $PASS_STRING
                        $outObject.returnCode = 0
                        $exitCode = 0
                    }
                }
            }
        }
        catch {
            if ($outObject.returnCode -ne 0) {
                UpdateReturnCode -ReturnCode -1
                $outObject.logging += $logFormatWithBlob -f $I7_7820HQ_CPU_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
                $outObject.logging += $logFormatException -f "$($_.Exception.GetType().Name) $($_.Exception.Message)"
                $exitCode = 1
            }
        }

        Switch ($outObject.returnCode) {
            0 { $outObject.returnResult = $CAPABLE_CAPS_STRING }
            1 { $outObject.returnResult = $NOT_CAPABLE_CAPS_STRING }
            -1 { $outObject.returnResult = $UNDETERMINED_CAPS_STRING }
            -2 { $outObject.returnResult = $FAILED_TO_RUN_STRING }
        }

        $outObject | ConvertTo-Json -Compress
    }
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        if ($env:customFieldName -and $env:customFieldName -notlike "null") { 
            $CustomField = $env:customFieldName
            Write-Log "Using custom field from environment: $CustomField" -Level INFO
        }
        
        Write-Log "Executing Windows 11 hardware readiness checks..." -Level INFO
        $Result = Get-HardwareReadiness | Select-Object -Unique | ConvertFrom-Json

        Switch ($Result.returnCode) {
            0 { 
                Ninja-Property-Set $CustomField "Capable"
                Write-Log "System is CAPABLE of Windows 11 upgrade" -Level SUCCESS
            }
            1 { 
                Ninja-Property-Set $CustomField "Not Capable"
                Write-Log "System is NOT CAPABLE of Windows 11 upgrade" -Level WARN
            }
            -1 { 
                Ninja-Property-Set $CustomField "Undetermined"
                Write-Log "Windows 11 compatibility is UNDETERMINED" -Level WARN
            }
            -2 { 
                Ninja-Property-Set $CustomField "Failed To Run"
                Write-Log "Windows 11 compatibility check FAILED TO RUN" -Level ERROR
            }
            default { 
                Ninja-Property-Set $CustomField "Unknown"
                Write-Log "Unknown compatibility result code: $($Result.returnCode)" -Level ERROR
            }
        }

        Write-Log "Result: $($Result.returnResult)" -Level INFO
        
        if ($Result.returnReason) {
            Write-Log "Failed Requirements: $($Result.returnReason)" -Level WARN
        }
        
        Write-Log "Detailed Hardware Checks:" -Level INFO
        Write-Output $Result.logging
        
        $script:ExitCode = $Result.returnCode
        
    } catch {
        Write-Log "Windows 11 compatibility check failed: $($_.Exception.Message)" -Level ERROR
        Ninja-Property-Set $CustomField "Failed To Run"
        $script:ExitCode = -2
    }
}

end {
    try {
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
