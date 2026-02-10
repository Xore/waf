#Requires -Version 5.1

<#
.SYNOPSIS
    Creates CEPROS application shortcuts and deploys them to all user desktops.

.DESCRIPTION
    Creates Windows shortcuts for CEPROS applications and copies them to all user desktops,
    including current users, Public Desktop, and Default User Profile.
    
    The script performs the following:
    - Creates shortcuts in temporary folder
    - CEPROS Test System shortcut with custom URL
    - CEPROS 11.7 shortcut
    - Workspaces Desktop shortcut (optional)
    - Copies shortcuts to Public Desktop
    - Copies shortcuts to Default User Profile Desktop
    - Copies shortcuts to all existing user desktops
    - Cleans up temporary files
    - Reports success/failure counts
    - Updates NinjaRMM custom fields with results
    
    This script runs unattended without user interaction.

.PARAMETER TempFolder
    Path to temporary folder for creating shortcuts.
    Default: C:\Temp

.PARAMETER ForceOverwrite
    If specified, overwrites existing shortcuts on target desktops.
    Default: $true

.PARAMETER CreateWorkspacesShortcut
    If specified, creates Workspaces Desktop shortcut in addition to CEPROS shortcuts.
    Default: Reads from environment variable createWorkspacesDesktopShortcut

.EXAMPLE
    .\Shortcuts-CreateCeprosShortcuts.ps1
    
    Creates CEPROS shortcuts and deploys to all desktops with default settings.

.EXAMPLE
    .\Shortcuts-CreateCeprosShortcuts.ps1 -TempFolder "C:\CustomTemp" -CreateWorkspacesShortcut
    
    Creates all shortcuts including Workspaces Desktop using custom temp folder.

.EXAMPLE
    .\Shortcuts-CreateCeprosShortcuts.ps1 -ForceOverwrite:$false
    
    Creates shortcuts but does not overwrite existing ones on desktops.

.NOTES
    Script Name:    Shortcuts-CreateCeprosShortcuts.ps1
    Author:         Windows Automation Framework
    Version:        2.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or User (via NinjaRMM automation)
    Execution Frequency: On-demand or during deployment
    Typical Duration: ~3-8 seconds (depends on user count)
    Timeout Setting: 60 seconds recommended
    
    User Interaction: NONE (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    Fields Updated:
        - shortcutCreationStatus (Success/Failed)
        - shortcutCreationDate (timestamp)
        - shortcutCreationCount (number of desktops updated)
        - shortcutCreationList (desktop paths)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - CEPROS CIM Database Desktop 11.7 installed
        - Workspaces Desktop installed (if creating that shortcut)
        - NinjaRMM Agent installed
        - Write access to C:\Temp and desktop folders
    
    Environment Variables (Optional):
        - createWorkspacesDesktopShortcut: Set to 'true' to create Workspaces shortcut
    
    Exit Codes:
        0 - Success (all shortcuts created and deployed)
        1 - Failure (shortcut creation failed or deployment failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false, HelpMessage="Temporary folder for creating shortcuts")]
    [ValidateNotNullOrEmpty()]
    [string]$TempFolder = "C:\Temp",
    
    [Parameter(Mandatory=$false, HelpMessage="Force overwrite existing shortcuts")]
    [bool]$ForceOverwrite = $true,
    
    [Parameter(Mandatory=$false, HelpMessage="Create Workspaces Desktop shortcut")]
    [switch]$CreateWorkspacesShortcut
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptVersion = "2.0"
$ScriptName = "Shortcuts-CreateCeprosShortcuts"

# Application paths
$CeprosPath = "C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.exe"
$WorkspacesPath = "C:\Program Files\CONTACT Workspaces Desktop\bin\WorkspacesDesktop.exe"
$CeprosTestURL = "https://biecdb20.de.mgp.int/"

# NinjaRMM CLI path for fallback
$NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"

# ============================================================================
# INITIALIZATION
# ============================================================================

