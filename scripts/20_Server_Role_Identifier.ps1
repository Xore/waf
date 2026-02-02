<#
.SYNOPSIS
    NinjaRMM Script 20: Server Role and Service Identifier

.DESCRIPTION
    Detects server roles and critical services running on the device.
    Classifies device type and primary function.

.NOTES
    Frequency: Weekly
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - srvRole (Dropdown: None, DC, File, Web, SQL, Exchange, App, Multi)
    - srvCriticalServices (Text)
    - baseDeviceType (Dropdown: Workstation, Server, Mobile, Virtual)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $detectedRoles = @()
    $criticalServices = @()

    # Determine device type
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $isServer = $os.ProductType -ne 1

    if ($isServer) {
        Ninja-Property-Set baseDeviceType "Server"
        
        # Check for Domain Controller
        $dcService = Get-Service -Name NTDS -ErrorAction SilentlyContinue
        if ($dcService) {
            $detectedRoles += "DC"
            $criticalServices += "Active Directory Domain Services"
        }

        # Check for File Server
        $fileServer = Get-WindowsFeature -Name FS-FileServer -ErrorAction SilentlyContinue
        if ($fileServer -and $fileServer.Installed) {
            $detectedRoles += "File"
            $criticalServices += "File Services"
        }

        # Check for Web Server (IIS)
        $iis = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
        if ($iis) {
            $detectedRoles += "Web"
            $criticalServices += "IIS"
        }

        # Check for SQL Server
        $sqlService = Get-Service -Name MSSQLSERVER, SQLSERVERAGENT -ErrorAction SilentlyContinue
        if ($sqlService) {
            $detectedRoles += "SQL"
            $criticalServices += "SQL Server"
        }

        # Check for Exchange
        $exchange = Get-Service -Name MSExchangeServiceHost -ErrorAction SilentlyContinue
        if ($exchange) {
            $detectedRoles += "Exchange"
            $criticalServices += "Exchange"
        }

        # Determine primary role
        if ($detectedRoles.Count -eq 0) {
            $primaryRole = "App"
        } elseif ($detectedRoles.Count -eq 1) {
            $primaryRole = $detectedRoles[0]
        } else {
            $primaryRole = "Multi"
        }

        Ninja-Property-Set srvRole $primaryRole
    } else {
        # Check if virtual machine
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        if ($computerSystem.Model -match "Virtual|VMware|Hyper-V") {
            Ninja-Property-Set baseDeviceType "Virtual"
        } else {
            Ninja-Property-Set baseDeviceType "Workstation"
        }
        
        Ninja-Property-Set srvRole "None"
    }

    # Update critical services field
    if ($criticalServices.Count -gt 0) {
        Ninja-Property-Set srvCriticalServices ($criticalServices -join ", ")
    } else {
        Ninja-Property-Set srvCriticalServices "None"
    }

    Write-Output "Device Type: $(Ninja-Property-Get baseDeviceType) | Role: $(Ninja-Property-Get srvRole)"

} catch {
    Write-Output "Error: $_"
    exit 1
}
