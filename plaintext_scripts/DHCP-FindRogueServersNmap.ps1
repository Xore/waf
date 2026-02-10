#Requires -Version 5.1

<#
.SYNOPSIS
    Scans network for rogue DHCP servers using Nmap.

.DESCRIPTION
    This script uses Nmap to scan the local network subnet(s) for active DHCP servers listening 
    on UDP port 67. It compares discovered DHCP servers against a list of allowed/authorized 
    servers and alerts if rogue DHCP servers are detected.
    
    Rogue DHCP servers can cause serious network disruptions by providing incorrect IP 
    configurations to clients. This script helps detect unauthorized DHCP services.
    
    Note: This script requires Nmap to be installed separately. It will not install Nmap.

.PARAMETER AllowedServers
    Array of IP addresses for authorized DHCP servers.

.PARAMETER CustomField
    Name of custom field to save rogue DHCP server report.
    Default: rogueDHCPServers

.PARAMETER AllowedServersField
    Name of custom field to retrieve allowed DHCP servers from.
    Default: allowedDHCPServers

.EXAMPLE
    .\DHCP-FindRogueServersNmap.ps1 -AllowedServers "172.17.240.1","172.17.242.10"
    
    DHCP Servers found.
    Mac Address       IP Address    
    00:15:5D:FF:93:C3 172.17.240.1
    No rogue dhcp servers found.

.EXAMPLE
    .\DHCP-FindRogueServersNmap.ps1 -AllowedServersField "allowedDHCP"
    
    Retrieves allowed servers from custom field and scans for rogues.

.OUTPUTS
    None. Status information is written to the console and optionally to a custom field.

.NOTES
    File Name      : DHCP-FindRogueServersNmap.ps1
    Prerequisite   : PowerShell 5.1 or higher, Nmap installed
    Minimum OS     : Windows 10, Windows Server 2016
    Version        : 3.0.0
    Author         : WAF Team
    Change Log:
    - 3.0.0: Upgraded to V3 standards with Write-Log function and execution tracking
    - 1.0: Initial release
    
.LINK
    https://nmap.org/download.html
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String[]]$AllowedServers,
    
    [Parameter()]
    [String]$CustomField = "rogueDHCPServers",
    
    [Parameter()]
    [String]$AllowedServersField = "allowedDHCPServers"
)

begin {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $StartTime = Get-Date
    
    Set-StrictMode -Version Latest
    
    $script:ExitCode = 0
    $script:ErrorCount = 0
    $script:WarningCount = 0

    function Write-Log {
        param([string]$Message, [string]$Level = 'INFO')
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"
        Write-Output $logMessage
        
        if ($Level -eq 'ERROR') { $script:ErrorCount++ }
        if ($Level -eq 'WARNING') { $script:WarningCount++ }
    }

    function Set-NinjaField {
        <#
        .SYNOPSIS
            Sets NinjaRMM custom field with CLI fallback.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Name,
            
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [AllowEmptyString()]
            [string]$Value
        )
        
        try {
            if (Get-Command 'Ninja-Property-Set' -ErrorAction SilentlyContinue) {
                Ninja-Property-Set -Name $Name -Value $Value
            }
            else {
                Write-Log "CLI fallback - Would set field '$Name' to: $Value" -Level 'INFO'
            }
        }
        catch {
            Write-Log "Failed to set custom field '$Name': $_" -Level 'ERROR'
            throw
        }
    }

    function Get-Subnet {
        <#
        .SYNOPSIS
            Parses subnet info into CIDR format from network configuration.
        #>
        try {
            $DefaultGateways = (Get-NetIPConfiguration).IPv4DefaultGateway

            $Subnets = $DefaultGateways | ForEach-Object {
                $Index = $_.ifIndex
                $PrefixLength = (Get-NetIPAddress | Where-Object { 
                    $_.AddressFamily -eq 'IPv4' -and 
                    $_.PrefixOrigin -ne 'WellKnown' -and 
                    $Index -eq $_.InterfaceIndex 
                } | Select-Object -ExpandProperty PrefixLength)
                
                if ($_.NextHop -and $PrefixLength) {
                    "$($_.NextHop)/$PrefixLength"
                }
            }

            if ($Subnets) {
                $Subnets | Select-Object -Unique
            }
        }
        catch {
            Write-Log "Failed to get subnet information: $_" -Level 'ERROR'
            throw
        }
    }

    function Find-UninstallKey {
        <#
        .SYNOPSIS
            Finds application uninstall keys in the registry.
        #>
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline = $True)]
            [String]$DisplayName,
            [Parameter()]
            [Switch]$UninstallString
        )
        process {
            $UninstallList = New-Object System.Collections.Generic.List[Object]

            $Result = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | 
                Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
            if ($Result) { $UninstallList.Add($Result) }

            $Result = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | 
                Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
            if ($Result) { $UninstallList.Add($Result) }

            if ($UninstallString) {
                $UninstallList | Select-Object -ExpandProperty UninstallString -ErrorAction SilentlyContinue
            }
            else {
                $UninstallList
            }
        }
    }

    if ($env:allowedServersCustomField -and $env:allowedServersCustomField -notlike "null") {
        $AllowedServersField = $env:allowedServersCustomField
    }

    if ($AllowedServersField -and -not ($AllowedServers)) {
        try {
            $AllowedServers = (Ninja-Property-Get $AllowedServersField 2>$null) -split ',' | ForEach-Object { $_.Trim() }
        }
        catch {
            Write-Log "Failed to retrieve allowed servers from custom field" -Level 'WARNING'
        }
    }

    if ($env:allowedServers -and $env:allowedServers -notlike "null") {
        $AllowedServers = $env:allowedServers -split ',' | ForEach-Object { $_.Trim() }
    }

    if ($env:customFieldName -and $env:customFieldName -notlike "null") {
        $CustomField = $env:customFieldName 
    }

    $Nmap = (Find-UninstallKey -DisplayName "Nmap" -UninstallString) -replace '"' -replace 'uninstall.exe', 'nmap.exe'
    if (-not $Nmap) {
        Write-Log "Nmap is not installed! Please install nmap prior to running this script. https://nmap.org/download.html" -Level 'ERROR'
        $script:ExitCode = 1
        return
    }
}

