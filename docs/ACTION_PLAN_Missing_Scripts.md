# Action Plan: Missing Monitoring Scripts Implementation

**Created:** February 3, 2026  
**Status:** Planning Phase  
**Priority:** High  
**Impact:** 102 fields currently unsupported (37% of total framework)

---

## Executive Summary

The filename header audit revealed 12 critical monitoring scripts that are either missing or incorrectly assigned. This document provides a prioritized implementation roadmap to achieve 100% field coverage.

**Current State:**
- Total Fields: 277
- Supported Fields: ~175 (63%)
- Unsupported Fields: ~102 (37%)

**Target State:**
- All 277 fields supported by verified scripts
- Clear script numbering convention established
- Automated validation to prevent future drift

---

## Phase 1: Critical Infrastructure (Weeks 1-2)

### Priority: P0 - Business Critical

#### 1.1 Database Server Monitoring (26 fields)
**Impact:** High - Production database monitoring  
**Files Affected:** `12_ROLE_Database_Web.md`  
**Estimated Effort:** 3-4 days

**Scripts to Implement:**

##### Script TBD: IIS Web Server Monitor
- **Fields:** 11 IIS fields
- **Frequency:** Every 4 hours
- **Key Metrics:**
  - Site status and health
  - Application pool monitoring
  - Request queue tracking
  - Error rate monitoring
- **Dependencies:** IIS PowerShell module
- **Conflict Resolution:** Script 9 remains Risk Classifier

##### Script TBD: MSSQL Server Monitor
- **Fields:** 8 MSSQL fields
- **Frequency:** Every 4 hours
- **Key Metrics:**
  - Instance health
  - Database count and status
  - Failed jobs tracking
  - Backup status monitoring
  - Transaction log size
- **Dependencies:** SQL Server Management Objects (SMO)
- **Conflict Resolution:** Script 10 remains Update Compliance Monitor

##### Script TBD: MySQL Server Monitor
- **Fields:** 7 MYSQL fields
- **Frequency:** Every 4 hours
- **Key Metrics:**
  - Version detection
  - Database count
  - Replication status and lag
  - Slow query tracking
- **Dependencies:** MySQL command-line tools or .NET connector
- **Conflict Resolution:** Script 11 remains NET Location Tracker

**Deliverables:**
- 3 PowerShell monitoring scripts (~1,200 LOC total)
- Integration tests for each database platform
- Documentation updates
- NinjaRMM custom field mappings

---

## Phase 2: Endpoint Essentials (Weeks 3-4)

### Priority: P1 - High Impact

#### 2.1 Network Monitoring (10 fields)
**Impact:** High - Core connectivity tracking  
**File Affected:** `15_NET_Network_Monitoring.md`  
**Estimated Effort:** 2 days

##### Script TBD: Network Monitor
- **Fields:** 10 NET fields
- **Frequency:** Every 4 hours
- **Key Metrics:**
  - Connection status and type
  - Adapter speed
  - Public/private IP addresses
  - Gateway and DNS configuration
  - Bandwidth utilization
  - Packet loss percentage
- **Dependencies:** Windows networking APIs
- **Conflict Resolution:** Script 8 remains Hyper-V Host Monitor

#### 2.2 Battery Health Monitoring (10 fields)
**Impact:** Medium-High - Laptop fleet management  
**File Affected:** `13_BAT_Battery_Health.md`  
**Estimated Effort:** 1-2 days

##### Script TBD: Battery Health Monitor
- **Fields:** 10 BAT fields
- **Frequency:** Daily (status checks every 4 hours)
- **Key Metrics:**
  - Battery presence detection
  - Design vs. full charge capacity
  - Health percentage calculation
  - Cycle count tracking
  - Chemistry type
  - Runtime estimation
  - Charge status
  - Replacement recommendations
- **Dependencies:** Win32_Battery WMI class
- **Conflict Resolution:** Script 12 remains BASE Baseline Manager
- **Device Targeting:** Laptops, tablets, 2-in-1 devices only

**Deliverables:**
- 2 PowerShell monitoring scripts (~600 LOC total)
- Device type detection logic
- Documentation updates

---

## Phase 3: Domain Integration (Week 5)

### Priority: P1 - Domain-Joined Devices

#### 3.1 Active Directory Monitoring (9 fields)
**Impact:** High - Domain trust and authentication  
**File Affected:** `18_AD_Active_Directory.md`  
**Estimated Effort:** 2 days

##### Script TBD: Active Directory Monitor
- **Fields:** 9 AD fields
- **Frequency:** Every 4 hours (critical), Daily (informational)
- **Key Metrics:**
  - Domain membership status
  - Domain controller connectivity
  - Site name detection
  - Computer OU path
  - Last logon user
  - Password age tracking
  - Secure channel health
  - Sync timestamp
