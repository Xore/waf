# Custom Health Check Templates - Complete Summary
**Date:** February 1, 2026, 4:38 PM CET  
**Version:** 1.0  


---

## FILES CREATED

### 1. 70_Custom_Health_Check_Templates.md (30.7 KB)
**Complete boilerplate PowerShell code library**

Templates included:
1. Windows Service Health Check
2. Application Process Monitoring
3. TCP Port Listening Check
4. Active Network Connection Monitoring
5. Application Response Time Check
6. Combined Health Check (Service + Port + Process)

Each template includes:
- Complete PowerShell code
- Customizable configuration section
- Working example implementation
- Custom field definitions
- Error handling
- Deployment notes

### 2. 70_Custom_Health_Check_Quick_Reference.md (4.5 KB)
**Quick reference card for rapid deployment**

Contents:
- All 6 templates summarized
- Configuration snippets
- Automation pattern examples
- Field naming guide
- Deployment steps (1-10)
- Common use cases
- Troubleshooting tips

---

## FRAMEWORK INTEGRATION

### Updated Files

**00_Master_Index.md**
- Added section: Custom Health Check Templates (70)
- Updated file count: 48 -> 49 files
- Includes template overview and examples

**00_README.md**
- Added table entry for health check templates
- Updated file count: 48 -> 49 files
- Positioned in file structure documentation

---

## USAGE EXAMPLES

### Example 1: SAP System Monitoring

**Scenario:** Monitor SAP OSCOL service and port 3200

**Custom Fields:**
- CUSTOM_SAPStatus (Dropdown)
- CUSTOM_SAPHealthy (Checkbox)
- CUSTOM_SAPPortListening (Checkbox)
- CUSTOM_SAPLastCheck (DateTime)

**Scripts:**
- Template 1: Service check for SAPOSCOL
- Template 3: Port check for 3200

**Automation:**
- Condition: CUSTOM_SAPHealthy = False
- Action: P1 ticket, restart service

### Example 2: ERP Application Health

**Scenario:** Monitor ERP application process and web interface

**Custom Fields:**
- CUSTOM_ERPRunning (Checkbox)
- CUSTOM_ERPMemoryMB (Integer)
- CUSTOM_ERPResponseTimeMs (Integer)
- CUSTOM_ERPResponsive (Checkbox)

**Scripts:**
- Template 2: Process monitoring
- Template 5: HTTP health check

**Automation:**
- Condition: CUSTOM_ERPRunning = False OR CUSTOM_ERPResponsive = False
- Action: P2 ticket, alert team

### Example 3: Database Server Connections

**Scenario:** Monitor connections to SQL Server at 10.0.1.50

**Custom Fields:**
- CUSTOM_DBConnActive (Checkbox)
- CUSTOM_DBConnCount (Integer)
- CUSTOM_DBConnEstablished (Integer)

**Scripts:**
- Template 4: Network connection monitoring

**Automation:**
- Condition: CUSTOM_DBConnEstablished < 5 (too few)
- Action: P3 ticket, connectivity issue

### Example 4: Internal Web Application

**Scenario:** Monitor intranet web app health and response time

**Custom Fields:**
- CUSTOM_IntranetResponsive (Checkbox)
- CUSTOM_IntranetResponseTimeMs (Integer)
- CUSTOM_IntranetStatusCode (Integer)

**Scripts:**
- Template 5: HTTP health endpoint

**Automation:**
- Condition: CUSTOM_IntranetResponseTimeMs > 5000 OR CUSTOM_IntranetResponsive = False
- Action: P3 ticket, performance issue

### Example 5: Business App Complete Check

**Scenario:** Full health check of custom business application

**Custom Fields:**
- CUSTOM_BizAppHealthStatus (Dropdown: Healthy/Degraded/Critical)
- CUSTOM_BizAppServiceRunning (Checkbox)
- CUSTOM_BizAppPortListening (Checkbox)
- CUSTOM_BizAppProcessRunning (Checkbox)

**Scripts:**
- Template 6: Combined health check

**Automation:**
- Condition: CUSTOM_BizAppHealthStatus = "Critical"
- Action: P1 ticket, emergency restart procedure

---

## FIELD STATISTICS

### Total Custom Fields Required (Per Application)

**Simple Monitoring (Template 1, 2, or 3):**
- 4-5 custom fields per application

**Advanced Monitoring (Template 5):**
- 4-5 custom fields per application

**Complete Monitoring (Template 6):**
- 5-6 custom fields per application

### Example Field Count for 5 Custom Applications

**5 Applications × 5 Fields Average = 25 custom fields**

This fits well within NinjaRMM's custom field limits and framework architecture.

---

