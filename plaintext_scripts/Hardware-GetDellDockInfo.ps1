#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Retrieves Dell docking station information using Dell System Inventory Agent

.DESCRIPTION
    Comprehensive Dell dock detection script that uses Dell System Inventory Agent
    (DSIA) to query connected Dell docking stations. DSIA provides access to hardware
    inventory data through WMI namespaces that standard Windows APIs cannot access.
    
    The script performs the following operations:
    - Checks for existing DSIA installation
    - Downloads and installs DSIA if not present
    - Queries Dell WMI namespace for docking station data
    - Extracts dock model, serial number, and firmware information
    - Automatically uninstalls DSIA if it was temporarily installed
    - Supports WD19, WD19S, WD19DC, and WD19DCS dock models
    - Optionally saves dock information to NinjaRMM custom fields
    
    DSIA (Dell System Inventory Agent) is a lightweight agent that exposes Dell
    hardware inventory through WMI. It creates the root\dell\sysinv namespace
    with classes like dell_softwareidentity for peripheral enumeration.
    
    The script handles DSIA lifecycle management:
    1. Detect if DSIA is already installed
    2. Download latest DSIA from Dell's catalog if needed
    3. Install silently with logging
    4. Query dock information
    5. Uninstall DSIA if we installed it (cleanup)
    
    Dock models detected:
    - WD19: Standard USB-C dock
    - WD19S: Slim USB-C dock
    - WD19DC: Dual USB-C dock
    - WD19DCS: Dual USB-C slim dock

.PARAMETER DockModelField
    Name of NinjaRMM custom field to store detected dock model.

.PARAMETER DockSerialField
    Name of NinjaRMM custom field to store dock serial number.

.PARAMETER KeepDSIA
    If specified, does not uninstall DSIA after querying (useful for repeated queries).

.EXAMPLE
    .\Hardware-GetDellDockInfo.ps1
    
    Detects Dell docks and displays information only.

.EXAMPLE
    .\Hardware-GetDellDockInfo.ps1 -DockModelField "dellDockModel" -DockSerialField "dellDockSerial"
    
    Detects docks and saves model and serial to custom fields.

.EXAMPLE
    .\Hardware-GetDellDockInfo.ps1 -KeepDSIA
    
    Installs DSIA and leaves it installed for future queries.

.NOTES
    Script Name:    Hardware-GetDellDockInfo.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    Original:       Based on Andrew J. Larson's DSIA-Get-Docks-Example.ps1
    
    Execution Context: Administrator (required for DSIA installation and WMI queries)
    Execution Frequency: Daily or on-demand
    Typical Duration: ~30-60 seconds (first run with DSIA install), ~5 seconds (subsequent)
    Timeout Setting: 120 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - DockModelField - Detected Dell dock model (if specified)
        - DockSerialField - Dock serial number (if specified)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges
        - Windows 10 or Server 2016 minimum
        - Internet access (for DSIA download if needed)
        - Dell hardware (script exits gracefully on non-Dell systems)
    
    External Software:
        - Dell System Inventory Agent (DSIA) - auto-installed if needed
    
    Exit Codes:
        0 - Success (docks detected or not found)
        1 - Failure (installation failed or query error)

.LINK
    https://github.com/Xore/waf

.LINK
    https://github.com/Andrew-J-Larson/OS-Scripts/blob/main/Windows/Dell/DSIA-Get-Docks-Example.ps1
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Custom field for dock model")]
    [string]$DockModelField,
    
    [Parameter(Mandatory=$false, HelpMessage="Custom field for dock serial number")]
    [string]$DockSerialField,
    
    [Parameter(Mandatory=$false, HelpMessage="Keep DSIA installed after query")]
    [switch]$KeepDSIA
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "3.0"
$ScriptName = "Hardware-GetDellDockInfo"

# DSIA configuration
$DSIACatalogURL = "https://downloads.dell.com/catalog/DellSDPCatalogPC.cab"
$DSIANameRegex = '^Dell (OpenManage|(Client )?System) Inventory Agent.*$'
$DSIAWMINamespace = "root\dell\sysinv"
$DSIAWMIClass = "dell_softwareidentity"

# Supported dock models (regex pattern)
$DockModelPattern = '^.*WD19(DC)?S?.*$'

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
$script:DSIAInstalled = $false
$script:DSIAWasPreInstalled = $false
$script:CLIFallbackCount = 0

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes structured log messages with plain text output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG','INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Output $LogMessage
    
    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++ }
    }
}

