<#
.SYNOPSIS
    Repair the trust relationship between a computer and its domain

.DESCRIPTION
    Tests and repairs the secure channel between the local computer and its Active Directory domain.
    This is useful when trust relationship errors occur, preventing domain authentication.
    Requires domain administrator credentials.

.EXAMPLE
    .\AD-RepairTrust.ps1

.NOTES
    Author: WAF Team
    Version: 2.0
    Requires: Administrator privileges, Computer must be domain-joined
    Environment Variables Required:
        - $env:user (domain admin username)
        - $env:pass (domain admin password)

.LINK
    https://github.com/Xore/waf
#>

# Phase 2: Execution time tracking
$StartTime = Get-Date

# Phase 1 & 3: Write-Log function for plain text output
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Output "[$Timestamp] [$Level] $Message"
}

try {
    Write-Log "Starting domain trust repair process" -Level INFO
    
    # Phase 3: Input validation
    if ([string]::IsNullOrWhiteSpace($env:user)) {
        throw "Environment variable 'user' is not set or empty"
    }
    
    if ([string]::IsNullOrWhiteSpace($env:pass)) {
        throw "Environment variable 'pass' is not set or empty"
    }
    
    Write-Log "Username: $env:user" -Level INFO
    
    # Verify computer is domain-joined
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
    if (-not $ComputerSystem.PartOfDomain) {
        throw "Computer is not joined to a domain"
    }
    
    $DomainName = $ComputerSystem.Domain
    Write-Log "Domain: $DomainName" -Level INFO
    
    # Create credentials
    Write-Log "Creating domain credentials" -Level DEBUG
    $SecurePassword = ConvertTo-SecureString -String $env:pass -AsPlainText -Force
    $JoinCred = [PSCredential]::new($env:user, $SecurePassword)
    
    # Test secure channel first
    Write-Log "Testing current secure channel status" -Level INFO
    $ChannelTest = Test-ComputerSecureChannel -ErrorAction SilentlyContinue
    
    if ($ChannelTest) {
        Write-Log "Secure channel is currently functional" -Level INFO
        Write-Log "Attempting repair anyway as requested" -Level INFO
    }
    else {
        Write-Log "Secure channel is broken - repair needed" -Level WARN
    }
    
    # Repair secure channel
    Write-Log "Repairing secure channel with domain controller" -Level INFO
    $RepairResult = Test-ComputerSecureChannel -Repair -Credential $JoinCred -ErrorAction Stop
    
    if ($RepairResult) {
        Write-Log "SUCCESS: Secure channel repaired successfully" -Level SUCCESS
        Write-Log "Trust relationship with domain '$DomainName' is now functional" -Level SUCCESS
    }
    else {
        throw "Repair operation returned false"
    }
    
    exit 0
}
catch {
    Write-Log "ERROR: Failed to repair trust relationship - $($_.Exception.Message)" -Level ERROR
    Write-Log "Verify domain admin credentials and domain controller connectivity" -Level ERROR
    Write-Log "If issue persists, consider removing and rejoining the domain" -Level INFO
    exit 1
}
finally {
    # Phase 2: Log execution time
    $Duration = (Get-Date) - $StartTime
    Write-Log "Script execution completed in $($Duration.TotalSeconds.ToString('F2')) seconds" -Level INFO
}
