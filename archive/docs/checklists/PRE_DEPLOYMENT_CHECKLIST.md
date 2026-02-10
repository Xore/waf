# WAF Pre-Deployment Checklist

**Purpose:** Ensure environment readiness before WAF deployment  
**Use:** Before starting any WAF deployment phase  
**Estimated Time:** 45-60 minutes  
**Last Updated:** February 9, 2026

---

## Overview

This checklist validates your environment meets all prerequisites for successful WAF deployment. Complete ALL items before proceeding.

**Stop if any critical item fails.**

---

## 1. NinjaRMM Access & Permissions

### 1.1 Account Access
- [ ] You have NinjaRMM administrator access
- [ ] You can log into NinjaRMM portal
- [ ] MFA configured and working
- [ ] API access available (if needed)

### 1.2 Required Permissions
- [ ] Can create custom fields (Organization Settings)
- [ ] Can create automation policies
- [ ] Can upload scripts
- [ ] Can create device groups
- [ ] Can create dashboards
- [ ] Can configure alerts

**Test:** Try creating a test custom field, then delete it

---

## 2. PowerShell Environment

### 2.1 Version Check
- [ ] PowerShell 5.1 or higher on target devices
- [ ] Test on sample device: `$PSVersionTable.PSVersion`
- [ ] Confirm output shows 5.1 or higher

**If failed:**
- Windows 10/11: Should have 5.1 by default
- Windows 7/8: Install Windows Management Framework 5.1
- Windows Server 2012+: Install WMF 5.1

### 2.2 Execution Policy
- [ ] NinjaRMM agent can execute scripts (controlled by NinjaRMM)
- [ ] Test script execution on sample device
- [ ] No execution policy blocks

**Test script:**
```powershell
Write-Output "WAF Test Successful"
$PSVersionTable.PSVersion
Get-Date
```

---

## 3. Pilot Device Selection

### 3.1 Pilot Group Requirements
- [ ] Identified 5-10 pilot devices
- [ ] Mix of device types (workstations, laptops)
- [ ] Mix of OS versions (Win10, Win11)
- [ ] Mix of locations (on-site, remote)
- [ ] Non-production or low-risk users
- [ ] Available for testing (not critical systems)

### 3.2 Pilot Device Criteria
**Each pilot device must:**
- [ ] Have active NinjaRMM agent
- [ ] Be online regularly (not offline for days)
- [ ] Have PowerShell 5.1+
- [ ] Be in good working condition
- [ ] Have responsive user (for feedback)

### 3.3 Device Group Created
- [ ] Created "WAF Pilot" device group in NinjaRMM
- [ ] Added pilot devices to group
- [ ] Group is visible in NinjaRMM
- [ ] Can filter by this group

---

## 4. Documentation Review

### 4.1 Implementation Documentation
- [ ] Read PHASE_7_IMPLEMENTATION_PLAN.md
- [ ] Understand deployment phases
- [ ] Know rollback procedures
- [ ] Reviewed field definitions
- [ ] Reviewed script purposes

### 4.2 Operational Documentation
- [ ] Read First Day with WAF guide
- [ ] Reviewed Quick Reference Cards
- [ ] Understand health scoring
- [ ] Know alert response procedures

### 4.3 Troubleshooting Resources
- [ ] Located troubleshooting flowcharts
- [ ] Reviewed FAQ document
- [ ] Know escalation paths
- [ ] Have support contacts

---

## 5. Backup & Rollback Preparation

### 5.1 Configuration Backup
- [ ] Documented current custom fields (if any)
- [ ] Exported current automation policies
- [ ] Documented current dashboards
- [ ] Exported current alert conditions
- [ ] Have rollback procedure documented

### 5.2 Testing Environment
- [ ] Have test/lab environment available (preferred)
- [ ] OR have pilot group isolated
- [ ] Can test without production impact
- [ ] Can roll back if needed

---

## 6. Team Preparation

### 6.1 Stakeholder Communication
- [ ] Management aware of deployment
- [ ] Technical team informed
- [ ] Help desk briefed
- [ ] Users notified (pilot group)
- [ ] Maintenance window approved (if needed)

### 6.2 Roles Assigned
- [ ] Project lead identified: _______________
- [ ] Deployment engineer: _______________
- [ ] Testing coordinator: _______________
- [ ] Escalation contact: _______________