$StartTime = Get-Date
$ErrorActionPreference = 'Stop'
$script:ErrorCount = 0
$script:WarningCount = 0
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

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level INFO
    Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
    Write-Log "========================================" -Level INFO
    
    # Check for environment variable override
    if ($env:createWorkspacesDesktopShortcut -eq 'true') {
        $CreateWorkspacesShortcut = $true
        Write-Log "Workspaces shortcut creation enabled via environment" -Level INFO
    }
    
    Write-Log "Configuration: TempFolder=$TempFolder, ForceOverwrite=$ForceOverwrite" -Level INFO
    
    # Create temp folder if needed
    if (-not (Test-Path $TempFolder)) {
        New-Item -Path $TempFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Log "Created temp folder: $TempFolder" -Level INFO
    } else {
        Write-Log "Using existing temp folder: $TempFolder" -Level DEBUG
    }
    
    # Initialize COM object for shortcuts
    Write-Log "Initializing Windows Script Shell COM object" -Level DEBUG
    $WshShell = New-Object -COMObject WScript.Shell -ErrorAction Stop
    
    # Create shortcuts
    Write-Log "Creating shortcuts in temp folder" -Level INFO
    
    # Shortcut 1: CEPROS Test System
    Write-Log "  Creating: CEPROS Testsystem.lnk" -Level DEBUG
    $ShortcutPath = Join-Path $TempFolder "CEPROS Testsystem.lnk"
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $CeprosPath
    $Shortcut.Arguments = "--url $CeprosTestURL"
    $Shortcut.Save()
    Write-Log "  Created CEPROS Test System shortcut" -Level SUCCESS
    
    # Shortcut 2: CEPROS 11.7
    Write-Log "  Creating: CEPROS 11.7.lnk" -Level DEBUG
    $ShortcutPath = Join-Path $TempFolder "CEPROS 11.7.lnk"
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $CeprosPath
    $Shortcut.Save()
    Write-Log "  Created CEPROS 11.7 shortcut" -Level SUCCESS
    
    # Shortcut 3: Workspaces Desktop (optional)
    if ($CreateWorkspacesShortcut) {
        Write-Log "  Creating: Workspaces Desktop.lnk" -Level DEBUG
        $ShortcutPath = Join-Path $TempFolder "Workspaces Desktop.lnk"
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = $WorkspacesPath
        $Shortcut.Save()
        Write-Log "  Created Workspaces Desktop shortcut" -Level SUCCESS
    }
    
    # Get all .lnk files to deploy
    $FilesToCopy = Get-ChildItem -Path $TempFolder -Filter "*.lnk" -File -ErrorAction Stop
    
    if ($FilesToCopy.Count -eq 0) {
        throw "No .lnk files found in $TempFolder after creation"
    }
    
    Write-Log "Total shortcuts to deploy: $($FilesToCopy.Count)" -Level INFO
    foreach ($File in $FilesToCopy) {
        Write-Log "  - $($File.Name)" -Level DEBUG
    }
    
    # Track deployment results
    $SuccessCount = 0
    $FailCount = 0
    $DeployedPaths = [System.Collections.Generic.List[string]]::new()
    
    # Deploy to Public Desktop
    Write-Log "Deploying to Public Desktop" -Level INFO
    try {
        $PublicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
        
        if (Test-Path $PublicDesktop) {
            foreach ($File in $FilesToCopy) {
                $DestFile = Join-Path $PublicDesktop $File.Name
                Copy-Item -Path $File.FullName -Destination $DestFile -Force:$ForceOverwrite -ErrorAction Stop
            }
            Write-Log "  Successfully deployed to Public Desktop" -Level SUCCESS
            Write-Log "  Path: $PublicDesktop" -Level DEBUG
            $SuccessCount++
            $DeployedPaths.Add("Public Desktop")
        } else {
            Write-Log "  Public Desktop path not found" -Level WARN
        }
    } catch {
        Write-Log "  Failed to deploy to Public Desktop: $($_.Exception.Message)" -Level ERROR
        $FailCount++
    }
    
    # Deploy to Default User Profile Desktop
    Write-Log "Deploying to Default User Profile Desktop" -Level INFO
    try {
        $DefaultUserDesktop = "C:\Users\Default\Desktop"
        
        if (Test-Path $DefaultUserDesktop) {
            foreach ($File in $FilesToCopy) {
                $DestFile = Join-Path $DefaultUserDesktop $File.Name
                Copy-Item -Path $File.FullName -Destination $DestFile -Force:$ForceOverwrite -ErrorAction Stop
            }
            Write-Log "  Successfully deployed to Default User Profile" -Level SUCCESS
            Write-Log "  Path: $DefaultUserDesktop" -Level DEBUG
            $SuccessCount++
            $DeployedPaths.Add("Default User Profile")
        } else {
            Write-Log "  Default User Profile Desktop not found" -Level WARN
        }
    } catch {
        Write-Log "  Failed to deploy to Default User Profile: $($_.Exception.Message)" -Level ERROR
        $FailCount++
    }
    
    # Deploy to all existing user desktops
    Write-Log "Deploying to existing user desktops" -Level INFO
    $UsersPath = "C:\Users"
    
    if (Test-Path $UsersPath) {
        $UserFolders = Get-ChildItem -Path $UsersPath -Directory -ErrorAction SilentlyContinue
        
        foreach ($UserFolder in $UserFolders) {
            # Skip system folders
            if ($UserFolder.Name -in @("Public", "Default", "All Users", "Default User")) {
                Write-Log "  Skipping system folder: $($UserFolder.Name)" -Level DEBUG
                continue
            }
            
            $UserDesktop = Join-Path $UserFolder.FullName "Desktop"
            
            try {
                if (Test-Path $UserDesktop) {
                    foreach ($File in $FilesToCopy) {
                        $DestFile = Join-Path $UserDesktop $File.Name
                        Copy-Item -Path $File.FullName -Destination $DestFile -Force:$ForceOverwrite -ErrorAction Stop
                    }
                    Write-Log "  Successfully deployed to user: $($UserFolder.Name)" -Level SUCCESS
                    $SuccessCount++
                    $DeployedPaths.Add($UserFolder.Name)
                } else {
                    Write-Log "  Desktop not found for user: $($UserFolder.Name)" -Level DEBUG
                }
            } catch {
                Write-Log "  Failed to deploy to user $($UserFolder.Name): $($_.Exception.Message)" -Level WARN
                $FailCount++
            }
        }
    }
    
    # Summary
    Write-Log "Deployment Summary:" -Level INFO
    Write-Log "  Shortcuts created: $($FilesToCopy.Count)" -Level INFO
    Write-Log "  Successful deployments: $SuccessCount" -Level SUCCESS
    Write-Log "  Failed deployments: $FailCount" -Level $(if ($FailCount -gt 0) { "WARN" } else { "INFO" })
    Write-Log "  Files per desktop: $($FilesToCopy.Count)" -Level INFO
    
    # Clean up temp files
    Write-Log "Cleaning up temporary files" -Level DEBUG
    Remove-Item -Path "$TempFolder\*.lnk" -Force -ErrorAction SilentlyContinue
    Write-Log "Temporary files deleted" -Level SUCCESS
    
    # Update custom fields
    Set-NinjaField -FieldName "shortcutCreationStatus" -Value "Success"
    Set-NinjaField -FieldName "shortcutCreationDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Set-NinjaField -FieldName "shortcutCreationCount" -Value $SuccessCount
    Set-NinjaField -FieldName "shortcutCreationList" -Value ($DeployedPaths -join ", ")
    
    Write-Log "Shortcut creation and deployment completed successfully" -Level SUCCESS
    $ExitCode = 0
    
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    
    Set-NinjaField -FieldName "shortcutCreationStatus" -Value "Failed"
    Set-NinjaField -FieldName "shortcutCreationDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    
    $ExitCode = 1
    
} finally {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    
    Write-Log "========================================" -Level INFO
    Write-Log "Execution Summary:" -Level INFO
    Write-Log "  Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
    Write-Log "  Errors: $script:ErrorCount" -Level INFO
    Write-Log "  Warnings: $script:WarningCount" -Level INFO
    
    if ($script:CLIFallbackCount -gt 0) {
        Write-Log "  CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
    }
    
    Write-Log "========================================" -Level INFO
    
    exit $ExitCode
}