function Set-NinjaField {
    <#
    .SYNOPSIS
        Sets a NinjaRMM custom field value with automatic fallback to CLI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FieldName,
        
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Value
    )
    
    if ($null -eq $Value -or $Value -eq "") {
        Write-Log "Skipping field '$FieldName' - no value" -Level DEBUG
        return
    }
    
    $ValueString = $Value.ToString()
    
    try {
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $FieldName $ValueString -ErrorAction Stop
            Write-Log "Field '$FieldName' set successfully" -Level DEBUG
            return
        } else {
            throw "Ninja-Property-Set cmdlet not available"
        }
    } catch {
        Write-Log "Ninja-Property-Set failed, using CLI fallback" -Level DEBUG
        
        try {
            if (-not (Test-Path $NinjaRMMCLI)) {
                throw "NinjaRMM CLI not found at: $NinjaRMMCLI"
            }
            
            $CLIArgs = @("set", $FieldName, $ValueString)
            $CLIResult = & $NinjaRMMCLI $CLIArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "CLI exit code: $LASTEXITCODE, Output: $CLIResult"
            }
            
            Write-Log "Field '$FieldName' set via CLI" -Level DEBUG
            $script:CLIFallbackCount++
            
        } catch {
            Write-Log "Failed to set field '$FieldName': $_" -Level ERROR
        }
    }
}

function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if script is running with Administrator privileges
    #>
    $Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsDellSystem {
    <#
    .SYNOPSIS
        Checks if the system is manufactured by Dell
    #>
    try {
        $Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        return ($Manufacturer -like "*Dell*")
    } catch {
        Write-Log "Failed to determine manufacturer: $_" -Level WARN
        return $false
    }
}

function Test-DSIAInstalled {
    <#
    .SYNOPSIS
        Checks if DSIA is already installed
    #>
    try {
        $WMIData = Get-CimInstance -Namespace $DSIAWMINamespace -ClassName $DSIAWMIClass -ErrorAction SilentlyContinue
        return ($null -ne $WMIData)
    } catch {
        return $false
    }
}

function Install-DSIA {
    <#
    .SYNOPSIS
        Downloads and installs Dell System Inventory Agent
    #>
    try {
        Write-Log "Downloading DSIA catalog from Dell" -Level INFO
        
        $TempPath = [System.IO.Path]::GetTempPath()
        $CABFile = Join-Path $TempPath "DellSDPCatalogPC.cab"
        $XMLFile = Join-Path $TempPath "DellSDPCatalogPC.xml"
        $LogFile = Join-Path $TempPath "DSIA_Install.log"
        
        # Download catalog CAB
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $DSIACatalogURL -OutFile $CABFile -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        Write-Log "Extracting catalog XML" -Level DEBUG
        
        # Extract XML from CAB
        $ExtractArgs = "/Y /L `"$TempPath`" `"$CABFile`" `"DellSDPCatalogPC.xml`""
        $ExtractProcess = Start-Process 'extrac32.exe' -ArgumentList $ExtractArgs -Wait -PassThru -NoNewWindow
        
        if ($ExtractProcess.ExitCode -ne 0) {
            throw "Failed to extract catalog XML (exit code: $($ExtractProcess.ExitCode))"
        }
        
        # Parse XML to find DSIA MSI URL
        [xml]$CatalogXML = Get-Content -Path $XMLFile
        
        $DSIAPackage = $CatalogXML.SystemsManagementCatalog.SoftwareDistributionPackage | 
            Where-Object { $_.LocalizedProperties.Title -match $DSIANameRegex } | 
            Select-Object -First 1
        
        if (-not $DSIAPackage) {
            throw "DSIA package not found in catalog"
        }
        
        $MSIURL = $DSIAPackage.InstallableItem.OriginFile.OriginUri
        Write-Log "DSIA MSI URL: $MSIURL" -Level DEBUG
        
        Write-Log "Installing DSIA (this may take 30-60 seconds)" -Level INFO
        
        # Install DSIA from URL
        $InstallArgs = "/i `"$MSIURL`" /qn /norestart /l*v `"$LogFile`""
        $InstallProcess = Start-Process 'msiexec.exe' -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
        
        $SuccessCodes = @(0, 1641, 3010)
        
        if ($SuccessCodes -contains $InstallProcess.ExitCode) {
            Write-Log "DSIA installed successfully" -Level SUCCESS
            
            # Wait for WMI namespace to become available
            Write-Log "Waiting for DSIA WMI namespace" -Level DEBUG
            $MaxWait = 30
            $Waited = 0
            
            while ($Waited -lt $MaxWait) {
                if (Test-DSIAInstalled) {
                    Write-Log "DSIA WMI namespace is ready" -Level SUCCESS
                    $script:DSIAInstalled = $true
                    break
                }
                Start-Sleep -Seconds 2
                $Waited += 2
            }
            
            if (-not $script:DSIAInstalled) {
                throw "DSIA installed but WMI namespace not available after $MaxWait seconds"
            }
            
        } else {
            throw "DSIA installation failed (exit code: $($InstallProcess.ExitCode)). Check log: $LogFile"
        }
        
        # Cleanup temporary files
        Remove-Item $CABFile, $XMLFile -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Log "DSIA installation failed: $_" -Level ERROR
        throw
    }
}

