#Requires -Version 2.0

<#
.SYNOPSIS
    Remove computer from Active Directory domain and revert to workgroup

.DESCRIPTION
    Automated domain disjoin operation that removes a Windows computer from its
    current Active Directory domain membership and places it in a workgroup.
    Supports secure credential handling through NinjaRMM custom fields.
    
    Technical Implementation:
    This script uses the Remove-Computer cmdlet to perform domain unjoin operations,
    with enhanced credential management and optional restart control.
    
    Domain Removal Process:
    
    1. Credential Validation:
       - Requires domain administrator credentials
       - Username must have rights to remove computer objects
       - Typically requires Domain Admins or Account Operators group
       - Can use specific delegated permissions for computer object deletion
    
    2. Remove-Computer Cmdlet:
       - PowerShell built-in cmdlet for domain operations
       - Parameters used:
         * -UnjoinDomainCredential: PSCredential object with domain admin rights
         * -PassThru: Returns result object for validation
         * -Force: Suppresses user prompts
         * -Confirm:$false: Disables confirmation dialogs
         * -Restart: Optional automatic restart after unjoin
    
    3. Active Directory Operations:
       - Contacts domain controller to authenticate credentials
       - Disables computer account in Active Directory
       - Removes computer from domain member group
       - Clears secure channel password
       - Removes domain DNS suffix from computer
    
    4. Local System Changes:
       - Updates registry: HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters
       - Removes Domain value from registry
       - Sets workgroup name (default: WORKGROUP)
       - Clears cached domain credentials
       - Removes computer from domain security groups
       - Updates local security policy
    
    Credential Management:
    
    NinjaRMM Integration:
    The script supports two credential input methods:
    
    Method 1: Direct Parameters
    - Username and Password passed as script parameters
    - Less secure but simpler for testing
    - Credentials visible in script execution logs
    
    Method 2: Secure Custom Field (Recommended)
    - Password stored in NinjaRMM secure custom field
    - Retrieved using Get-NinjaProperty function
    - Encrypted at rest in NinjaRMM database
    - Not visible in execution logs
    - Environment variable: domainPasswordWithCustomField
    
    Get-NinjaProperty Function:
    Comprehensive custom field retrieval with support for:
    - Device custom fields
    - Organization custom fields
    - Document custom fields
    - Secure fields (passwords)
    - Multiple data types (text, numbers, dates, dropdowns)
    - Type conversion and validation
    
    Supported Custom Field Types:
    - Secure: Encrypted password fields
    - Text/WYSIWYG: Plain text values
    - Dropdown/MultiSelect: Selection fields
    - Checkbox: Boolean values
    - Date/DateTime: Timestamp fields
    - Integer/Decimal: Numeric values
    - Attachment: File references
    - Device/Organization references
    
    Security Considerations:
    
    Credential Security:
    - PSCredential object prevents plain-text password exposure
    - ConvertTo-SecureString encrypts password in memory
    - Credentials cleared from memory after use ($LeaveCred = $null)
    - Secure custom fields encrypted with AES-256
    - No credential logging to console output
    
    Required Permissions:
    - Domain user with computer object delete rights
    - Typically Domain Admins group membership
    - Or delegated permission on specific OU
    - Computer account must exist in AD
    
    Network Requirements:
    - Network connectivity to domain controller
    - DNS resolution to domain name
    - Firewall allows LDAP (TCP 389) and Kerberos (TCP/UDP 88)
    - RPC dynamic ports for AD communication
    
    Post-Removal State:
    
    Local System Changes:
    - Computer becomes workgroup member
    - Workgroup name: WORKGROUP (default)
    - Local user accounts remain intact
    - Domain cached credentials cleared
    - Domain group policy no longer applies
    - Domain user profiles become orphaned
    
    Active Directory Changes:
    - Computer object disabled (not deleted)
    - Computer remains in AD for 30 days (default tombstone)
    - Can be manually deleted from AD Users and Computers
    - Secure channel broken
    - Cannot authenticate domain users
    
    User Impact:
    - Domain users cannot login after removal
    - Only local accounts can authenticate
    - Roaming profiles inaccessible
    - Network resources requiring domain auth unavailable
    - Group Policy settings revert to local policy
    
    Restart Behavior:
    
    Automatic Restart (-Restart parameter):
    - System reboots immediately after successful unjoin
    - All applications closed without warning
    - No user notification
    - Completes domain removal process
    
    Manual Restart (-NoRestart parameter):
    - Domain removal staged but not completed
    - Requires manual restart to finalize
    - Allows for additional preparation
    - User can save work before restart
    
    Why Restart Required:
    - Windows must reload security subsystem
    - New workgroup membership needs initialization
    - Cached domain credentials must be cleared
    - Local Security Authority (LSA) must reinitialize
    - Network provider order needs update
    
    Common Use Cases:
    
    1. Computer Decommissioning:
       - Preparing system for disposal
       - Removing from corporate network
       - Transitioning to workgroup/home use
    
    2. Domain Migration:
       - Moving between different domains
       - Unjoin old domain before joining new
       - Cleanup during infrastructure changes
    
    3. Troubleshooting:
       - Resolving trust relationship issues
       - Fixing broken secure channel
       - Resetting computer account
    
    4. Redeployment:
       - Repurposing corporate assets
       - Converting to standalone systems
       - Lab/test environment reconfiguration
    
    Troubleshooting:
    
    Common Errors:
    
    1. "The network path was not found":
       - Cannot reach domain controller
       - Check DNS resolution
       - Verify network connectivity
       - Ensure VPN connected if remote
    
    2. "Access is denied":
       - Credentials lack permissions
       - User not in Domain Admins
       - OU permissions insufficient
       - Try different admin account
    
    3. "The trust relationship failed":
       - Secure channel already broken
       - May need to delete from AD first
       - Consider manual AD cleanup
       - Local admin can still unjoin
    
    4. "The specified domain does not exist":
       - DNS cannot resolve domain name
       - Domain controller offline
       - Network connectivity issue
       - Firewall blocking LDAP/Kerberos
    
    Recovery:
    If script fails, computer may be in indeterminate state:
    - Check domain membership: (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    - Verify workgroup: (Get-WmiObject Win32_ComputerSystem).Workgroup
    - Restart and retry if partially completed
    - Manual unjoin via System Properties as fallback

.PARAMETER UserName
    Domain administrator username (can include domain: DOMAIN\username)

.PARAMETER Password
    Domain administrator password (plain text - use secure custom field instead)

.PARAMETER NoRestart
    Prevent automatic restart after domain removal

.EXAMPLE
    .\AD-RemoveComputerFromDomain.ps1 -UserName "CONTOSO\admin" -Password "Pass123!"
    
    Removes computer from CONTOSO domain and restarts immediately.

.EXAMPLE
    .\AD-RemoveComputerFromDomain.ps1 -UserName "admin@contoso.com" -Password "Pass123!" -NoRestart
    
    Removes computer from domain but does not restart (manual restart required).

.EXAMPLE
    Environment Variables:
    domainUsername = "CONTOSO\admin"
    domainPasswordWithCustomField = "DomainAdminPassword"
    
    Retrieves password from secure custom field named "DomainAdminPassword".

.NOTES
    Script Name:    AD-RemoveComputerFromDomain.ps1
    Author:         Windows Automation Framework
    Version:        3.0
    Creation Date:  2024-01-15
    Last Modified:  2026-02-10
    
    Execution Context: SYSTEM or Administrator required
    Execution Frequency: One-time (domain removal operation)
    Typical Duration: 15-60 seconds (plus restart time if enabled)
    Timeout Setting: 180 seconds recommended
    
    User Interaction: NONE (automatic restart if enabled)
    Restart Behavior: Optional automatic restart
    
    NinjaRMM Fields Updated: None
    
    Dependencies:
        - Network connectivity to domain controller
        - Valid domain administrator credentials
        - DNS resolution to domain
        - PowerShell 2.0 or later
    
    Exit Codes:
        0 - Successfully removed from domain
        1 - Failed to remove from domain or missing credentials
    
    WARNING: Computer will no longer be domain-managed after execution
             Domain users cannot login after removal
             Requires manual rejoin to restore domain membership

.LINK
    https://github.com/Xore/waf
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-computer
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [String]$UserName,
    
    [Parameter(Mandatory=$false)]
    $Password,
    
    [Parameter(Mandatory=$false)]
    [Switch]$NoRestart = [System.Convert]::ToBoolean($env:noRestart)
)