- **Dependencies:** Active Directory PowerShell module
- **Conflict Resolution:** Script 15 remains Cleanup Analyzer

#### 3.2 Group Policy Monitoring (6 fields)
**Impact:** Medium-High - Policy compliance  
**File Affected:** `17_GPO_Group_Policy.md`  
**Estimated Effort:** 1-2 days

##### Script TBD: Group Policy Monitor
- **Fields:** 6 GPO fields
- **Frequency:** Daily
- **Key Metrics:**
  - GPO application status
  - Last application timestamp
  - Applied GPO count
  - Error detection
  - Applied policy list (HTML)
- **Dependencies:** Group Policy PowerShell module
- **Conflict Resolution:** Script 16 remains Security Remediation

**Deliverables:**
- 2 PowerShell monitoring scripts (~500 LOC total)
- Domain-joined device targeting
- Documentation updates

---

## Phase 4: Server Roles (Weeks 6-7)

### Priority: P2 - Specialized Infrastructure

#### 4.1 Event Log Monitoring (7 fields)
**Impact:** Medium - Proactive issue detection  
**File Affected:** `16_ROLE_Additional.md`  
**Estimated Effort:** 2 days

##### Script TBD: Event Log Monitor
- **Fields:** 7 EVT fields
- **Frequency:** Daily (full scan), Every 4 hours (recent events)
- **Key Metrics:**
  - Full event log detection
  - Critical errors (24h)
  - Warnings (24h)
  - Security events (24h)
  - Top error sources
  - Summary HTML table
- **Conflict Resolution:** Script 4 remains Security Analyzer

#### 4.2 File Server Monitoring (8 fields)
**Impact:** Medium - File share health  
**File Affected:** `16_ROLE_Additional.md`  
**Estimated Effort:** 2 days

##### Script TBD: File Server Monitor
- **Fields:** 8 FS fields
- **Frequency:** Daily (config), Every 4 hours (usage)
- **Key Metrics:**
  - File Server role detection
  - Share count and summary
  - Open file tracking
  - Connected users
  - Quota violations
  - Access errors
- **Dependencies:** File Server PowerShell module
- **Conflict Resolution:** Script 5 remains Capacity Analyzer

#### 4.3 Print Server Monitoring (8 fields)
**Impact:** Medium - Print queue health  
**File Affected:** `16_ROLE_Additional.md`  
**Estimated Effort:** 2 days

##### Script TBD: Print Server Monitor
- **Fields:** 8 PRINT fields
- **Frequency:** Daily (config), Every 4 hours (status)
- **Key Metrics:**
  - Print Server role detection
  - Printer and queue counts
  - Stuck job tracking
  - Printer errors
  - Offline printer detection
  - Printer summary HTML
- **Dependencies:** Print Management PowerShell module
- **Conflict Resolution:** Script 6 remains Telemetry Collector

#### 4.4 FlexLM License Monitoring (11 fields)
**Impact:** Medium - License compliance  
**File Affected:** `16_ROLE_Additional.md`  
**Estimated Effort:** 2-3 days

##### Script TBD: FlexLM License Monitor
- **Fields:** 11 FLEXLM fields
- **Frequency:** Every 4 hours
- **Key Metrics:**
  - FlexLM installation detection
  - Version tracking
  - Vendor daemon count
  - License utilization
  - Denied requests
  - Daemon health
  - Expiration tracking
  - License summary HTML
- **Dependencies:** FlexLM lmutil.exe
- **Conflict Resolution:** Script 12 remains BASE Baseline Manager

**Deliverables:**
- 4 PowerShell monitoring scripts (~1,400 LOC total)
- Server role detection logic
- Documentation updates

---

## Phase 5: Infrastructure Services (Week 8)

### Priority: P2 - Verify and Enhance

#### 5.1 Verify Existing Scripts
**File Affected:** `14_ROLE_Infrastructure.md`  
**Estimated Effort:** 2-3 days

**Scripts to Verify:**

##### Script 1: Apache Web Server Monitor (TBD)
- **Fields:** 7 APACHE fields
- **Status:** Needs verification or implementation
- **Key Metrics:** VHost count, requests/sec, errors, worker processes

##### Script 2: DHCP Server Monitor (TBD)
- **Fields:** 9 DHCP fields
- **Status:** Needs verification or implementation
- **Key Metrics:** Scope utilization, address pools, denied leases

##### Script 3: DNS Server Monitor (TBD)
- **Fields:** 9 DNS fields
- **Status:** Needs verification or implementation
- **Key Metrics:** Zone count, queries/sec, failed queries, zone transfers

##### Script TBD: Veeam Backup Monitor
- **Fields:** 12 VEEAM fields
- **Status:** Missing (Script 13 is DRIFT Detector)
- **Key Metrics:** Backup job status, repository space, warnings, failures
- **Conflict Resolution:** Script 13 remains DRIFT Detector