process {
    if ($script:ExitCode -ne 0) { return }
    
    try {
        Write-Log "Starting rogue DHCP server scan"
        
        $Subnets = Get-Subnet
        if (-not $Subnets) {
            Write-Log "Unable to get list of subnets" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        Write-Log "Scanning subnets: $($Subnets -join ', ')"

        $Arguments = @(
            "-sU"
            "-p"
            "67"
            "-d"
            $Subnets
            "--open"
            "-oX"
            "$env:TEMP\nmap-results.xml"
        )
        
        Start-Process -FilePath $Nmap -ArgumentList $Arguments -WindowStyle Hidden -Wait -ErrorAction Stop
        
        if (-not (Test-Path "$env:Temp\nmap-results.xml")) {
            Write-Log "Nmap scan failed to generate results file" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }
        
        [xml]$result = Get-Content -Path "$env:Temp\nmap-results.xml" -ErrorAction Stop

        if ($result) {
            $resultObject = $result.DocumentElement.host | ForEach-Object {
                [PSCustomObject]@{
                    "IP Address"  = ($_.address | Where-Object { $_.addrtype -match "ip" } | Select-Object -ExpandProperty "addr")
                    "Mac Address" = ($_.address | Where-Object { $_.addrtype -match "mac" } | Select-Object -ExpandProperty "addr")
                }
            }
        }
        else {
            Write-Log "Nmap results are empty" -Level 'ERROR'
            $script:ExitCode = 1
            return
        }

        if ($resultObject) {
            Write-Log "DHCP Servers found:"
            $resultObject | Sort-Object -Property "IP Address" -Unique | ForEach-Object {
                Write-Log "  IP: $($_.'IP Address')  MAC: $($_.'Mac Address')"
            }
            
            Remove-Item -Path "$env:Temp\nmap-results.xml" -Force -ErrorAction SilentlyContinue

            Write-Log "Checking against allowed servers list..."
            $RogueServers = @()
            
            foreach ($Server in $resultObject) {
                if ($AllowedServers -notcontains $Server."IP Address") {
                    Write-Log "Rogue DHCP Server Found: $($Server.'IP Address') is not on the allowed list" -Level 'WARNING'
                    $RogueServers += $Server
                    $script:ExitCode = 1
                }
            }

            if ($RogueServers.Count -gt 0) {
                try {
                    $RogueReport = ($RogueServers | ForEach-Object { "IP: $($_.'IP Address') MAC: $($_.'Mac Address')" }) -join "; "
                    Set-NinjaField -Name $CustomField -Value $RogueReport
                }
                catch {
                    Write-Log "Failed to save rogue servers to custom field: $_" -Level 'WARNING'
                }
            }
            else {
                Write-Log "No rogue DHCP servers found"
            }
        }
    }
    catch {
        Write-Log "Failed to scan for rogue DHCP servers: $_" -Level 'ERROR'
        $script:ExitCode = 1
    }
}

end {
    try {
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        
        Write-Output "`n========================================"
        Write-Output "Execution Summary"
        Write-Output "========================================"
        Write-Output "Script: DHCP-FindRogueServersNmap.ps1"
        Write-Output "Duration: $Duration seconds"
        Write-Output "Errors: $script:ErrorCount"
        Write-Output "Warnings: $script:WarningCount"
        Write-Output "Exit Code: $script:ExitCode"
        Write-Output "========================================"
    }
    finally {
        [System.GC]::Collect()
        exit $script:ExitCode
    }
}