### 6.3 Communication Plan
- [ ] Status update schedule defined
- [ ] Issue escalation path documented
- [ ] Team collaboration tool ready (chat/email)
- [ ] Emergency contact list available

---

## 7. Time & Resource Planning

### 7.1 Time Allocation
- [ ] Phase 7.1 deployment: 8-10 hours scheduled
- [ ] Testing period: 1-2 weeks blocked
- [ ] Team member availability confirmed
- [ ] No major changes during pilot period

### 7.2 Maintenance Window
- [ ] Identified optimal deployment time
- [ ] Low-impact window selected
- [ ] After-hours available (if needed)
- [ ] Weekend available (if needed)

---

## 8. Technical Prerequisites

### 8.1 Network Requirements
- [ ] Devices can reach NinjaRMM cloud
- [ ] No firewall blocking PowerShell execution
- [ ] DNS resolution working
- [ ] Internet connectivity stable

### 8.2 Active Directory (if applicable)
- [ ] LDAP:// protocol not blocked
- [ ] Domain controllers accessible
- [ ] DNS can resolve DC names
- [ ] Test LDAP query works from device

**Test script:**
```powershell
$searcher = New-Object DirectoryServices.DirectorySearcher
$searcher.SearchRoot = "LDAP://DC=yourdomain,DC=com"
$searcher.FindOne()
```

### 8.3 WMI/CIM Functionality
- [ ] WMI service running on devices
- [ ] WMI repository not corrupted
- [ ] Can query WMI remotely
- [ ] Test basic WMI query works

**Test script:**
```powershell
Get-CimInstance Win32_OperatingSystem
Get-CimInstance Win32_ComputerSystem
```

---

## 9. Security & Compliance

### 9.1 Security Approval
- [ ] Security team aware of deployment
- [ ] Scripts reviewed for security (if required)
- [ ] Data collection approved
- [ ] Privacy requirements met
- [ ] Compliance requirements addressed

### 9.2 Change Management
- [ ] Change request submitted (if required)
- [ ] Change approved
- [ ] Change scheduled
- [ ] Rollback plan approved

---

## 10. Success Criteria Definition

### 10.1 Pilot Success Metrics
- [ ] Defined: Target field population rate (96%+)
- [ ] Defined: Target script success rate (95%+)
- [ ] Defined: Acceptable performance impact (<5% CPU)
- [ ] Defined: User satisfaction threshold
- [ ] Defined: Go/no-go decision criteria

### 10.2 Validation Plan
- [ ] Week 1: Daily health checks
- [ ] Week 2: Every other day checks
- [ ] Go-live decision date: _______________
- [ ] Review meeting scheduled

---

## 11. Repository Access

### 11.1 GitHub Repository
- [ ] Can access github.com/Xore/waf
- [ ] Scripts downloaded or available
- [ ] Documentation accessible
- [ ] Using latest version

### 11.2 Version Control
- [ ] Noted current WAF version: Phase ___
- [ ] Documented customizations (if any)
- [ ] Know how to get updates

---

## 12. Final Verification

### 12.1 Pre-Flight Test
- [ ] Manually ran one script on one device
- [ ] Script completed successfully
- [ ] Field updated correctly
- [ ] No errors in logs
- [ ] No user impact observed

### 12.2 Readiness Confirmation
- [ ] ALL critical items checked
- [ ] ALL prerequisites met
- [ ] Team ready to proceed
- [ ] Rollback plan in place
- [ ] Deployment scheduled

---

## Go/No-Go Decision

**Deployment is GO if:**
- All critical items (☑) are checked
- Pilot group ready
- Team prepared
- Documentation reviewed
- Rollback plan in place

**Deployment is NO-GO if:**
- Any critical items unchecked
- Prerequisites not met
- Team not ready
- Major concerns unresolved

---

## Sign-Off

**Completed by:** _______________  
**Date:** _______________  
**Decision:** □ GO  □ NO-GO  
**Approved by:** _______________  
**Deployment scheduled:** _______________

**Notes:**
```
[Document any concerns, special considerations, or deviations]
```

---

## Next Steps

After completing this checklist:

**If GO:**
1. Proceed to Field Creation Checklist
2. Begin Phase 7.1 deployment
3. Follow implementation plan

**If NO-GO:**
1. Document blocking issues
2. Create remediation plan
3. Re-run checklist when ready

---

**Last Updated:** February 9, 2026, 8:14 PM CET