## INTEGRATION WITH FRAMEWORK

### Layer 1: Telemetry Scripts
- Custom health check scripts execute every 15-60 minutes
- Collect service status, process info, port status, response times

### Layer 2: Custom Field Storage
- CUSTOM_* prefixed fields store health check results
- Persistent per-device storage
- Accessible to all framework layers

### Layer 3: Classification Logic
- Health status derived from multiple checks
- Combined scoring (Healthy/Degraded/Critical)
- Integrates with OPSHealthScore calculation

### Layer 4: Dynamic Groups
- Group devices by custom application health
- Target specific application deployments
- Route automation based on health status

### Layer 5: Remediation Automation
- Auto-restart services when down
- Auto-start applications when stopped
- Alert teams on critical health failures

### Layer 6: Helpdesk Visibility
- Dashboard panels show custom app health
- Color-coded status indicators
- Actionable alerts for custom applications

---

## DEPLOYMENT RECOMMENDATIONS

### Phase 1: Pilot (Week 1)
- Select 1-2 critical applications
- Deploy to 5-10 pilot devices
- Use Template 1 or 3 (simplest)
- Validate field population

### Phase 2: Expansion (Week 2-3)
- Add 3-5 more applications
- Deploy to 20-50 devices
- Use Templates 2, 4, 5 as needed
- Create automation conditions

### Phase 3: Advanced (Week 4+)
- Implement Template 6 for critical apps
- Full automation enablement
- Dynamic group creation
- Dashboard integration

---

## BENEFITS

### Operational Benefits
- Monitor any custom application
- Proactive failure detection
- Automated remediation
- Consistent monitoring approach

### Technical Benefits
- Reusable templates (copy/paste)
- Standardized field naming
- Framework integration
- Scalable architecture

### Business Benefits
- Reduce custom app downtime
- Improve user satisfaction
- Lower support costs
- Better visibility into line-of-business apps

---

## ROI ESTIMATE

### Time Savings Per Application

**Manual Monitoring:**
- 10 minutes per day checking each app manually
- 5 applications = 50 minutes per day

**Automated Monitoring:**
- 30 minutes one-time setup per app
- 5 applications = 150 minutes setup
- Daily time: 0 minutes (automated)

**Payback Period:**
- 150 minutes / 50 minutes per day = 3 days

**Annual Savings:**
- 50 minutes × 5 days per week × 50 weeks = 12,500 minutes per year
- = 208 hours per year
- = 5.2 weeks of technician time

### Cost Savings

**Assuming $50/hour technician cost:**
- 208 hours × $50 = $10,400 per year savings

**Setup Cost:**
- 2.5 hours × $50 = $125 one-time cost

**ROI:** 8,320% over first year

---

## CUSTOMIZATION GUIDELINES

### When to Use Each Template

**Template 1 (Service):** When monitoring Windows services  
**Template 2 (Process):** When monitoring applications without services  
**Template 3 (Port):** When monitoring network listeners  
**Template 4 (Connection):** When monitoring client connections  
**Template 5 (Response):** When monitoring web apps or APIs  
**Template 6 (Combined):** When comprehensive monitoring is critical  

### Customization Steps

1. Copy template code
2. Update CONFIGURATION section
3. Modify field names to match your naming
4. Test with sample data
5. Deploy to pilot device
6. Validate field population
7. Create automation conditions
8. Full deployment

### Advanced Customizations

- Add custom validation logic
- Include multiple service checks
- Combine multiple port checks
- Add performance thresholds
- Include custom alerting logic
- Integrate with external APIs

---

## SUPPORT AND DOCUMENTATION

### Primary Resources

**Template Documentation:**
- 70_Custom_Health_Check_Templates.md - Complete templates
- 70_Custom_Health_Check_Quick_Reference.md - Quick reference

**Framework Integration:**
- 00_Master_Index.md - Navigation guide
- 00_README.md - Framework overview
- 51_Field_to_Script_Complete_Mapping.md - Field mapping
- 91_Compound_Conditions_Complete.md - Automation patterns

### Troubleshooting

**Script Issues:**
- Review 99_Quick_Reference_Guide.md
- Check script execution logs
- Verify SYSTEM context

**Field Issues:**
- Verify field names match exactly
- Check field types are correct
- Confirm script is scheduled

**Automation Issues:**
- Review compound condition logic
- Check field values are updating
- Verify condition is enabled

---

## PACKAGE STATUS

**Files Created:** 2 new files  
**Framework Files:** 49 total (was 48)  
  
**Version:** 1.0  
**Compatibility:** NinjaRMM, PowerShell 5.1+  

---

**Created:** February 1, 2026, 4:38 PM CET  
**Ready for immediate deployment**
