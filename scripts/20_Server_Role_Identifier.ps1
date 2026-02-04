<#
.SYNOPSIS
    Server Role and Service Identifier - Device Classification and Role Detection

.DESCRIPTION
    Automatically detects and classifies device types and server roles by analyzing installed
    Windows features, running services, and operating system characteristics. Provides accurate
    device inventory categorization and enables role-specific monitoring, patching, and
    maintenance policies.
    
    Performs comprehensive environment discovery to identify server functions including domain
    controllers, file servers, web servers, database servers, and multi-role servers. Enables
    automated policy assignment, targeted alerting, and role-based configuration management.
    
    Device Type Classification:
    
    Server (ProductType 2 or 3):
    - Identifies Windows Server operating systems
    - Triggers server role detection logic
    - Subject to enhanced monitoring and maintenance
    
    Workstation (ProductType 1, Physical):
    - Desktop or laptop systems
    - Physical hardware (not virtual machines)
    - Standard end-user device policies
    
    Virtual (ProductType 1, Virtual Platform):
    - Virtual machines running client OS
    - Detected via Model string matching:
      * VMware (VMware Virtual Platform)
      * Hyper-V (Virtual Machine)
      * VirtualBox, KVM, Xen patterns
    
    Server Role Detection (Servers Only):
    
    Domain Controller (DC):
    - Service: NTDS (Active Directory Domain Services)
    - Critical Service: Active Directory Domain Services
    - Highest priority server role
    - Requires specialized backup and replication monitoring
    
    File Server (File):
    - Feature: FS-FileServer (File Services role)
    - Critical Service: File Services
    - Shared folder and SMB monitoring required
    - Storage and share permissions management
    
    Web Server (Web):
    - Service: W3SVC (World Wide Web Publishing Service)
    - Critical Service: IIS (Internet Information Services)
    - Application pool and site availability monitoring
    - SSL certificate and performance tracking
    
    Database Server (SQL):
    - Services: MSSQLSERVER, SQLSERVERAGENT
    - Critical Service: SQL Server
    - Database availability and performance monitoring
    - Backup verification and transaction log management
    
    Exchange Server (Exchange):
    - Service: MSExchangeServiceHost
    - Critical Service: Exchange
    - Mailbox database and transport monitoring
    - Queue and connector health tracking
    
    Application Server (App):
    - Default classification when no specific role detected
    - Generic Windows Server without specialized services
    - Custom application hosting
    
    Multi-Role Server (Multi):
    - Two or more detected server roles on same system
    - Requires monitoring for all identified roles
    - Higher resource utilization expected
    - Complexity increases troubleshooting effort