# Configuration
$ScriptVersion = "3.0"
$ScriptName = "AD-RemoveComputerFromDomain"

function Get-NinjaProperty {
    <#
    .SYNOPSIS
        Retrieve NinjaRMM custom field values with type conversion
    .DESCRIPTION
        Comprehensive function to retrieve custom field data from NinjaRMM
        with support for multiple field types and automatic type conversion.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String]$Name,
        [Parameter()]
        [String]$Type,
        [Parameter()]
        [String]$DocumentName
    )

    $DocumentationParams = @{}
    if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }

    $NeedsOptions = "DropDown", "MultiSelect"

    if ($DocumentName) {
        if ($Type -Like "Secure") { 
            throw [System.ArgumentOutOfRangeException]::New("$Type is an invalid type! Secure fields only available as device custom fields.")
        }

        $NinjaPropertyValue = Ninja-Property-Docs-Get -AttributeName $Name @DocumentationParams 2>&1

        if ($NeedsOptions -contains $Type) {
            $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
        }
    }
    else {
        $NinjaPropertyValue = Ninja-Property-Get -Name $Name 2>&1

        if ($NeedsOptions -contains $Type) {
            $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
        }
    }

    if ($NinjaPropertyValue.Exception) { throw $NinjaPropertyValue }
    if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }

    if (-not $NinjaPropertyValue) {
        throw [System.NullReferenceException]::New("The Custom Field '$Name' is empty!")
    }

    switch ($Type) {
        "Attachment" { $NinjaPropertyValue | ConvertFrom-Json }
        "Checkbox" { [System.Convert]::ToBoolean([int]$NinjaPropertyValue) }
        "Date or Date Time" {
            $UnixTimeStamp = $NinjaPropertyValue
            $UTC = (Get-Date "1970-01-01 00:00:00").AddSeconds($UnixTimeStamp)
            $TimeZone = [TimeZoneInfo]::Local
            [TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TimeZone)
        }
        "Decimal" { [double]$NinjaPropertyValue }
        "Device Dropdown" { $NinjaPropertyValue | ConvertFrom-Json }
        "Device MultiSelect" { $NinjaPropertyValue | ConvertFrom-Json }
        "Dropdown" {
            $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
            $Options | Where-Object { $_.GUID -eq $NinjaPropertyValue } | Select-Object -ExpandProperty Name
        }
        "Integer" { [int]$NinjaPropertyValue }
        "MultiSelect" {
            $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
            $Selection = ($NinjaPropertyValue -split ',').trim()

            foreach ($Item in $Selection) {
                $Options | Where-Object { $_.GUID -eq $Item } | Select-Object -ExpandProperty Name
            }
        }
        "Organization Dropdown" { $NinjaPropertyValue | ConvertFrom-Json }
        "Organization Location Dropdown" { $NinjaPropertyValue | ConvertFrom-Json }
        "Organization Location MultiSelect" { $NinjaPropertyValue | ConvertFrom-Json }
        "Organization MultiSelect" { $NinjaPropertyValue | ConvertFrom-Json }
        "Time" {
            $Seconds = $NinjaPropertyValue
            $UTC = ([TimeSpan]::FromSeconds($Seconds)).ToString("hh\:mm\:ss")
            $TimeZone = [TimeZoneInfo]::Local
            $ConvertedTime = [TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TimeZone)
            Get-Date $ConvertedTime -DisplayHint Time
        }
        default { $NinjaPropertyValue }
    }
}

