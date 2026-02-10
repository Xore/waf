#Requires -Version 5.1

<#
.SYNOPSIS
    Adds a network printer by UNC path or IP address.

.DESCRIPTION
    This script adds a network printer to the local system using either a UNC path (e.g., 
    \\printserver\printername) or an IP address with port configuration. It can optionally 
    set the printer as the default printer and install printer drivers if needed.
    
    The script supports:
    - UNC path printer connections (\\server\printer)
    - TCP/IP printer connections with port configuration
    - Driver installation from Windows driver store
    - Setting printer as default
    - Printer configuration verification

.PARAMETER PrinterPath
    UNC path to the network printer (e.g., \\printserver\HP-LaserJet-01)
    Required if using UNC path method.

.PARAMETER PrinterIP
    IP address of the network printer for TCP/IP connection.
    Required if using TCP/IP method.

.PARAMETER PrinterPort
    TCP port number for the printer. Default: 9100
    Only used with PrinterIP parameter.

.PARAMETER PrinterName
    Friendly name for the printer. If not specified, uses the share name or IP address.

.PARAMETER DriverName
    Name of the printer driver to use. Must be available in Windows driver store.
    Required for TCP/IP connections.

.PARAMETER SetAsDefault
    If specified, sets this printer as the default printer.

.PARAMETER SaveToCustomField
    Name of a custom field to save the printer installation results.

.EXAMPLE
    -PrinterPath "\\printserver\HP-Color-LaserJet"

    [Info] Adding network printer from UNC path...
    [Info] Connecting to \\printserver\HP-Color-LaserJet
    [Info] Printer 'HP-Color-LaserJet' added successfully

.EXAMPLE
    -PrinterIP "192.168.1.100" -DriverName "HP Universal Printing PCL 6" -PrinterName "Office Printer" -SetAsDefault

    [Info] Adding network printer via TCP/IP...
    [Info] Creating printer port for 192.168.1.100:9100
    [Info] Installing printer with driver 'HP Universal Printing PCL 6'
    [Info] Printer 'Office Printer' added successfully
    [Info] Printer set as default

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: Initial release for WAF v3.0
    Requires: Administrator privileges for driver installation
    
.COMPONENT
    Add-Printer - PowerShell printer management cmdlet
    Add-PrinterPort - PowerShell printer port management cmdlet
    
.LINK
    https://learn.microsoft.com/en-us/powershell/module/printmanagement/

.FUNCTIONALITY
    - Adds network printers via UNC path or TCP/IP
    - Creates TCP/IP printer ports when needed
    - Installs printers with specified drivers
    - Can set printer as system default
    - Verifies successful printer installation
    - Supports both shared and direct IP printers
    - Can save installation results to custom fields
#>

[CmdletBinding()]
param(
    [string]$PrinterPath,
    [string]$PrinterIP,
    [int]$PrinterPort = 9100,
    [string]$PrinterName,
    [string]$DriverName,
    [switch]$SetAsDefault,
    [string]$SaveToCustomField
)

begin {
    if ($env:printerPath -and $env:printerPath -notlike "null") {
        $PrinterPath = $env:printerPath
    }
    if ($env:printerIP -and $env:printerIP -notlike "null") {
        $PrinterIP = $env:printerIP
    }
    if ($env:printerPort -and $env:printerPort -notlike "null") {
        $PrinterPort = [int]$env:printerPort
    }
    if ($env:printerName -and $env:printerName -notlike "null") {
        $PrinterName = $env:printerName
    }
    if ($env:driverName -and $env:driverName -notlike "null") {
        $DriverName = $env:driverName
    }
    if ($env:setAsDefault -eq "true") {
        $SetAsDefault = $true
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
    if ([string]::IsNullOrWhiteSpace($PrinterPath) -and [string]::IsNullOrWhiteSpace($PrinterIP)) {
        Write-Host "[Error] Either PrinterPath or PrinterIP must be specified"
        exit 1
    }

    if (-not [string]::IsNullOrWhiteSpace($PrinterIP) -and [string]::IsNullOrWhiteSpace($DriverName)) {
        Write-Host "[Error] DriverName is required when using PrinterIP"
        exit 1
    }

    try {
        if ($PrinterPath) {
            Write-Host "[Info] Adding network printer from UNC path..."
            Write-Host "[Info] Connecting to $PrinterPath"
            
            if ([string]::IsNullOrWhiteSpace($PrinterName)) {
                $PrinterName = ($PrinterPath -split '\\')[-1]
            }
            
            Add-Printer -ConnectionName $PrinterPath -ErrorAction Stop
            
            $Printer = Get-Printer -Name $PrinterPath -ErrorAction SilentlyContinue
            if ($Printer) {
                Write-Host "[Info] Printer '$PrinterName' added successfully"
                $Result = "Printer '$PrinterName' added from $PrinterPath"
            } else {
                Write-Host "[Error] Printer was not added successfully"
                $ExitCode = 1
                $Result = "Failed to add printer from $PrinterPath"
            }
            
        } elseif ($PrinterIP) {
            Write-Host "[Info] Adding network printer via TCP/IP..."
            
            if ([string]::IsNullOrWhiteSpace($PrinterName)) {
                $PrinterName = "Printer-$PrinterIP"
            }
            
            $PortName = "IP_$PrinterIP"
            
            $ExistingPort = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
            if (-not $ExistingPort) {
                Write-Host "[Info] Creating printer port for ${PrinterIP}:${PrinterPort}"
                Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP -PortNumber $PrinterPort -ErrorAction Stop
            } else {
                Write-Host "[Info] Using existing printer port $PortName"
            }
            
            $AvailableDriver = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
            if (-not $AvailableDriver) {
                Write-Host "[Error] Printer driver '$DriverName' not found in driver store"
                Write-Host "[Info] Available drivers:"
                Get-PrinterDriver | Select-Object -First 10 -ExpandProperty Name | ForEach-Object {
                    Write-Host "  - $_"
                }
                exit 1
            }
            
            Write-Host "[Info] Installing printer with driver '$DriverName'"
            Add-Printer -Name $PrinterName -PortName $PortName -DriverName $DriverName -ErrorAction Stop
            
            $Printer = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
            if ($Printer) {
                Write-Host "[Info] Printer '$PrinterName' added successfully"
                $Result = "Printer '$PrinterName' added at $PrinterIP with driver '$DriverName'"
            } else {
                Write-Host "[Error] Printer was not added successfully"
                $ExitCode = 1
                $Result = "Failed to add printer at $PrinterIP"
            }
        }
        
        if ($SetAsDefault -and $Printer) {
            try {
                $Printer | Set-Printer -Default -ErrorAction Stop
                Write-Host "[Info] Printer set as default"
                $Result += " | Set as default"
            } catch {
                Write-Host "[Warn] Failed to set as default printer: $_"
            }
        }

        if ($SaveToCustomField) {
            try {
                $Result | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to add printer: $_"
        $ExitCode = 1
    }

    exit $ExitCode
}

end {
}
