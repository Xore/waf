# Custom Health Check Templates - Boilerplate Code
**Version:** 1.0  
**Created:** February 1, 2026  
**Purpose:** Reusable PowerShell templates for monitoring custom services, applications, and ports

---

## OVERVIEW

This document provides boilerplate PowerShell code templates for creating custom health checks in NinjaRMM. These templates can be adapted for monitoring any service, application, or network port.

### Template Categories

1. **Windows Service Monitoring** - Check service status and health
2. **Application Process Monitoring** - Monitor specific applications
3. **TCP Port Monitoring** - Check if ports are listening
4. **Network Connection Monitoring** - Track active connections
5. **Application Response Time** - Measure application performance
6. **Combined Health Checks** - Multi-check validation

---

## CUSTOM FIELD NAMING CONVENTION

For custom health checks, follow this naming pattern:

```
CUSTOM_[ServiceName]Status
CUSTOM_[ServiceName]HealthCheck
CUSTOM_[ServiceName]LastCheck
CUSTOM_[ServiceName]ResponseTime
CUSTOM_[ServiceName]ErrorCount
```

**Examples:**
- CUSTOM_SAPStatus
- CUSTOM_ERPHealthCheck
- CUSTOM_CRMLastCheck
- CUSTOM_DatabaseResponseTime

---

## TEMPLATE 1: WINDOWS SERVICE HEALTH CHECK

### Description
Monitor any Windows service by name, track status, and health.

### Custom Fields Required
- `CUSTOM_ServiceNameStatus` (Dropdown: Running, Stopped, Not Installed, Error)
- `CUSTOM_ServiceNameStartMode` (Dropdown: Automatic, Manual, Disabled)
- `CUSTOM_ServiceNameLastCheck` (DateTime)
- `CUSTOM_ServiceNameHealthy` (Checkbox)

### PowerShell Template

```powershell
# Custom Service Health Check Template
# Replace: [SERVICE_NAME] with actual service name
# Replace: [FIELD_PREFIX] with your custom field prefix

try {
    Write-Output "Starting Custom Service Health Check"
    Write-Output "Service: [SERVICE_NAME]"
    Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # CONFIGURATION - MODIFY THESE VALUES
    $serviceName = "[SERVICE_NAME]"  # e.g., "MSSQLSERVER", "MyCustomService"
    $fieldPrefix = "[FIELD_PREFIX]"  # e.g., "CUSTOM_SAP", "CUSTOM_ERP"

    # Check if service exists
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-Output "Service not found: $serviceName"
        Ninja-Property-Set "$($fieldPrefix)Status" "Not Installed"
        Ninja-Property-Set "$($fieldPrefix)Healthy" $false
        Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Write-Output "SUCCESS: Service not installed status recorded"
        exit 0
    }

    # Get service details
    $status = $service.Status.ToString()
    $startMode = $service.StartType.ToString()
    $displayName = $service.DisplayName

    Write-Output "Service Display Name: $displayName"
    Write-Output "Current Status: $status"
    Write-Output "Start Mode: $startMode"

    # Determine health status
    $isHealthy = $false
    if ($status -eq "Running") {
        $isHealthy = $true
        Write-Output "Health Status: Healthy (Running)"
    } else {
        Write-Output "Health Status: Unhealthy (Not Running)"
    }

    # Update custom fields
    Ninja-Property-Set "$($fieldPrefix)Status" $status
    Ninja-Property-Set "$($fieldPrefix)StartMode" $startMode
    Ninja-Property-Set "$($fieldPrefix)Healthy" $isHealthy
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Service health check completed"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set "$($fieldPrefix)Status" "Error"
    Ninja-Property-Set "$($fieldPrefix)Healthy" $false
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    exit 1
}
```

### Example: SAP Service Monitor