function Uninstall-DSIA {
    <#
    .SYNOPSIS
        Removes Dell System Inventory Agent
    #>
    try {
        Write-Log "Uninstalling DSIA" -Level INFO
        
        $Apps = @()
        $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
        $Apps += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
        
        $DSIA = $Apps | Where-Object { 
            $_.DisplayName -and ($_.DisplayName -match $DSIANameRegex) -and $_.UninstallString 
        } | Sort-Object -Property InstallDate -Descending | Select-Object -First 1
        
        if ($DSIA) {
            # Extract product code from uninstall string
            if ($DSIA.UninstallString -match '{[0-9A-F-]+}') {
                $ProductCode = $Matches[0]
                
                $UninstallArgs = "/x $ProductCode /qn /norestart"
                $UninstallProcess = Start-Process 'msiexec.exe' -ArgumentList $UninstallArgs -Wait -PassThru -NoNewWindow
                
                if ($UninstallProcess.ExitCode -eq 0) {
                    Write-Log "DSIA uninstalled successfully" -Level SUCCESS
                } else {
                    Write-Log "DSIA uninstall exit code: $($UninstallProcess.ExitCode)" -Level WARN
                }
            } else {
                Write-Log "Could not parse DSIA uninstall string" -Level WARN
            }
        } else {
            Write-Log "DSIA not found in installed programs" -Level DEBUG
        }
        
    } catch {
        Write-Log "DSIA uninstallation failed: $_" -Level WARN
    }
}

function Get-DellDocks {
    <#
    .SYNOPSIS
        Queries DSIA for connected Dell docking stations
    #>
    try {
        Write-Log "Querying DSIA for Dell docking stations" -Level INFO
        
        $AllDevices = Get-CimInstance -Namespace $DSIAWMINamespace -ClassName $DSIAWMIClass -ErrorAction Stop
        
        $Docks = $AllDevices | Where-Object { 
            $_.ElementName -and ($_.ElementName -match $DockModelPattern) 
        }
        
        if ($Docks) {
            Write-Log "Found $($Docks.Count) Dell dock(s)" -Level SUCCESS
            return $Docks
        } else {
            Write-Log "No Dell docks detected" -Level INFO
            return $null
        }
        
    } catch {
        Write-Log "Failed to query for docks: $_" -Level ERROR
        throw
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check administrator privileges
    if (-not (Test-IsElevated)) {
        throw "Administrator privileges required for DSIA installation and queries"
    }
    Write-Log "Administrator privileges confirmed" -Level SUCCESS
    
    # Check if system is Dell
    if (-not (Test-IsDellSystem)) {
        Write-Log "System is not manufactured by Dell, exiting" -Level INFO
        exit 0
    }
    Write-Log "Dell system detected" -Level SUCCESS
    
    # Check if DSIA is already installed
    $script:DSIAWasPreInstalled = Test-DSIAInstalled
    
    if ($script:DSIAWasPreInstalled) {
        Write-Log "DSIA is already installed" -Level INFO
        $script:DSIAInstalled = $true
    } else {
        Write-Log "DSIA not found, installing" -Level INFO
        Install-DSIA
    }
    
    # Query for docks
    $Docks = Get-DellDocks
    
    if ($Docks) {
        Write-Log "" -Level INFO
        Write-Log "Dell Dock Information:" -Level INFO
        Write-Log "=====================" -Level INFO
        
        foreach ($Dock in $Docks) {
            Write-Log "" -Level INFO
            Write-Log "Model: $($Dock.ElementName)" -Level INFO
            Write-Log "Serial: $($Dock.SerialNumber)" -Level INFO
            
            if ($Dock.VersionString) {
                Write-Log "Firmware: $($Dock.VersionString)" -Level INFO
            }
        }
        
        # Update custom fields if specified
        if ($DockModelField -or $DockSerialField) {
            Write-Log "" -Level INFO
            
            # Use first dock for fields (most common scenario is single dock)
            $PrimaryDock = $Docks | Select-Object -First 1
            
            if ($DockModelField) {
                Set-NinjaField -FieldName $DockModelField -Value $PrimaryDock.ElementName
                Write-Log "Dock model saved to field: $DockModelField" -Level SUCCESS
            }
            
            if ($DockSerialField) {
                Set-NinjaField -FieldName $DockSerialField -Value $PrimaryDock.SerialNumber
                Write-Log "Dock serial saved to field: $DockSerialField" -Level SUCCESS
            }
        }
    } else {
        Write-Log "No Dell docks detected on this system" -Level INFO
        
        if ($DockModelField) {
            Set-NinjaField -FieldName $DockModelField -Value "No dock detected"
        }
        if ($DockSerialField) {
            Set-NinjaField -FieldName $DockSerialField -Value "N/A"
        }
    }
    
    # Cleanup: Uninstall DSIA if we installed it (unless KeepDSIA flag set)
    if ($script:DSIAInstalled -and -not $script:DSIAWasPreInstalled -and -not $KeepDSIA) {
        Write-Log "" -Level INFO
        Uninstall-DSIA
    }
    
    Write-Log "Dock detection completed successfully" -Level SUCCESS
    exit 0
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    # Attempt cleanup on error
    if ($script:DSIAInstalled -and -not $script:DSIAWasPreInstalled) {
        Write-Log "Attempting DSIA cleanup after error" -Level INFO
        Uninstall-DSIA
    }
    
    exit 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  DSIA Pre-installed: $script:DSIAWasPreInstalled" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
}