try {
    Write-Host "========================================"
    Write-Host "Starting: $ScriptName v$ScriptVersion"
    Write-Host "========================================"
    Write-Host ""
    
    # Check for environment variable overrides
    if ($env:domainUsername -and $env:domainUsername -notlike "null") { 
        $UserName = $env:domainUsername 
    }

    if ($env:domainPasswordWithCustomField -and $env:domainPasswordWithCustomField -notlike "null") { 
        try {
            Write-Host "Retrieving domain password from secure custom field: $env:domainPasswordWithCustomField"
            $Password = Get-NinjaProperty -Name $env:domainPasswordWithCustomField
            
            if ([string]::IsNullOrWhiteSpace($Password)) {
                Write-Host "ERROR: The secure custom field '$env:domainPasswordWithCustomField' is empty."
                exit 1
            }
            
            Write-Host "Password retrieved successfully from secure custom field"
        }
        catch {
            Write-Host "ERROR: Failed to retrieve password from secure custom field '$env:domainPasswordWithCustomField'"
            Write-Host "ERROR: $($_.Exception.Message)"
            exit 1
        }
    }

    # Validate credentials were provided
    if (-not $UserName -or -not $Password) {
        Write-Host "ERROR: Domain username and password are required."
        Write-Host ""
        Write-Host "Usage:"
        Write-Host "  -UserName <domain\username>"
        Write-Host "  -Password <password>"
        Write-Host ""
        Write-Host "Or configure NinjaRMM environment variables:"
        Write-Host "  domainUsername"
        Write-Host "  domainPasswordWithCustomField"
        exit 1
    }

    Write-Host "Domain Username: $UserName"
    Write-Host "Restart after removal: $(-not $NoRestart)"
    Write-Host ""

    # Create PSCredential object
    Write-Host "Creating credential object..."
    $LeaveCred = [PSCredential]::new(
        $UserName, 
        $(ConvertTo-SecureString -String $Password -AsPlainText -Force)
    )

    # Execute domain removal
    Write-Host "Removing computer '$env:COMPUTERNAME' from domain..."
    
    $LeaveResult = if ($NoRestart) {
        (Remove-Computer -UnjoinDomainCredential $LeaveCred -PassThru -Force -Confirm:$false).HasSucceeded
    }
    else {
        (Remove-Computer -UnjoinDomainCredential $LeaveCred -PassThru -Force -Restart -Confirm:$false).HasSucceeded
    }

    if ($LeaveResult) {
        Write-Host ""
        Write-Host "========================================"
        Write-Host "SUCCESS: Computer removed from domain"
        Write-Host "========================================"
        
        if ($NoRestart) {
            Write-Host ""
            Write-Host "IMPORTANT: A restart is required to complete the domain removal."
            Write-Host "Computer will not be fully removed until restarted."
        }
        else {
            Write-Host ""
            Write-Host "Computer is restarting to complete domain removal..."
        }
        
        # Clean up credentials
        $LeaveCred = $null
        $Password = $null
        
        exit 0
    }
    else {
        Write-Host ""
        Write-Host "ERROR: Failed to remove computer '$env:COMPUTERNAME' from domain"
        
        # Clean up credentials
        $LeaveCred = $null
        $Password = $null
        
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "ERROR: Domain removal failed: $($_.Exception.Message)"
    
    # Clean up credentials
    if ($LeaveCred) { $LeaveCred = $null }
    if ($Password) { $Password = $null }
    
    exit 1
}