.NOTES
    Frequency: Weekly
    Runtime: ~20 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - baseDeviceType (Text: Workstation, Server, Virtual, Mobile)
    - srvRole (Text: None, DC, File, Web, SQL, Exchange, App, Multi)
    - srvCriticalServices (Text: comma-separated list of critical services)
    
    Dependencies:
    - WMI/CIM: Win32_OperatingSystem, Win32_ComputerSystem
    - Windows Features cmdlets (Get-WindowsFeature)
    - Service Control Manager
    
    Detection Methods:
    - ProductType (1=Workstation, 2=Domain Controller, 3=Server)
    - Windows Features (Get-WindowsFeature)
    - Service enumeration (Get-Service)
    - Model string pattern matching for virtualization
    
    Use Cases:
    - Automated device inventory and classification
    - Role-based monitoring policy assignment
    - Patch management targeting (server vs workstation)
    - Asset management and lifecycle tracking
    - Capacity planning and infrastructure mapping
    - Compliance reporting and audit trails
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Server Role and Service Identifier (v4.0)..."

    $detectedRoles = @()
    $criticalServices = @()

    # Determine device type via operating system ProductType
    Write-Output "INFO: Detecting device type..."
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $isServer = $os.ProductType -ne 1  # ProductType: 1=Workstation, 2=DC, 3=Server
    
    Write-Output "INFO: OS: $($os.Caption) | ProductType: $($os.ProductType)"

    if ($isServer) {
        Write-Output "INFO: Device identified as Windows Server"
        Ninja-Property-Set baseDeviceType "Server"
        
        # Begin server role detection
        Write-Output "INFO: Scanning for server roles and services..."

        # Role 1: Domain Controller
        Write-Output "INFO: Checking for Domain Controller role..."
        $dcService = Get-Service -Name NTDS -ErrorAction SilentlyContinue
        if ($dcService) {
            $detectedRoles += "DC"
            $criticalServices += "Active Directory Domain Services"
            Write-Output "  DETECTED: Domain Controller (NTDS service found)"
        }

        # Role 2: File Server
        Write-Output "INFO: Checking for File Server role..."
        try {
            $fileServer = Get-WindowsFeature -Name FS-FileServer -ErrorAction SilentlyContinue
            if ($fileServer -and $fileServer.Installed) {
                $detectedRoles += "File"
                $criticalServices += "File Services"
                Write-Output "  DETECTED: File Server (FS-FileServer feature installed)"
            }
        } catch {
            Write-Output "  INFO: Unable to query Windows Features (may not be available)"
        }

        # Role 3: Web Server (IIS)
        Write-Output "INFO: Checking for Web Server role (IIS)..."
        $iis = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
        if ($iis) {
            $detectedRoles += "Web"
            $criticalServices += "IIS"
            Write-Output "  DETECTED: Web Server (W3SVC service found)"
        }

        # Role 4: SQL Server
        Write-Output "INFO: Checking for SQL Server role..."
        $sqlService = Get-Service -Name MSSQLSERVER, SQLSERVERAGENT -ErrorAction SilentlyContinue
        if ($sqlService) {
            $detectedRoles += "SQL"
            $criticalServices += "SQL Server"
            Write-Output "  DETECTED: SQL Server (MSSQLSERVER/SQLSERVERAGENT services found)"
        }

        # Role 5: Exchange Server
        Write-Output "INFO: Checking for Exchange Server role..."
        $exchange = Get-Service -Name MSExchangeServiceHost -ErrorAction SilentlyContinue
        if ($exchange) {
            $detectedRoles += "Exchange"
            $criticalServices += "Exchange"
            Write-Output "  DETECTED: Exchange Server (MSExchangeServiceHost service found)"
        }

        # Determine primary server role
        Write-Output "INFO: Classifying primary server role..."
        if ($detectedRoles.Count -eq 0) {
            $primaryRole = "App"
            Write-Output "  CLASSIFICATION: Application Server (no specific roles detected)"
        } elseif ($detectedRoles.Count -eq 1) {
            $primaryRole = $detectedRoles[0]
            Write-Output "  CLASSIFICATION: Single-role server ($primaryRole)"
        } else {
            $primaryRole = "Multi"
            Write-Output "  CLASSIFICATION: Multi-role server (roles: $($detectedRoles -join ', '))"
        }

        Ninja-Property-Set srvRole $primaryRole
        
    } else {
        # Workstation/Client OS - check virtualization
        Write-Output "INFO: Device identified as Client OS (Workstation or Virtual)"
        
        Write-Output "INFO: Checking virtualization platform..."
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        $model = $computerSystem.Model
        Write-Output "INFO: Hardware Model: $model"
        
        if ($model -match "Virtual|VMware|Hyper-V|VirtualBox|KVM|Xen|QEMU") {
            Ninja-Property-Set baseDeviceType "Virtual"
            Write-Output "  CLASSIFICATION: Virtual Machine"
        } else {
            Ninja-Property-Set baseDeviceType "Workstation"
            Write-Output "  CLASSIFICATION: Physical Workstation"
        }
        
        Ninja-Property-Set srvRole "None"
        Write-Output "INFO: Server role set to None (client device)"
    }

    # Update critical services field
    Write-Output "INFO: Updating critical services inventory..."
    if ($criticalServices.Count -gt 0) {
        $servicesList = $criticalServices -join ", "
        Ninja-Property-Set srvCriticalServices $servicesList
        Write-Output "INFO: Critical services identified: $servicesList"
    } else {
        Ninja-Property-Set srvCriticalServices "None"
        Write-Output "INFO: No critical services identified"
    }

    # Retrieve final classification
    $finalDeviceType = Ninja-Property-Get baseDeviceType
    $finalRole = Ninja-Property-Get srvRole

    Write-Output "SUCCESS: Device classification complete"
    Write-Output "DEVICE CLASSIFICATION:"
    Write-Output "  - Device Type: $finalDeviceType"
    Write-Output "  - Server Role: $finalRole"
    Write-Output "  - Critical Services: $(if ($criticalServices.Count -gt 0) { $criticalServices -join ', ' } else { 'None' })"
    
    if ($isServer) {
        Write-Output "DETECTED SERVER ROLES:"
        if ($detectedRoles.Count -gt 0) {
            $detectedRoles | ForEach-Object { Write-Output "  - $_" }
        } else {
            Write-Output "  - Application Server (generic)"
        }
    }

    exit 0
} catch {
    Write-Output "ERROR: Server Role Identifier failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
