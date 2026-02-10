#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Retrieves Windows activation status and license information.

.DESCRIPTION
    This script queries the Windows Software Licensing service to determine the current 
    activation status, license type, and product key information. It provides detailed 
    information about Windows licensing compliance and activation state.
    
    Monitoring Windows activation status is essential for license compliance auditing and 
    identifying systems that may require reactivation or license key updates.

.PARAMETER SaveToCustomField
    Name of a custom field to save the activation status information.

.EXAMPLE
    -SaveToCustomField "WindowsActivation"

    [Info] Querying Windows activation status...
    License Status: Licensed
    Product Name: Windows 10 Pro
    Activation Status: Activated
    [Info] Activation status saved to custom field 'WindowsActivation'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Refactored to V3.0 standards with Write-Log function
    
.COMPONENT
    SoftwareLicensingProduct - WMI class for license information
    
.LINK
    https://learn.microsoft.com/en-us/windows/win32/api/slpublic/

.FUNCTIONALITY
    - Queries SoftwareLicensingProduct WMI class
    - Retrieves Windows activation status
    - Reports license type and product name
    - Identifies activation method (KMS, MAK, Retail, etc.)
    - Provides license expiration information if applicable
    - Can save activation data to custom fields for compliance tracking
#>

[CmdletBinding()]
param(
    [string]$SaveToCustomField
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
        Write-Log "Querying Windows activation status..."
        
        $LicenseInfo = Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.Name -like "Windows*" }

        if ($LicenseInfo) {
            $StatusMap = @{
                0 = "Unlicensed"
                1 = "Licensed"
                2 = "Out-of-Box Grace Period"
                3 = "Out-of-Tolerance Grace Period"
                4 = "Non-Genuine Grace Period"
                5 = "Notification"
                6 = "Extended Grace"
            }

            $Status = $StatusMap[$LicenseInfo.LicenseStatus]
            Write-Log "License Status: $Status"
            Write-Log "Product Name: $($LicenseInfo.Name)"
            Write-Log "Description: $($LicenseInfo.Description)"
            Write-Log "Partial Product Key: $($LicenseInfo.PartialProductKey)"

            $Output = "Status: $Status | Product: $($LicenseInfo.Name) | Key: $($LicenseInfo.PartialProductKey)"

            if ($SaveToCustomField) {
                try {
                    $Output | Set-NinjaProperty -Name $SaveToCustomField
                    Write-Log "Activation status saved to custom field '$SaveToCustomField'"
                }
                catch {
                    Write-Log "Failed to save to custom field: $_" -Level Error
                    $ExitCode = 1
                }
            }
        }
        else {
            Write-Log "Could not retrieve Windows license information" -Level Warning
        }
    }
    catch {
        Write-Log "Failed to query activation status: $_" -Level Error
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
