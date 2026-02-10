#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Retrieves and displays WiFi driver information.
.DESCRIPTION
    Retrieves and displays WiFi driver information.
.EXAMPLE
    No parameters needed
    Retrieves and displays WiFi driver information.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param ()

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

    function Get-NinjaOneCard($Title, $Body, [string]$Icon, [string]$TitleLink, [String]$Classes) {
        [System.Collections.Generic.List[String]]$OutputHTML = @()

        $OutputHTML.add('<div class="card flex-grow-1' + $(if ($classes) {
                    ' ' + $classes 
                }) + '" >')

        if ($Title) {
            $OutputHTML.add('<div class="card-title-box"><div class="card-title" >' + $(if ($Icon) {
                        '<i class="' + $Icon + '"></i>&nbsp;&nbsp;' 
                    }) + $Title + '</div>')

            if ($TitleLink) {
                $OutputHTML.add('<div class="card-link-box"><a href="' + $TitleLink + '" target="_blank" class="card-link" ><i class="fas fa-arrow-up-right-from-square" style="color: #337ab7;"></i></a></div>')
            }

            $OutputHTML.add('</div>')
        }

        $OutputHTML.add('<div class="card-body" >')
        $OutputHTML.add('<p class="card-text" >' + $Body + '</p>')
           
        $OutputHTML.add('</div></div>')

        return $OutputHTML -join ''
    }
}

process {
    try {
        $ExecutionPolicy = Get-ExecutionPolicy
        if ($ExecutionPolicy -eq 'Restricted') {
            Write-Log "Temporarily changing execution policy from Restricted"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
        }

        Write-Log "Retrieving WiFi driver information..."
        $WifiDriverHtml = (netsh wlan show driver).Trim() | ConvertTo-Json
        $WifiDrive = Get-NinjaOneCard -Title 'WiFi Driver Details' -Body $WifiDriverHtml -Icon 'fas fa-wifi style="color:#0364b8;'
        $CombinedHTML = '<div class="row g-1 rows-cols-2">' + 
        '<div class="col-xl-4 col-lg-4 col-md-4 col-sm-4 d-flex">' + $ODHTML + 
        '</div>' + $WifiDrive +
        '</div>'
        $CombinedHTML | Ninja-Property-Set-Piped -Name wifidriver

        Write-Log "WiFi driver information retrieved successfully"

        if ($ExecutionPolicy -eq 'Restricted') {
            Write-Log "Restoring execution policy to Restricted"
            Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force
        }
    }
    catch {
        Write-Log "Failed to retrieve WiFi driver information: $_" -Level Error
        if ($ExecutionPolicy -eq 'Restricted') {
            Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -ErrorAction SilentlyContinue
        }
        exit 1
    }
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
