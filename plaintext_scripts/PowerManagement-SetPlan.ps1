#Requires -Version 5.1

<#
.SYNOPSIS
    Sets the active Windows power plan.

.DESCRIPTION
    This script changes the active Windows power plan to a specified plan. It supports setting 
    plans by name (High Performance, Balanced, Power Saver) or by GUID. The script verifies the 
    plan exists before attempting to activate it and confirms successful activation.
    
    Power plans control CPU performance, display timeout, sleep settings, and other power-related 
    behaviors. This script is useful for optimizing performance vs battery life, or for ensuring 
    consistent power settings across multiple systems.

.PARAMETER PowerPlan
    Name or GUID of the power plan to activate.
    Common plans: "High Performance", "Balanced", "Power Saver"
    Example GUIDs:
    - High Performance: 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    - Balanced: 381b4222-f694-41f0-9685-ff5bb260df2e
    - Power Saver: a1841308-3541-4fab-bc81-f71556f20b4a

.PARAMETER SaveToCustomField
    Name of a custom field to save the power plan change results.

.EXAMPLE
    -PowerPlan "High Performance"

    [Info] Setting power plan to 'High Performance'...
    [Info] Current active plan: Balanced
    [Info] Power plan changed successfully to 'High Performance'

.EXAMPLE
    -PowerPlan "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

    [Info] Setting power plan by GUID...
    [Info] Power plan changed successfully to 'High Performance'

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Administrator privileges
    
.COMPONENT
    powercfg.exe - Windows power configuration utility
    
.LINK
    https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options

.FUNCTIONALITY
    - Sets active Windows power plan by name or GUID
    - Validates power plan exists before activation
    - Reports current and new power plan
    - Verifies successful power plan change
    - Supports all built-in and custom power plans
    - Can save operation results to custom fields
    - Useful for performance optimization and power management
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PowerPlan,
    [string]$SaveToCustomField
)

begin {
    if ($env:powerPlan -and $env:powerPlan -notlike "null") {
        $PowerPlan = $env:powerPlan
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
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
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges"
        exit 1
    }

    if ([string]::IsNullOrWhiteSpace($PowerPlan)) {
        Write-Host "[Error] PowerPlan parameter is required"
        exit 1
    }

    try {
        Write-Host "[Info] Setting power plan to '$PowerPlan'..."
        
        $AllPlans = powercfg /list
        $CurrentPlan = ($AllPlans | Select-String "\*$").ToString().Trim()
        
        if ($CurrentPlan -match "([0-9a-f-]{36})") {
            $CurrentGuid = $Matches[1]
            $CurrentName = ($CurrentPlan -split "\(")[0].Trim().TrimStart('*').Trim()
            Write-Host "[Info] Current active plan: $CurrentName"
        }
        
        $TargetGuid = $null
        $TargetName = $null
        
        if ($PowerPlan -match "^[0-9a-f-]{36}$") {
            $TargetGuid = $PowerPlan
            $MatchingPlan = $AllPlans | Select-String $TargetGuid
            if ($MatchingPlan) {
                $TargetName = ($MatchingPlan.ToString() -split "\(")[0].Trim().TrimStart('*').Trim()
            }
        } else {
            $MatchingPlan = $AllPlans | Select-String -Pattern "$PowerPlan" -SimpleMatch
            if ($MatchingPlan) {
                $PlanLine = $MatchingPlan.ToString()
                if ($PlanLine -match "([0-9a-f-]{36})") {
                    $TargetGuid = $Matches[1]
                    $TargetName = ($PlanLine -split "\(")[0].Trim().TrimStart('*').Trim()
                }
            }
        }
        
        if (-not $TargetGuid) {
            Write-Host "[Error] Power plan '$PowerPlan' not found"
            Write-Host "[Info] Available power plans:"
            $AllPlans | Select-String "Power Scheme GUID" | ForEach-Object {
                $Line = $_.ToString()
                $PlanName = ($Line -split "\(")[0].Trim().TrimStart('*').Trim()
                Write-Host "  - $PlanName"
            }
            exit 1
        }
        
        if ($TargetGuid -eq $CurrentGuid) {
            Write-Host "[Info] Power plan '$TargetName' is already active"
        } else {
            $SetResult = powercfg /setactive $TargetGuid 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[Info] Power plan changed successfully to '$TargetName'"
                $Result = "Power plan changed to '$TargetName' at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            } else {
                Write-Host "[Error] Failed to set power plan: $SetResult"
                $Result = "Failed to change power plan to '$TargetName'"
                $ExitCode = 1
            }
        }

        if ($SaveToCustomField) {
            try {
                if (-not $Result) {
                    $Result = "Power plan already set to '$TargetName'"
                }
                $Result | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to set power plan: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
