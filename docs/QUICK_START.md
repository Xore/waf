# Quick Start Guide - 5 Minutes to First Monitoring

**Time Required:** 5 minutes  
**Prerequisites:** NinjaRMM tenant with admin access, 1 test device  
**Goal:** Deploy your first monitoring script and see results

---

## Step 1: Create First Custom Field (1 minute)

1. Navigate to **Administration > Device Custom Fields**
2. Click **Add Custom Field**
3. Configure:
   - **Name:** `opsHealthScore`
   - **Type:** Integer
   - **Description:** Overall device health score (0-100)
4. Click **Save**

---

## Step 2: Deploy First Script (2 minutes)

1. Navigate to **Administration > Automation > Scripts**
2. Click **Add Script**
3. Configure:
   - **Name:** Health Score Calculator
   - **Category:** Monitoring
   - **Script Type:** PowerShell
   - **Execution Context:** System
   - **Timeout:** 60 seconds
4. Paste script content (get from [scripts/core/](../scripts/core/))
5. Click **Save**

---

## Step 3: Schedule Script Execution (1 minute)

1. Navigate to **Automation > Scheduled Automations**
2. Click **Create Automation Policy**
3. Configure:
   - **Name:** Core Monitoring - Health Score
   - **Trigger:** Schedule
   - **Schedule:** Every 4 hours
   - **Script:** Health Score Calculator
   - **Devices:** Select your test device
4. Click **Save** and **Enable**

---

## Step 4: Verify Field Population (1 minute)

1. Wait 5 minutes for script execution
2. Navigate to **Devices**
3. Click on your test device
4. Go to **Custom Fields** tab
5. Verify `opsHealthScore` has a value (0-100)

**Success!** Your first monitoring field is now populating automatically.

---

## Next Steps

### Deploy Essential 10 Fields (10 minutes)

Expand monitoring by creating these critical fields:

1. `opsHealthScore` (Integer) - Done!
2. `opsStabilityScore` (Integer) - System stability
3. `opsPerformanceScore` (Integer) - Performance metrics
4. `opsSecurityScore` (Integer) - Security posture
5. `opsCapacityScore` (Integer) - Capacity metrics
6. `secAntivirusEnabled` (Checkbox) - AV status
7. `secFirewallEnabled` (Checkbox) - Firewall status
8. `capDiskFreePercent` (Integer) - Disk space %
9. `capMemoryUsedPercent` (Integer) - Memory usage %
10. `updComplianceStatus` (Dropdown) - Patch status

**Values for updComplianceStatus:** `Compliant`, `Minor Gap`, `Major Gap`, `Critical Gap`

### Create Your First Dashboard (15 minutes)

**[Dashboard Templates Guide →](reference/DASHBOARD_TEMPLATES.md)**

1. Navigate to **Dashboards > Create Dashboard**
2. Add Number Widget:
   - **Name:** Average Health Score
   - **Data Source:** Custom Field
   - **Field:** opsHealthScore
   - **Aggregation:** Average
3. Add Gauge Widget:
   - **Name:** Devices at Risk
   - **Filter:** opsHealthScore < 70
   - **Color:** Red if > 10%

### Set Up Your First Alert (10 minutes)

**[Alert Configuration Guide →](reference/ALERT_CONFIGURATION.md)**

1. Navigate to **Automation > Conditions**
2. Click **Add Condition**
3. Configure:
   - **Name:** Critical Health Score
   - **Logic:** `opsHealthScore` < 40
   - **Actions:**
     - Create ticket (Priority: High)
     - Send email notification
   - **Notification:** IT team
4. Save and enable

### Full Deployment (1-3 weeks)

**[Complete Deployment Guide →](reference/DEPLOYMENT_GUIDE.md)**

Follow the comprehensive 10-phase deployment process:

1. Prerequisites and Planning
2. Create 277+ Custom Fields
3. Deploy 110 Scripts
4. Configure Automation Policies
5. Set Up Dashboards
6. Configure Alerts
7. Testing and Validation
8. Production Rollout
9. Training
10. Ongoing Maintenance

---

## Common Issues

### Script Not Executing

**Check:**
- Automation policy is enabled
- Device matches policy filter
- Script timeout is sufficient (60s minimum)
- Agent is online and communicating

### Field Not Populating

**Check:**
- Custom field name matches script exactly (case-sensitive)
- Script completed successfully (check execution logs)
- Field type is correct (Integer for scores)
- Device was targeted by script

### Permission Issues

**Check:**
- Script runs as SYSTEM account (default)
- Your NinjaRMM role has script execution permissions
- Your role can create custom fields

---

## Resources

### Documentation
- **[Custom Fields Reference](reference/CUSTOM_FIELDS_COMPLETE.md)** - All 277+ fields documented
- **[Quick Reference Card](reference/QUICK_REFERENCE.md)** - One-page cheat sheet
- **[Dashboard Templates](reference/DASHBOARD_TEMPLATES.md)** - 6 complete dashboards
- **[Alert Configuration](reference/ALERT_CONFIGURATION.md)** - 50+ alert templates
- **[Deployment Guide](reference/DEPLOYMENT_GUIDE.md)** - Full deployment procedures

### Getting Help
- **Issues:** [GitHub Issues](https://github.com/Xore/waf/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Xore/waf/discussions)
- **Documentation:** [docs/](../docs/)

---

**Congratulations!** You've deployed your first WAF monitoring field. Continue with the Next Steps above to expand your monitoring capabilities.

**Time to Full Deployment:** 1-3 weeks depending on environment size  
**Support:** See resources above