```powershell
# SAP Service Health Check
try {
    Write-Output "Starting SAP Service Health Check"

    $serviceName = "SAPOSCOL"  # SAP OS Collector service
    $fieldPrefix = "CUSTOM_SAP"

    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Ninja-Property-Set "CUSTOM_SAPStatus" "Not Installed"
        Ninja-Property-Set "CUSTOM_SAPHealthy" $false
        exit 0
    }

    $status = $service.Status.ToString()
    $isHealthy = ($status -eq "Running")

    Ninja-Property-Set "CUSTOM_SAPStatus" $status
    Ninja-Property-Set "CUSTOM_SAPHealthy" $isHealthy
    Ninja-Property-Set "CUSTOM_SAPLastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: SAP Status = $status"
    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## TEMPLATE 2: APPLICATION PROCESS MONITORING

### Description
Monitor if a specific application process is running, track CPU and memory usage.

### Custom Fields Required
- `CUSTOM_AppNameRunning` (Checkbox)
- `CUSTOM_AppNameProcessCount` (Integer)
- `CUSTOM_AppNameCPUPercent` (Integer)
- `CUSTOM_AppNameMemoryMB` (Integer)
- `CUSTOM_AppNameLastCheck` (DateTime)

### PowerShell Template

```powershell
# Custom Application Process Monitor Template
# Replace: [PROCESS_NAME] with executable name (without .exe)
# Replace: [FIELD_PREFIX] with your custom field prefix

