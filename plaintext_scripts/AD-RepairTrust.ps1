#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Repair the trust relationship between a computer and its Active Directory domain

.DESCRIPTION
    Tests and repairs the secure channel between the local computer and its Active Directory domain.
    This resolves trust relationship errors that prevent domain authentication.
    
    The script performs the following:
    - Validates required environment variables
    - Verifies computer is domain-joined
    - Tests current secure channel status
    - Repairs secure channel using domain credentials
    - Updates NinjaRMM custom fields with repair status
    
    This script runs unattended without user interaction.

.EXAMPLE
    .\AD-RepairTrust.ps1
    
    Tests and repairs the domain trust relationship using credentials
    from environment variables.

.NOTES
    File Name      : AD-RepairTrust.ps1
    Prerequisite   : PowerShell 5.1 or higher, Administrator privileges
    Minimum OS     : Windows 10, Windows Server 2012 R2
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: V3 standards with Set-StrictMode and begin/process/end blocks
    - 3.0: Enhanced logging and error handling
    - 2.0: Added NinjaRMM integration
    - 1.0: Initial release
    
    Execution Context: SYSTEM (via NinjaRMM automation)
    Execution Frequency: On-demand or scheduled
    Typical Duration: 5-8 seconds
    Timeout Setting: 180 seconds recommended
    
    User Interaction: None (fully automated, no prompts)
    Restart Behavior: N/A (no restart required)
    
    NinjaRMM Fields Updated:
        - adTrustRepairStatus (Success/Failed)
        - adTrustRepairDate (timestamp)
        - adDomainName (domain name)
        - adSecureChannelStatus (Functional/Broken)
    
    Dependencies:
        - Windows PowerShell 5.1 or higher
        - Administrator privileges (SYSTEM context)
        - NinjaRMM Agent installed
        - Computer must be domain-joined
        - Network connectivity to domain controller
    
    Environment Variables Required:
        - user: Domain administrator username
        - pass: Domain administrator password
    
    Exit Codes:
        0 - Success (trust repaired or already functional)
        1 - Failure (not domain-joined, repair failed)

.LINK
    https://github.com/Xore/waf
#>

[CmdletBinding()]
param()

begin {
    Set-StrictMode -Version Latest
    
    $ScriptVersion = "3.0.0"
    $ScriptName = "AD-RepairTrust"
    
    $StartTime = Get-Date
    $ErrorActionPreference = 'Continue'
    $script:ErrorCount = 0
    $script:WarningCount = 0
    $script:ExitCode = 0
    $script:CLIFallbackCount = 0
    
    $NinjaRMMCLI = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    
    $script:JoinCred = $null
    $script:SecurePassword = $null

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

    function Set-NinjaField {
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
}

process {
    try {
        Write-Log "========================================" -Level INFO
        Write-Log "Starting: $ScriptName v$ScriptVersion" -Level INFO
        Write-Log "========================================" -Level INFO
        
        Write-Log "Validating environment variables" -Level INFO
        
        if ([string]::IsNullOrWhiteSpace($env:user)) {
            throw "Environment variable 'user' is not set or empty"
        }
        
        if ([string]::IsNullOrWhiteSpace($env:pass)) {
            throw "Environment variable 'pass' is not set or empty"
        }
        
        Write-Log "Username: $env:user" -Level INFO
        
        Write-Log "Checking domain membership status" -Level INFO
        $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        
        if (-not $ComputerSystem.PartOfDomain) {
            throw "Computer is not joined to a domain"
        }
        
        $DomainName = $ComputerSystem.Domain
        Write-Log "Configuration:" -Level INFO
        Write-Log "  Domain: $DomainName" -Level INFO
        Write-Log "  Computer: $($ComputerSystem.Name)" -Level INFO
        
        Write-Log "Creating domain credentials" -Level DEBUG
        $script:SecurePassword = ConvertTo-SecureString -String $env:pass -AsPlainText -Force
        $script:JoinCred = [PSCredential]::new($env:user, $script:SecurePassword)
        
        Write-Log "Testing current secure channel status" -Level INFO
        $ChannelTest = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
        
        if ($ChannelTest) {
            Write-Log "Secure channel is currently functional" -Level INFO
            Write-Log "Attempting repair anyway as requested" -Level INFO
            Set-NinjaField -FieldName "adSecureChannelStatus" -Value "Functional"
        } else {
            Write-Log "Secure channel is broken - repair needed" -Level WARN
            Set-NinjaField -FieldName "adSecureChannelStatus" -Value "Broken"
        }
        
        Write-Log "Repairing secure channel with domain controller" -Level INFO
        $RepairResult = Test-ComputerSecureChannel -Repair -Credential $script:JoinCred -ErrorAction Stop
        
        if ($RepairResult) {
            Write-Log "Secure channel repaired successfully" -Level SUCCESS
            Write-Log "Trust relationship with domain is now functional" -Level SUCCESS
            Write-Log "Domain: $DomainName" -Level INFO
            
            Set-NinjaField -FieldName "adTrustRepairStatus" -Value "Success"
            Set-NinjaField -FieldName "adTrustRepairDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Set-NinjaField -FieldName "adDomainName" -Value $DomainName
            Set-NinjaField -FieldName "adSecureChannelStatus" -Value "Functional"
        } else {
            throw "Repair operation returned false"
        }
        
        Write-Log "Trust repair operation completed" -Level INFO
        $script:ExitCode = 0
        
    } catch {
        Write-Log "Failed to repair trust relationship: $($_.Exception.Message)" -Level ERROR
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
        Write-Log "Verify domain admin credentials and DC connectivity" -Level ERROR
        Write-Log "If issue persists, consider removing and rejoining domain" -Level INFO
        
        Set-NinjaField -FieldName "adTrustRepairStatus" -Value "Failed"
        Set-NinjaField -FieldName "adTrustRepairDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        
        $script:ExitCode = 1
    }
}

end {
    try {
        if ($null -ne $script:JoinCred) {
            $script:JoinCred = $null
            Write-Log "Credential object cleared" -Level DEBUG
        }
        
        if ($null -ne $script:SecurePassword) {
            $script:SecurePassword.Dispose()
            $script:SecurePassword = $null
            Write-Log "SecureString disposed" -Level DEBUG
        }
        
        $EndTime = Get-Date
        $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
        
        Write-Log "========================================" -Level INFO
        Write-Log "Execution Duration: $($ExecutionTime.ToString('F2')) seconds" -Level INFO
        Write-Log "Warnings: $script:WarningCount, Errors: $script:ErrorCount" -Level INFO
        
        if ($script:CLIFallbackCount -gt 0) {
            Write-Log "CLI Fallbacks: $script:CLIFallbackCount" -Level INFO
        }
        
        Write-Log "========================================" -Level INFO
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