**Deliverables:**
- Verification report for Scripts 1-3
- Implementation of Veeam Monitor
- 1-4 PowerShell scripts depending on verification results

---

## Phase 6: Remediation Scripts (Weeks 9-10)

### Priority: P3 - Automation Enhancement

**Scripts Referenced in Conditions (Not Yet Implemented):**

#### Infrastructure Remediation
- **Script 42:** Restart IIS App Pools
- **Script 43:** Trigger SQL Backup
- **Script 44:** MySQL Replication Repair
- **Script 45:** Veeam Job Retry
- **Script 46:** DHCP Scope Alert
- **Script 47:** DNS Service Restart

#### Server Role Remediation
- **Script 48:** File Share Diagnostics
- **Script 49:** Clear Print Queues
- **Script 50:** Hyper-V Health Check
- **Script 51:** FlexLM Alert
- **Script 52:** BitLocker Enablement

**Deliverables:**
- 11 PowerShell remediation scripts (~1,100 LOC total)
- Safe execution guards
- Rollback procedures
- Documentation

---

## Implementation Guidelines

### Script Numbering Convention

**Proposed Standard:**
```
1-50:   Monitoring scripts (data collection)
51-100: Remediation scripts (automated fixes)
101+:   Specialized/custom scripts
```

**Assignment Strategy:**
- Assign new monitoring scripts starting at 37 (next available)
- Document conflicts clearly in code comments
- Update 51_Field_to_Script_Complete_Mapping.md after each script

### Code Standards

**All New Scripts Must Include:**
1. Header block with script number, purpose, fields updated
2. Parameter validation
3. Error handling with Try/Catch
4. Logging to NinjaRMM activity log
5. Field update confirmation
6. Runtime optimization (target < 60 seconds)
7. Device applicability checks
8. Graceful degradation for missing dependencies

### Testing Requirements

**Each Script Must Pass:**
1. Unit tests (mock data)
2. Integration tests (lab environment)
3. Production pilot (5-10 devices)
4. Full rollout validation

### Documentation Requirements

**For Each Script:**
1. Update corresponding core documentation file
2. Update 51_Field_to_Script_Complete_Mapping.md
3. Add script to version control with comments
4. Create deployment guide
5. Document known limitations

---

## Resource Requirements

### Development Team
- **PowerShell Developer:** 1 FTE (8 weeks)
- **QA Engineer:** 0.5 FTE (testing phases)
- **Technical Writer:** 0.25 FTE (documentation)

### Infrastructure
- Test lab with all monitored services (IIS, SQL, MySQL, etc.)
- NinjaRMM test environment
- Version control access

### Timeline
- **Phase 1-2:** 4 weeks (Critical + Endpoints)
- **Phase 3:** 1 week (Domain Integration)
- **Phase 4:** 2 weeks (Server Roles)
- **Phase 5:** 1 week (Infrastructure Verification)
- **Phase 6:** 2 weeks (Remediation)
- **Total:** 10 weeks

---

## Success Metrics

### Quantitative
- Field coverage: 100% (277/277 fields supported)
- Script conflicts: 0 (all resolved)
- Average script runtime: < 45 seconds
- Test coverage: 100% (all scripts tested)

### Qualitative
- Clear script numbering convention adopted
- Automated validation implemented
- Documentation up-to-date
- Team trained on new scripts

---

## Risk Mitigation

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Database credentials required | High | Use NinjaRMM secure variables |
| FlexLM vendor-specific parsing | Medium | Implement flexible parsing logic |
| Performance impact on endpoints | Medium | Optimize queries, stagger execution |
| WMI failures on legacy systems | Low | Graceful degradation, alternative methods |

### Project Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Resource availability | High | Front-load critical phases |
| Scope creep | Medium | Strict phase boundaries |
| Testing delays | Medium | Parallel test environment setup |

---

## Next Steps

### Immediate (This Week)
1. ✅ Complete filename header audit (DONE)
2. ✅ Document script conflicts (DONE)
3. ⏳ Review action plan with stakeholders
4. ⏳ Allocate development resources
5. ⏳ Setup test lab environment

### Week 1-2 (Phase 1 Start)
1. Begin IIS/MSSQL/MySQL script development
2. Create script templates and standards
3. Setup CI/CD pipeline for script deployment
4. Begin unit test development

### Ongoing
1. Weekly progress reviews
2. Documentation updates as scripts complete
3. Field validation testing
4. Performance monitoring

---

**Document Owner:** Technical Lead  
**Last Updated:** February 3, 2026  
**Next Review:** Weekly during implementation  
**Related Documents:**
- [AUDIT_2026-02-03_Filename_Header_Corrections.md](./AUDIT_2026-02-03_Filename_Header_Corrections.md)
- [51_Field_to_Script_Complete_Mapping.md](./51_Field_to_Script_Complete_Mapping.md)
