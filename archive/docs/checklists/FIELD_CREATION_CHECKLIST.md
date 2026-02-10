# WAF Field Creation Checklist

**Purpose:** Systematic custom field creation in NinjaRMM  
**Phase:** 7.1 Foundation  
**Estimated Time:** 2-3 hours  
**Last Updated:** February 9, 2026

---

## Before You Begin

- [ ] Pre-Deployment Checklist completed
- [ ] NinjaRMM administrator access confirmed
- [ ] Field definitions document available
- [ ] 2-3 hours uninterrupted time allocated

---

## Field Creation Process

### Step 1: Navigate to Custom Fields

- [ ] Log into NinjaRMM
- [ ] Go to Administration
- [ ] Select Organization
- [ ] Click "Custom Fields"
- [ ] Click "Device Custom Fields"

### Step 2: Prepare for Creation

- [ ] Open field reference document
- [ ] Prepare text editor for notes
- [ ] Note starting time: _______________

---

## Operations (OPS) - 15 Fields

**Category:** Core operational health

### Health Scores (6 fields)

- [ ] **opsHealthScore**
  - Type: Integer
  - Description: Overall device health score (0-100)
  - Validation: 0-100

- [ ] **opsStabilityScore**
  - Type: Integer
  - Description: System stability score (0-100)
  - Validation: 0-100

- [ ] **opsPerformanceScore**
  - Type: Integer
  - Description: Performance health score (0-100)
  - Validation: 0-100

- [ ] **opsSecurityScore**
  - Type: Integer
  - Description: Security posture score (0-100)
  - Validation: 0-100

- [ ] **opsCapacityScore**
  - Type: Integer
  - Description: Capacity health score (0-100)
  - Validation: 0-100

- [ ] **opsOverallScore**
  - Type: Integer
  - Description: Weighted overall health score (0-100)
  - Validation: 0-100

### Timestamps (3 fields)

- [ ] **opsLastHealthCheck**
  - Type: Integer
  - Description: Last health check timestamp (Unix Epoch)

- [ ] **opsLastBootTime**
  - Type: Integer
  - Description: Last boot timestamp (Unix Epoch)

- [ ] **opsUptime**
  - Type: Integer
  - Description: Device uptime in seconds

### Status & Config (6 fields)

- [ ] **opsUptimeDays**
  - Type: Integer
  - Description: Device uptime in days

- [ ] **opsDeviceAge**
  - Type: Integer
  - Description: Device age since first boot (seconds)

- [ ] **opsDeviceAgeMonths**
  - Type: Integer
  - Description: Device age in months

- [ ] **opsMonitoringEnabled**
  - Type: Checkbox
  - Description: WAF monitoring active

- [ ] **opsStatus**
  - Type: Dropdown
  - Description: Overall status classification
  - Values: Healthy, Warning, Critical, Unknown

- [ ] **opsNotes**
  - Type: Text
  - Description: Administrative notes

**Progress check:** 15/15 OPS fields created ✓

---

## Statistics (STAT) - 10 Fields

**Category:** Event and error tracking

### Event Counts (4 fields)

- [ ] **statCrashCount30d**
  - Type: Integer
  - Description: Application crashes in last 30 days

- [ ] **statErrorCount30d**
  - Type: Integer
  - Description: Error events in last 30 days

- [ ] **statWarningCount30d**
  - Type: Integer
  - Description: Warning events in last 30 days

- [ ] **statRebootCount30d**
  - Type: Integer
  - Description: System reboots in last 30 days

### Performance Averages (3 fields)

- [ ] **statAvgCPUUsage**
  - Type: Integer
  - Description: Average CPU usage percentage
  - Validation: 0-100

- [ ] **statAvgMemoryUsage**
  - Type: Integer
  - Description: Average memory usage percentage
  - Validation: 0-100

- [ ] **statAvgDiskUsage**
  - Type: Integer
  - Description: Average disk usage percentage
  - Validation: 0-100

### Other Stats (3 fields)

- [ ] **statStabilityScore**
  - Type: Integer
  - Description: Calculated stability score
  - Validation: 0-100

- [ ] **statLastCrashDate**
  - Type: Integer
  - Description: Last crash timestamp (Unix Epoch)

- [ ] **statUpgradeAvailable**
  - Type: Checkbox
  - Description: OS upgrade available

**Progress check:** 10/10 STAT fields created ✓

---

## Security (SEC) - 10 Fields

**Category:** Security posture and compliance

### Protection Status (7 fields)

- [ ] **secAntivirusEnabled**
  - Type: Checkbox
  - Description: Antivirus protection active