try {
    Write-Output "Starting Custom Application Process Monitor"
    Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # CONFIGURATION - MODIFY THESE VALUES
    $processName = "[PROCESS_NAME]"  # e.g., "chrome", "outlook", "myapp"
    $fieldPrefix = "[FIELD_PREFIX]"  # e.g., "CUSTOM_Chrome", "CUSTOM_CRM"

    # Get all processes with this name
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

    if (-not $processes) {
        Write-Output "Application not running: $processName"
        Ninja-Property-Set "$($fieldPrefix)Running" $false
        Ninja-Property-Set "$($fieldPrefix)ProcessCount" 0
        Ninja-Property-Set "$($fieldPrefix)CPUPercent" 0
        Ninja-Property-Set "$($fieldPrefix)MemoryMB" 0
        Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Write-Output "SUCCESS: Application not running status recorded"
        exit 0
    }

    # Calculate metrics
    $processCount = ($processes | Measure-Object).Count
    $totalCPU = [math]::Round(($processes | Measure-Object -Property CPU -Sum).Sum, 0)
    $totalMemoryMB = [math]::Round(($processes | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB, 0)

    Write-Output "Application: $processName"
    Write-Output "Process Count: $processCount"
    Write-Output "Total CPU: $totalCPU"
    Write-Output "Total Memory: $totalMemoryMB MB"

    # Update custom fields
    Ninja-Property-Set "$($fieldPrefix)Running" $true
    Ninja-Property-Set "$($fieldPrefix)ProcessCount" $processCount
    Ninja-Property-Set "$($fieldPrefix)CPUPercent" $totalCPU
    Ninja-Property-Set "$($fieldPrefix)MemoryMB" $totalMemoryMB
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Application monitoring completed"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set "$($fieldPrefix)Running" $false
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    exit 1
}
```

### Example: ERP Application Monitor

```powershell
# ERP Application Process Monitor
try {
    Write-Output "Starting ERP Application Monitor"

    $processName = "erpapp"  # Replace with your ERP executable name
    $fieldPrefix = "CUSTOM_ERP"

    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

    if (-not $processes) {
        Ninja-Property-Set "CUSTOM_ERPRunning" $false
        Ninja-Property-Set "CUSTOM_ERPProcessCount" 0
        Write-Output "ERP application not running"
        exit 0
    }

    $processCount = ($processes | Measure-Object).Count
    $totalMemoryMB = [math]::Round(($processes | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB, 0)

    Ninja-Property-Set "CUSTOM_ERPRunning" $true
    Ninja-Property-Set "CUSTOM_ERPProcessCount" $processCount
    Ninja-Property-Set "CUSTOM_ERPMemoryMB" $totalMemoryMB
    Ninja-Property-Set "CUSTOM_ERPLastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: ERP running with $processCount processes, $totalMemoryMB MB memory"
    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## TEMPLATE 3: TCP PORT LISTENING CHECK

### Description
Check if a specific TCP port is listening (open) on localhost or remote server.

### Custom Fields Required
- `CUSTOM_PortNameListening` (Checkbox)
- `CUSTOM_PortNameNumber` (Integer)
- `CUSTOM_PortNameProcessName` (Text)
- `CUSTOM_PortNameLastCheck` (DateTime)

### PowerShell Template

```powershell
# Custom TCP Port Listening Check Template
# Replace: [PORT_NUMBER] with actual port number
# Replace: [FIELD_PREFIX] with your custom field prefix

try {
    Write-Output "Starting Custom TCP Port Listening Check"
    Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # CONFIGURATION - MODIFY THESE VALUES
    $portNumber = [PORT_NUMBER]  # e.g., 1433, 3389, 8080
    $fieldPrefix = "[FIELD_PREFIX]"  # e.g., "CUSTOM_SQL", "CUSTOM_Web"

    # Get TCP connections listening on the specified port
    $listeningPort = Get-NetTCPConnection -LocalPort $portNumber -State Listen -ErrorAction SilentlyContinue

    if (-not $listeningPort) {
        Write-Output "Port $portNumber is NOT listening"
        Ninja-Property-Set "$($fieldPrefix)Listening" $false
        Ninja-Property-Set "$($fieldPrefix)Number" $portNumber
        Ninja-Property-Set "$($fieldPrefix)ProcessName" "None"
        Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Write-Output "SUCCESS: Port not listening status recorded"
        exit 0
    }

    # Get process name owning the port
    $owningProcessId = $listeningPort[0].OwningProcess
    $owningProcess = Get-Process -Id $owningProcessId -ErrorAction SilentlyContinue
    $processName = if ($owningProcess) { $owningProcess.Name } else { "Unknown" }

    Write-Output "Port: $portNumber"
    Write-Output "Status: LISTENING"
    Write-Output "Process: $processName (PID: $owningProcessId)"

    # Update custom fields
    Ninja-Property-Set "$($fieldPrefix)Listening" $true
    Ninja-Property-Set "$($fieldPrefix)Number" $portNumber
    Ninja-Property-Set "$($fieldPrefix)ProcessName" $processName
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Port monitoring completed"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set "$($fieldPrefix)Listening" $false
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    exit 1
}
```

### Example: Custom Application Port 8443

```powershell
# Custom Application Port 8443 Listening Check
try {
    Write-Output "Starting Port 8443 Listening Check"

    $portNumber = 8443
    $fieldPrefix = "CUSTOM_AppPort"

    $listeningPort = Get-NetTCPConnection -LocalPort $portNumber -State Listen -ErrorAction SilentlyContinue

    if (-not $listeningPort) {
        Ninja-Property-Set "CUSTOM_AppPortListening" $false
        Ninja-Property-Set "CUSTOM_AppPortProcessName" "None"
        Write-Output "Port 8443 not listening"
        exit 0
    }

    $owningProcessId = $listeningPort[0].OwningProcess
    $owningProcess = Get-Process -Id $owningProcessId -ErrorAction SilentlyContinue
    $processName = if ($owningProcess) { $owningProcess.Name } else { "Unknown" }

    Ninja-Property-Set "CUSTOM_AppPortListening" $true
    Ninja-Property-Set "CUSTOM_AppPortNumber" $portNumber
    Ninja-Property-Set "CUSTOM_AppPortProcessName" $processName
    Ninja-Property-Set "CUSTOM_AppPortLastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Port 8443 listening, process = $processName"
    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## TEMPLATE 4: ACTIVE NETWORK CONNECTION MONITORING

### Description
Monitor active network connections to specific IP addresses or subnets.

### Custom Fields Required
- `CUSTOM_ConnectionNameActive` (Checkbox)
- `CUSTOM_ConnectionNameCount` (Integer)
- `CUSTOM_ConnectionNameEstablished` (Integer)
- `CUSTOM_ConnectionNameLastCheck` (DateTime)

### PowerShell Template

```powershell
# Custom Network Connection Monitor Template
# Replace: [IP_ADDRESS_PATTERN] with IP or subnet pattern
# Replace: [FIELD_PREFIX] with your custom field prefix

try {
    Write-Output "Starting Custom Network Connection Monitor"
    Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # CONFIGURATION - MODIFY THESE VALUES
    $ipPattern = "[IP_ADDRESS_PATTERN]"  # e.g., "192.168.1.*", "10.0.0.5"
    $fieldPrefix = "[FIELD_PREFIX]"  # e.g., "CUSTOM_DBServer", "CUSTOM_RemoteAPI"

    # Get all TCP connections
    $allConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue

    # Filter connections to specific IP pattern
    $matchingConnections = $allConnections | Where-Object {
        $_.RemoteAddress -like $ipPattern
    }

    if (-not $matchingConnections) {
        Write-Output "No active connections to: $ipPattern"
        Ninja-Property-Set "$($fieldPrefix)Active" $false
        Ninja-Property-Set "$($fieldPrefix)Count" 0
        Ninja-Property-Set "$($fieldPrefix)Established" 0
        Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Write-Output "SUCCESS: No connections status recorded"
        exit 0
    }

    # Count connections by state
    $totalCount = ($matchingConnections | Measure-Object).Count
    $establishedCount = ($matchingConnections | Where-Object { $_.State -eq "Established" } | Measure-Object).Count

    Write-Output "IP Pattern: $ipPattern"
    Write-Output "Total Connections: $totalCount"
    Write-Output "Established Connections: $establishedCount"

    # Update custom fields
    Ninja-Property-Set "$($fieldPrefix)Active" $true
    Ninja-Property-Set "$($fieldPrefix)Count" $totalCount
    Ninja-Property-Set "$($fieldPrefix)Established" $establishedCount
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Connection monitoring completed"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set "$($fieldPrefix)Active" $false
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    exit 1
}
```

### Example: Database Server Connection Monitor

```powershell
# Database Server Connection Monitor
try {
    Write-Output "Starting Database Server Connection Monitor"

    $ipPattern = "10.0.1.50"  # Your database server IP
    $fieldPrefix = "CUSTOM_DBConn"

    $allConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue
    $matchingConnections = $allConnections | Where-Object {
        $_.RemoteAddress -eq $ipPattern
    }

    if (-not $matchingConnections) {
        Ninja-Property-Set "CUSTOM_DBConnActive" $false
        Ninja-Property-Set "CUSTOM_DBConnCount" 0
        Write-Output "No connections to database server"
        exit 0
    }

    $totalCount = ($matchingConnections | Measure-Object).Count
    $establishedCount = ($matchingConnections | Where-Object { $_.State -eq "Established" } | Measure-Object).Count

    Ninja-Property-Set "CUSTOM_DBConnActive" $true
    Ninja-Property-Set "CUSTOM_DBConnCount" $totalCount
    Ninja-Property-Set "CUSTOM_DBConnEstablished" $establishedCount
    Ninja-Property-Set "CUSTOM_DBConnLastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: $establishedCount established connections to database server"
    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## TEMPLATE 5: APPLICATION RESPONSE TIME CHECK

### Description
Measure response time of web applications or APIs using HTTP requests.

### Custom Fields Required
- `CUSTOM_AppNameResponsive` (Checkbox)
- `CUSTOM_AppNameResponseTimeMs` (Integer)
- `CUSTOM_AppNameStatusCode` (Integer)
- `CUSTOM_AppNameLastCheck` (DateTime)

### PowerShell Template

```powershell
# Custom Application Response Time Check Template
# Replace: [URL] with actual endpoint URL
# Replace: [FIELD_PREFIX] with your custom field prefix

try {
    Write-Output "Starting Custom Application Response Time Check"
    Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # CONFIGURATION - MODIFY THESE VALUES
    $url = "[URL]"  # e.g., "http://localhost:8080/health", "https://myapp.local/api/status"
    $fieldPrefix = "[FIELD_PREFIX]"  # e.g., "CUSTOM_WebApp", "CUSTOM_API"
    $timeoutSec = 10  # Request timeout in seconds

    # Measure response time
    $startTime = Get-Date

    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec $timeoutSec -ErrorAction Stop
        $endTime = Get-Date
        $responseTimeMs = [int](($endTime - $startTime).TotalMilliseconds)
        $statusCode = $response.StatusCode
        $isResponsive = ($statusCode -ge 200 -and $statusCode -lt 300)

        Write-Output "URL: $url"
        Write-Output "Status Code: $statusCode"
        Write-Output "Response Time: $responseTimeMs ms"
        Write-Output "Responsive: $isResponsive"

        # Update custom fields
        Ninja-Property-Set "$($fieldPrefix)Responsive" $isResponsive
        Ninja-Property-Set "$($fieldPrefix)ResponseTimeMs" $responseTimeMs
        Ninja-Property-Set "$($fieldPrefix)StatusCode" $statusCode
        Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

        Write-Output "SUCCESS: Response time check completed"
        exit 0

    } catch {
        Write-Output "Application not responsive or error occurred"
        Write-Output "Error: $($_.Exception.Message)"

        Ninja-Property-Set "$($fieldPrefix)Responsive" $false
        Ninja-Property-Set "$($fieldPrefix)ResponseTimeMs" -1
        Ninja-Property-Set "$($fieldPrefix)StatusCode" 0
        Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

        Write-Output "SUCCESS: Non-responsive status recorded"
        exit 0
    }

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set "$($fieldPrefix)Responsive" $false
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    exit 1
}
```

### Example: Internal Web Application Health Check

```powershell
# Internal Web Application Health Check
try {
    Write-Output "Starting Web Application Health Check"

    $url = "http://intranet.local/health"
    $fieldPrefix = "CUSTOM_Intranet"
    $timeoutSec = 10

    $startTime = Get-Date

    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec $timeoutSec -ErrorAction Stop
        $endTime = Get-Date
        $responseTimeMs = [int](($endTime - $startTime).TotalMilliseconds)
        $statusCode = $response.StatusCode
        $isResponsive = ($statusCode -ge 200 -and $statusCode -lt 300)

        Ninja-Property-Set "CUSTOM_IntranetResponsive" $isResponsive
        Ninja-Property-Set "CUSTOM_IntranetResponseTimeMs" $responseTimeMs
        Ninja-Property-Set "CUSTOM_IntranetStatusCode" $statusCode
        Ninja-Property-Set "CUSTOM_IntranetLastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

        Write-Output "SUCCESS: Intranet responsive, $responseTimeMs ms, Status $statusCode"
        exit 0

    } catch {
        Ninja-Property-Set "CUSTOM_IntranetResponsive" $false
        Ninja-Property-Set "CUSTOM_IntranetResponseTimeMs" -1
        Ninja-Property-Set "CUSTOM_IntranetStatusCode" 0
        Write-Output "Intranet not responsive"
        exit 0
    }

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## TEMPLATE 6: COMBINED HEALTH CHECK (SERVICE + PORT + PROCESS)

### Description
Comprehensive health check combining service status, port listening, and process monitoring.

### Custom Fields Required
- `CUSTOM_AppNameHealthStatus` (Dropdown: Healthy, Degraded, Critical, Unknown)
- `CUSTOM_AppNameServiceRunning` (Checkbox)
- `CUSTOM_AppNamePortListening` (Checkbox)
- `CUSTOM_AppNameProcessRunning` (Checkbox)
- `CUSTOM_AppNameLastCheck` (DateTime)

### PowerShell Template

```powershell
# Combined Health Check Template
# Checks: Service + Port + Process
# Replace values in CONFIGURATION section

try {
    Write-Output "Starting Combined Health Check"
    Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # CONFIGURATION - MODIFY THESE VALUES
    $serviceName = "[SERVICE_NAME]"  # e.g., "MyAppService"
    $processName = "[PROCESS_NAME]"  # e.g., "myapp"
    $portNumber = [PORT_NUMBER]  # e.g., 8080
    $fieldPrefix = "[FIELD_PREFIX]"  # e.g., "CUSTOM_MyApp"

    # Initialize health check results
    $serviceRunning = $false
    $portListening = $false
    $processRunning = $false
    $healthStatus = "Unknown"

    # Check 1: Service Status
    Write-Output "Checking service: $serviceName"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        $serviceRunning = $true
        Write-Output "Service Status: Running"
    } else {
        Write-Output "Service Status: Not Running or Not Found"
    }

    # Check 2: Port Listening
    Write-Output "Checking port: $portNumber"
    $listeningPort = Get-NetTCPConnection -LocalPort $portNumber -State Listen -ErrorAction SilentlyContinue
    if ($listeningPort) {
        $portListening = $true
        Write-Output "Port Status: Listening"
    } else {
        Write-Output "Port Status: Not Listening"
    }

    # Check 3: Process Running
    Write-Output "Checking process: $processName"
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        $processRunning = $true
        Write-Output "Process Status: Running"
    } else {
        Write-Output "Process Status: Not Running"
    }

    # Determine overall health status
    if ($serviceRunning -and $portListening -and $processRunning) {
        $healthStatus = "Healthy"
        Write-Output "Overall Health: HEALTHY (All checks passed)"
    } elseif ($serviceRunning -or $portListening -or $processRunning) {
        $healthStatus = "Degraded"
        Write-Output "Overall Health: DEGRADED (Some checks failed)"
    } else {
        $healthStatus = "Critical"
        Write-Output "Overall Health: CRITICAL (All checks failed)"
    }

    # Update custom fields
    Ninja-Property-Set "$($fieldPrefix)HealthStatus" $healthStatus
    Ninja-Property-Set "$($fieldPrefix)ServiceRunning" $serviceRunning
    Ninja-Property-Set "$($fieldPrefix)PortListening" $portListening
    Ninja-Property-Set "$($fieldPrefix)ProcessRunning" $processRunning
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Combined health check completed"
    Write-Output "Health Status: $healthStatus"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    Ninja-Property-Set "$($fieldPrefix)HealthStatus" "Unknown"
    Ninja-Property-Set "$($fieldPrefix)LastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    exit 1
}
```

### Example: Custom Business Application Combined Check

```powershell
# Business Application Combined Health Check
try {
    Write-Output "Starting Business Application Health Check"

    $serviceName = "BusinessAppService"
    $processName = "bizapp"
    $portNumber = 9000
    $fieldPrefix = "CUSTOM_BizApp"

    $serviceRunning = $false
    $portListening = $false
    $processRunning = $false

    # Check service
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        $serviceRunning = $true
    }

    # Check port
    $listeningPort = Get-NetTCPConnection -LocalPort $portNumber -State Listen -ErrorAction SilentlyContinue
    if ($listeningPort) {
        $portListening = $true
    }

    # Check process
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        $processRunning = $true
    }

    # Determine health
    if ($serviceRunning -and $portListening -and $processRunning) {
        $healthStatus = "Healthy"
    } elseif ($serviceRunning -or $portListening -or $processRunning) {
        $healthStatus = "Degraded"
    } else {
        $healthStatus = "Critical"
    }

    # Update fields
    Ninja-Property-Set "CUSTOM_BizAppHealthStatus" $healthStatus
    Ninja-Property-Set "CUSTOM_BizAppServiceRunning" $serviceRunning
    Ninja-Property-Set "CUSTOM_BizAppPortListening" $portListening
    Ninja-Property-Set "CUSTOM_BizAppProcessRunning" $processRunning
    Ninja-Property-Set "CUSTOM_BizAppLastCheck" (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Health=$healthStatus, Service=$serviceRunning, Port=$portListening, Process=$processRunning"
    exit 0

} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## AUTOMATION PATTERNS

### Compound Condition: Service Down Alert

```
Condition Name: CUSTOM_ServiceNameDown
Priority: P1 Critical
Check Frequency: Every 5 minutes
Logic: CUSTOM_ServiceNameHealthy = False
Actions:
  - Create Ticket: [Service Name] service is down
  - Run Script: Restart [Service Name] service (if auto-restart enabled)
  - Send Alert: Operations team
  - Escalate: After 15 minutes
```

### Compound Condition: Port Not Listening

```
Condition Name: CUSTOM_PortNotListening
Priority: P2 High
Check Frequency: Every 15 minutes
Logic: CUSTOM_PortNameListening = False
Actions:
  - Create Ticket: Port [PORT_NUMBER] not listening
  - Run Script: Restart service owning port
  - Send Alert: Support team
```

### Compound Condition: Application Not Running

```
Condition Name: CUSTOM_AppNotRunning
Priority: P2 High
Check Frequency: Every 15 minutes
Logic: CUSTOM_AppNameRunning = False
Actions:
  - Create Ticket: [Application Name] not running
  - Run Script: Start application (if auto-start enabled)
  - Send Alert: Application team
```

### Compound Condition: Slow Response Time

```
Condition Name: CUSTOM_SlowResponseTime
Priority: P3 Medium
Check Frequency: Every 30 minutes
Logic: CUSTOM_AppNameResponseTimeMs > 5000 OR CUSTOM_AppNameResponsive = False
Actions:
  - Create Ticket: [Application Name] slow or unresponsive
  - Send Alert: Application team
```

### Compound Condition: Combined Health Critical

```
Condition Name: CUSTOM_HealthCritical
Priority: P1 Critical
Check Frequency: Every 5 minutes
Logic: CUSTOM_AppNameHealthStatus = "Critical"
Actions:
  - Create Ticket: [Application Name] health critical - all checks failed
  - Run Script: Emergency restart procedure
  - Send Alert: Operations team
  - Escalate: Immediate
```

---

## DYNAMIC GROUP PATTERNS

### Group: Custom Services Unhealthy

```
Group Name: CUSTOM_ServicesUnhealthy
Description: Devices with custom services in unhealthy state
Criteria: 
  CUSTOM_[Service1]Healthy = False OR
  CUSTOM_[Service2]Healthy = False OR
  CUSTOM_[Service3]Healthy = False
Use Case: Bulk remediation targeting
```

### Group: Custom Ports Not Listening

```
Group Name: CUSTOM_PortsNotListening
Description: Devices with custom ports not listening
Criteria:
  CUSTOM_[Port1]Listening = False OR
  CUSTOM_[Port2]Listening = False
Use Case: Network service monitoring
```

### Group: Custom Applications Running

```
Group Name: CUSTOM_AppsRunning
Description: Devices where custom applications are active
Criteria:
  CUSTOM_[App1]Running = True AND
  CUSTOM_[App2]Running = True
Use Case: Application deployment tracking
```

---

## DEPLOYMENT CHECKLIST

### Before Deployment

- [ ] Identify services, applications, and ports to monitor
- [ ] Choose field prefix (CUSTOM_[Name])
- [ ] Create custom fields in NinjaRMM
- [ ] Test scripts locally with PsExec as SYSTEM
- [ ] Verify field names match exactly in scripts

### During Deployment

- [ ] Deploy scripts to pilot group (5-10 devices)
- [ ] Schedule scripts (recommended: every 15 minutes for critical, every hour for standard)
- [ ] Wait 24 hours for field population
- [ ] Verify data accuracy

### After Deployment

- [ ] Create compound conditions for alerting
- [ ] Create dynamic groups for automation
- [ ] Set up dashboards and widgets
- [ ] Document custom monitoring configuration

---

## BEST PRACTICES

### Field Naming

1. Use consistent prefix (CUSTOM_)
2. Use PascalCase for field names
3. Include descriptive suffix (Status, Healthy, LastCheck)
4. Maximum 50 characters

### Script Execution

1. Run as SYSTEM context
2. Set appropriate timeout (60-120 seconds)
3. Execute every 15-60 minutes depending on criticality
4. Include error handling with Try/Catch

### Error Handling

1. Always update LastCheck field
2. Set status to "Error" or "Unknown" on failure
3. Log errors with Write-Output
4. Exit with code 0 for known failures, 1 for exceptions

### Performance

1. Keep scripts under 60 seconds execution time
2. Use ErrorAction SilentlyContinue for Get-* cmdlets
3. Avoid heavy WMI queries
4. Test on representative devices before deployment

---

## TROUBLESHOOTING

### Fields Not Populating

**Problem:** Custom fields remain empty after script execution

**Solutions:**
1. Verify script runs as SYSTEM context
2. Check field names match exactly (case-sensitive)
3. Review NinjaRMM script logs for errors
4. Manually run script on affected device
5. Confirm service/process/port exists on device

### Script Timeout

**Problem:** Script times out before completion

**Solutions:**
1. Increase script timeout from 60s to 120s
2. Remove unnecessary Wait-Sleep commands
3. Optimize WMI queries
4. Break into multiple smaller scripts

### False Negatives

**Problem:** Script reports service/port healthy when it's not

**Solutions:**
1. Add additional validation checks
2. Verify service state is "Running" not just exists
3. Check port state is "Listen" not just connection exists
4. Test response time threshold is appropriate

---

## SUPPORT

For framework integration questions, refer to:
- `99_Quick_Reference_Guide.md` - Quick troubleshooting
- `51_Field_to_Script_Complete_Mapping.md` - Field mapping reference
- `91_Compound_Conditions_Complete.md` - Condition patterns

---

**Version:** 1.0  
**Created:** February 1, 2026  
  
**Compatible With:** NinjaRMM, PowerShell 5.1+
