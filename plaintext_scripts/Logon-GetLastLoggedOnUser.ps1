#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Retrieves the last logged on user account from the system.

.DESCRIPTION
    This script queries the Windows registry to determine the last user who logged into the system.
    It retrieves the username from the registry key that stores the last interactive logon information,
    which is useful for tracking system usage and identifying the primary user of a workstation.
    
    This information is valuable for IT support, asset management, and user activity tracking.

.PARAMETER SaveToCustomField
    Name of a custom field to save the last logged on username.

.PARAMETER IncludeDomain
    If specified, includes the domain name with the username. Default: False

.EXAMPLE
    No Parameters

    [Info] Retrieving last logged on user...
    [Info] Last logged on user: JohnDoe

.EXAMPLE
    -IncludeDomain -SaveToCustomField "LastUser"

    [Info] Retrieving last logged on user...
    [Info] Last logged on user: CONTOSO\JohnDoe
    [Info] Result saved to custom field 'LastUser'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Refactored to V3.0 standards with Write-Log function
    
.COMPONENT
    Registry - HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI
    
.LINK
    https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry

.FUNCTIONALITY
    - Queries registry for last interactive logon
    - Retrieves username from LogonUI registry key
    - Optionally includes domain information
    - Can save result to custom fields
    - Handles cases where no user has logged on
#>

[CmdletBinding()]
param(
    [string]$SaveToCustomField,
    [switch]$IncludeDomain = $false
)

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

    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }
    if ($env:includeDomain -eq "true") {
        $IncludeDomain = $true
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    $ExitCode = 0
}

process {
    try {
        Write-Log "Retrieving last logged on user..."
        
        $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
        
        $LastLoggedOnUser = Get-ItemProperty -Path $RegPath -Name "LastLoggedOnUser" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LastLoggedOnUser
        
        if (-not $LastLoggedOnUser) {
            $LastLoggedOnUser = Get-ItemProperty -Path $RegPath -Name "LastLoggedOnSAMUser" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LastLoggedOnSAMUser
        }

        if ($LastLoggedOnUser) {
            if (-not $IncludeDomain -and $LastLoggedOnUser -match "\\") {
                $LastLoggedOnUser = $LastLoggedOnUser.Split('\')[-1]
            }
            
            Write-Log "Last logged on user: $LastLoggedOnUser"

            if ($SaveToCustomField) {
                try {
                    $LastLoggedOnUser | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Log "Result saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Log "Failed to save to custom field: $_" -Level Error
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Log "No user has logged on to this system yet"
        }
    }
    catch {
        Write-Log "Failed to retrieve last logged on user: $_" -Level Error
        $ExitCode = 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit $ExitCode
}
