# Custom Health Check Templates - Quick Reference Card
**File:** 70_Custom_Health_Check_Templates.md  
**Version:** 1.0  
**Created:** February 1, 2026

---

## TEMPLATE QUICK REFERENCE

### Template 1: Windows Service Monitor

**Purpose:** Monitor any Windows service status  
**Fields:** Status, StartMode, Healthy, LastCheck  
**Configuration:** Set serviceName and fieldPrefix  
**Example:** SAP service monitoring

```powershell
$serviceName = "YourServiceName"
$fieldPrefix = "CUSTOM_YourApp"
```

---

### Template 2: Application Process Monitor

**Purpose:** Track if application is running, CPU/memory usage  
**Fields:** Running, ProcessCount, CPUPercent, MemoryMB, LastCheck  
**Configuration:** Set processName and fieldPrefix  
**Example:** ERP application monitoring

```powershell
$processName = "yourapp"  # without .exe
$fieldPrefix = "CUSTOM_YourApp"
```

---

### Template 3: TCP Port Listener

**Purpose:** Check if port is listening  
**Fields:** Listening, Number, ProcessName, LastCheck  
**Configuration:** Set portNumber and fieldPrefix  
**Example:** Custom port 8443 monitoring

```powershell
$portNumber = 8443
$fieldPrefix = "CUSTOM_AppPort"
```

---

### Template 4: Network Connection Monitor

**Purpose:** Track connections to specific IP addresses  
**Fields:** Active, Count, Established, LastCheck  
**Configuration:** Set ipPattern and fieldPrefix  
**Example:** Database server connection tracking

```powershell
$ipPattern = "10.0.1.50"
$fieldPrefix = "CUSTOM_DBConn"
```

---

### Template 5: Response Time Check

**Purpose:** Measure web app/API response time  
**Fields:** Responsive, ResponseTimeMs, StatusCode, LastCheck  
**Configuration:** Set url and fieldPrefix  
**Example:** Intranet health check

```powershell
$url = "http://intranet.local/health"
$fieldPrefix = "CUSTOM_Intranet"
```

---

### Template 6: Combined Health Check

**Purpose:** Service + Port + Process all-in-one  
**Fields:** HealthStatus, ServiceRunning, PortListening, ProcessRunning, LastCheck  
**Configuration:** Set serviceName, processName, portNumber, fieldPrefix  
**Example:** Business app complete check

```powershell
$serviceName = "BusinessAppService"
$processName = "bizapp"
$portNumber = 9000
$fieldPrefix = "CUSTOM_BizApp"
```

---

## AUTOMATION PATTERNS

### Critical: Service Down
```
Logic: CUSTOM_[Name]Healthy = False
Action: Create P1 ticket, restart service
Frequency: Every 5 minutes
```

### High: Port Not Listening
```
Logic: CUSTOM_[Name]Listening = False
Action: Create P2 ticket, restart owning service
Frequency: Every 15 minutes
```

### High: Application Not Running
```
Logic: CUSTOM_[Name]Running = False
Action: Create P2 ticket, start application
Frequency: Every 15 minutes
```

### Medium: Slow Response
```
Logic: CUSTOM_[Name]ResponseTimeMs > 5000
Action: Create P3 ticket, alert team
Frequency: Every 30 minutes
```

### Critical: Combined Health Failure
```
Logic: CUSTOM_[Name]HealthStatus = "Critical"
Action: Create P1 ticket, emergency restart
Frequency: Every 5 minutes
```

---

## FIELD NAMING GUIDE

### Pattern
```
CUSTOM_[ServiceName]Status
CUSTOM_[ServiceName]Healthy
CUSTOM_[ServiceName]LastCheck
```

### Examples
```
CUSTOM_SAPStatus
CUSTOM_ERPHealthy
CUSTOM_CRMLastCheck
CUSTOM_DatabaseResponseTime
```

### Rules
- Use CUSTOM prefix for all custom checks
- Use PascalCase (no spaces)
- Maximum 50 characters
- Descriptive suffix (Status, Healthy, LastCheck, etc.)

---

## DEPLOYMENT STEPS

1. **Identify** - What to monitor (service, app, port)
2. **Choose Template** - Select appropriate template (1-6)
3. **Create Fields** - Add custom fields in NinjaRMM
4. **Customize Script** - Update configuration section
5. **Test Locally** - Run with PsExec as SYSTEM
6. **Deploy Pilot** - 5-10 test devices
7. **Verify Data** - Wait 24h, check field population
8. **Create Conditions** - Add automation patterns
9. **Create Groups** - Add dynamic groups
10. **Full Rollout** - Deploy to all applicable devices

---

## COMMON USES

### SAP Systems
- Template 1: SAP services (SAPOSCOL, etc.)
- Template 3: SAP ports (3200-3299)
- Template 6: Combined SAP health

### ERP Applications
- Template 2: ERP process monitoring
- Template 5: ERP web interface response
- Template 6: Complete ERP stack

### Database Servers
- Template 1: Database services
- Template 3: Database listener ports (1433, 3306)
- Template 4: Client connections

### Web Applications
- Template 3: Web server ports (80, 443, 8080)
- Template 5: HTTP health endpoints
- Template 6: Web stack (IIS + app pool + process)

### Custom Line-of-Business Apps
- Template 2: Application process
- Template 3: Application listener port
- Template 6: Complete application health

---

## TROUBLESHOOTING

### Script Not Running
- Check scheduled in NinjaRMM
- Verify SYSTEM context
- Review execution logs

### Fields Not Populating
- Verify field names match exactly
- Check service/process/port exists
- Review script output for errors

### False Positives
- Adjust thresholds (response time, etc.)
- Add additional validation checks
- Increase check frequency

### Script Timeout
- Increase timeout to 120 seconds
- Optimize queries
- Remove unnecessary waits

---

## BEST PRACTICES

- Run as SYSTEM context
- Execute every 15-60 minutes
- Include error handling (Try/Catch)
- Always update LastCheck field
- Test on pilot devices first
- Document custom configurations
- Use consistent field prefixes

---

**For complete templates and examples, see:**  
`70_Custom_Health_Check_Templates.md`

**For framework integration, see:**  
`00_Master_Index.md` - Navigation  
`51_Field_to_Script_Complete_Mapping.md` - Field mapping  
`91_Compound_Conditions_Complete.md` - Automation patterns  
`99_Quick_Reference_Guide.md` - Troubleshooting