- [ ] **secAntivirusProduct**
  - Type: Text
  - Description: Antivirus product name

- [ ] **secAntivirusUpdated**
  - Type: Checkbox
  - Description: AV definitions current

- [ ] **secFirewallEnabled**
  - Type: Checkbox
  - Description: Windows Firewall active

- [ ] **secBitLockerEnabled**
  - Type: Checkbox
  - Description: BitLocker encryption enabled

- [ ] **secSecureBootEnabled**
  - Type: Checkbox
  - Description: Secure Boot enabled

- [ ] **secTPMEnabled**
  - Type: Checkbox
  - Description: TPM chip enabled

### Compliance (3 fields)

- [ ] **secLastSecurityScan**
  - Type: Integer
  - Description: Last security scan timestamp (Unix Epoch)

- [ ] **secVulnerabilityCount**
  - Type: Integer
  - Description: Known vulnerabilities count

- [ ] **secComplianceStatus**
  - Type: Dropdown
  - Description: Compliance classification
  - Values: Compliant, Non-Compliant, Partial, Unknown

**Progress check:** 10/10 SEC fields created ✓

---

## Capacity (CAP) - 10 Fields

**Category:** Resource capacity and usage

### Disk Metrics (3 fields)

- [ ] **capDiskFreeGB**
  - Type: Integer
  - Description: Free disk space in GB (C: drive)

- [ ] **capDiskFreePercent**
  - Type: Integer
  - Description: Free disk percentage
  - Validation: 0-100

- [ ] **capDiskTotalGB**
  - Type: Integer
  - Description: Total disk size in GB (C: drive)

### Memory Metrics (3 fields)

- [ ] **capMemoryTotalGB**
  - Type: Integer
  - Description: Total RAM installed in GB

- [ ] **capMemoryUsedGB**
  - Type: Integer
  - Description: Current RAM usage in GB

- [ ] **capMemoryUsedPercent**
  - Type: Integer
  - Description: Memory usage percentage
  - Validation: 0-100

### CPU & Forecasting (4 fields)

- [ ] **capCPUCores**
  - Type: Integer
  - Description: CPU core count

- [ ] **capCPUThreads**
  - Type: Integer
  - Description: CPU thread count

- [ ] **capWarningLevel**
  - Type: Dropdown
  - Description: Capacity warning level
  - Values: Normal, Warning, Critical

- [ ] **capForecastDaysFull**
  - Type: Integer
  - Description: Days until disk full (forecast)

**Progress check:** 10/10 CAP fields created ✓

---

## Updates (UPD) - 5 Fields

**Category:** Windows Update compliance

- [ ] **updComplianceStatus**
  - Type: Dropdown
  - Description: Update compliance status
  - Values: Compliant, Partial, Non-Compliant, Unknown

- [ ] **updMissingCriticalCount**
  - Type: Integer
  - Description: Missing critical updates count

- [ ] **updMissingImportantCount**
  - Type: Integer
  - Description: Missing important updates count

- [ ] **updLastPatchDate**
  - Type: Integer
  - Description: Last update installed timestamp (Unix Epoch)

- [ ] **updLastPatchCheck**
  - Type: Integer
  - Description: Last update check timestamp (Unix Epoch)

**Progress check:** 5/5 UPD fields created ✓

---

## Final Verification

### Field Count Check

- [ ] OPS fields: 15 ✓
- [ ] STAT fields: 10 ✓
- [ ] SEC fields: 10 ✓
- [ ] CAP fields: 10 ✓
- [ ] UPD fields: 5 ✓
- [ ] **Total: 50 fields** ✓

### Quality Check

- [ ] All field names spelled correctly (case-sensitive!)
- [ ] All field types correct (Integer, Text, Checkbox, Dropdown)
- [ ] All dropdown values entered correctly
- [ ] All descriptions meaningful
- [ ] No duplicate fields

### Functionality Test

- [ ] Can view custom fields in device details
- [ ] Fields appear in correct order
- [ ] Can search/filter by fields
- [ ] Fields available in dashboards

---

## Time Tracking

- Start time: _______________
- End time: _______________
- Total duration: _______________
- Expected: 2-3 hours

---

## Completion Sign-Off

**Created by:** _______________  
**Date:** _______________  
**Fields created:** 50/50 ✓  
**Quality verified:** □ Yes  
**Ready for scripts:** □ Yes

**Notes:**
```
[Document any issues, deviations, or special considerations]
```

---

## Next Steps

- [ ] Proceed to Script Deployment Checklist
- [ ] Begin uploading automation scripts
- [ ] Configure automation policies

---

**Last Updated:** February 9, 2026, 8:15 PM CET
