# Oracle Database Monitoring - Action Plan

**Document Version:** 1.0  
**Created:** 2026-02-11  
**Author:** Windows Automation Framework  
**Target Platform:** Windows Server with Oracle Database  
**Framework:** NinjaRMM Custom Field Framework v4.0

---

## Executive Summary

This action plan outlines the development of comprehensive PowerShell-based monitoring scripts for Oracle databases hosted on Windows servers, integrated with NinjaRMM. The solution follows WAF (Windows Automation Framework) standards and aligns with the existing infrastructure monitoring patterns established in the NinjaRMM framework.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Architecture Design](#architecture-design)
4. [Custom Fields Design](#custom-fields-design)
5. [Script Development Plan](#script-development-plan)
6. [Implementation Phases](#implementation-phases)
7. [Testing Strategy](#testing-strategy)
8. [Integration with NinjaRMM](#integration-with-ninjarmm)
9. [Monitoring Metrics](#monitoring-metrics)
10. [Alerting Strategy](#alerting-strategy)
11. [Documentation Requirements](#documentation-requirements)
12. [Timeline and Milestones](#timeline-and-milestones)

---

## Project Overview

### Objectives

- Develop production-ready PowerShell scripts for Oracle database monitoring on Windows
- Integrate with NinjaRMM custom field framework
- Provide comprehensive health, performance, and capacity metrics
- Enable proactive alerting and predictive analysis
- Follow established WAF coding standards and patterns

### Scope

**In Scope:**
- Oracle database instance health monitoring
- Tablespace capacity tracking
- Session and connection monitoring
- Performance metrics collection
- Query performance analysis
- Backup status verification
- Alert log monitoring
- Archive log management tracking
- RMAN backup status
- Database availability monitoring

**Out of Scope:**
- Oracle RAC specific monitoring (future phase)
- Data Guard monitoring (future phase)
- Oracle GoldenGate monitoring (future phase)
- Database tuning automation
- Automated recovery procedures

---

## Prerequisites

### Environment Requirements

1. **Oracle Database**
   - Oracle 11g, 12c, 18c, 19c, or 21c
   - Windows Server 2016/2019/2022
   - Oracle Client installed on monitoring server

2. **PowerShell**
   - PowerShell 5.1 or higher
   - Oracle PowerShell modules (Oracle.ManagedDataAccess.Core)

3. **NinjaRMM**
   - NinjaRMM agent installed
   - Custom field support enabled
   - API access for advanced integration

4. **Credentials**
   - Database monitoring user with appropriate privileges
   - Secure credential storage mechanism
   - Read-only access to system views

### Required Oracle Privileges

```sql
-- Monitoring user setup
CREATE USER ninja_monitor IDENTIFIED BY SecurePassword123;

GRANT CONNECT TO ninja_monitor;
GRANT SELECT_CATALOG_ROLE TO ninja_monitor;
GRANT SELECT ON v_$database TO ninja_monitor;
GRANT SELECT ON v_$instance TO ninja_monitor;
GRANT SELECT ON v_$session TO ninja_monitor;
GRANT SELECT ON v_$datafile TO ninja_monitor;
GRANT SELECT ON dba_tablespaces TO ninja_monitor;
GRANT SELECT ON dba_data_files TO ninja_monitor;
GRANT SELECT ON dba_free_space TO ninja_monitor;
GRANT SELECT ON v_$recovery_file_dest TO ninja_monitor;
GRANT SELECT ON v_$flash_recovery_area_usage TO ninja_monitor;
GRANT SELECT ON v_$rman_backup_job_details TO ninja_monitor;
GRANT SELECT ON v_$archived_log TO ninja_monitor;
```

---

## Architecture Design

### Component Structure

```
scripts/database/oracle/
├── ACTION_PLAN.md                          # This document
├── README.md                                # Implementation guide
├── core/
│   ├── Oracle-Connection-Module.ps1        # Connection management
│   ├── Oracle-Query-Helper.ps1             # Query execution wrapper
│   └── Oracle-Credential-Manager.ps1       # Secure credential handling
├── monitoring/
│   ├── 37-Oracle-Instance-Health.ps1       # Main instance monitoring
│   ├── 38-Oracle-Tablespace-Monitor.ps1    # Tablespace capacity
│   ├── 39-Oracle-Session-Monitor.ps1       # Session tracking
│   ├── 40-Oracle-Performance-Metrics.ps1   # Performance data
│   └── 41-Oracle-Backup-Monitor.ps1        # Backup verification
├── utilities/
│   ├── Test-OracleConnection.ps1           # Connection testing
│   ├── Get-OracleVersion.ps1               # Version detection
│   └── Initialize-OracleMonitoring.ps1     # Setup script
└── docs/
    ├── FIELD_DEFINITIONS.md                 # Custom field documentation
    ├── TROUBLESHOOTING.md                   # Common issues
    └── PERFORMANCE_TUNING.md                # Optimization guide
```

### Data Flow

```
[Oracle Database] <--SQL--> [PowerShell Script] <--Custom Fields--> [NinjaRMM]
                                    |
                                    v
                            [Error Logging]
                            [Performance Data]
                            [Alert Generation]
```

---

## Custom Fields Design

### Field Naming Convention

Following NinjaRMM framework standards:
- Prefix: `ORA` (Oracle)
- Category: `DB` (Database), `TBS` (Tablespace), `PERF` (Performance)
- Format: `{PREFIX}{CATEGORY}{Descriptor}`

### Proposed Custom Fields (35 fields)

#### Instance Health Fields (8 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `ORADBInstalled` | Checkbox | Oracle database installed on system |
| `ORADBInstanceName` | Text | Primary database instance name |
| `ORADBVersion` | Text | Oracle version (e.g., 19.3.0.0.0) |
| `ORADBStatus` | Dropdown | Instance status (OPEN, MOUNTED, CLOSED) |
| `ORADBUptime` | Integer | Database uptime in hours |
| `ORADBHealthScore` | Integer | Overall health score (0-100) |
| `ORADBHealthStatus` | Dropdown | Health status (Healthy, Warning, Critical) |
| `ORADBLastCheck` | DateTime | Last monitoring check timestamp |

#### Tablespace Monitoring Fields (9 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `ORATBSCount` | Integer | Total number of tablespaces |
| `ORATBSTotalSizeGB` | Integer | Total tablespace size in GB |
| `ORATBSUsedSizeGB` | Integer | Total used space in GB |
| `ORATBSUsedPercent` | Integer | Overall space utilization percentage |
| `ORATBSCriticalCount` | Integer | Tablespaces over 90% full |
| `ORATBSWarningCount` | Integer | Tablespaces 80-90% full |
| `ORATBSCriticalList` | WYSIWYG | HTML list of critical tablespaces |
| `ORATBSAutoextendEnabled` | Checkbox | Any tablespace with autoextend disabled |
| `ORATBSSummaryHtml` | WYSIWYG | HTML summary of tablespace status |

#### Session & Performance Fields (10 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `ORADBActiveSessions` | Integer | Current active session count |
| `ORADBMaxSessions` | Integer | Maximum allowed sessions |
| `ORADBSessionUtilization` | Integer | Session utilization percentage |
| `ORADBBlockedSessions` | Integer | Currently blocked sessions |
| `ORADBLongRunningQueries` | Integer | Queries running >5 minutes |
| `ORAPERFCPUUsage` | Integer | Database CPU usage percentage |
| `ORAPERFWaitEvents` | WYSIWYG | Top wait events HTML summary |
| `ORAPERFBufferCacheHitRatio` | Integer | Buffer cache hit ratio percentage |
| `ORAPERFLibraryCacheHitRatio` | Integer | Library cache hit ratio percentage |
| `ORAPERFPhysicalReads` | Integer | Physical reads per second |

#### Backup & Recovery Fields (8 fields)

| Field Name | Type | Description |
|------------|------|-------------|
| `ORABKPLastFullBackup` | DateTime | Last successful full backup |
| `ORABKPLastIncBackup` | DateTime | Last successful incremental backup |
| `ORABKPDaysSinceFullBackup` | Integer | Days since last full backup |
| `ORABKPBackupStatus` | Dropdown | Backup health (Current, Aging, Critical) |
| `ORABKPRMANErrors24h` | Integer | RMAN errors in last 24 hours |
| `ORABKPArchivelogStatus` | Dropdown | Archivelog mode status |
| `ORABKPArchivelogCount24h` | Integer | Archive logs generated (24h) |
| `ORABKPRecoveryAreaUsage` | Integer | Flash recovery area usage percent |

---

## Script Development Plan

### Script 37: Oracle Instance Health Monitor

**Purpose:** Core instance health and availability monitoring  
**Frequency:** Every 4 hours  
**Runtime:** 30-40 seconds  
**Priority:** Critical

**Key Functions:**
- Check Oracle service status
- Verify database instance accessibility
- Collect instance version and uptime
- Calculate overall health score
- Generate health status summary

**Pseudocode:**
```powershell
# Check if Oracle database is installed
# Test Oracle service status (OracleServiceSID)
# Attempt SQL connection to instance
# Query v$instance for status, version, uptime
# Query v$database for database info
# Calculate health score based on:
#   - Service running (25 points)
#   - Database OPEN status (25 points)
#   - No critical alerts (25 points)
#   - Backup current within 24h (25 points)
# Update custom fields
# Generate HTML summary
```

### Script 38: Oracle Tablespace Monitor

**Purpose:** Tablespace capacity and growth tracking  
**Frequency:** Daily  
**Runtime:** 20-30 seconds  
**Priority:** High

**Key Functions:**
- Query all tablespace sizes and usage
- Identify critical/warning thresholds
- Check autoextend configuration
- Project capacity exhaustion dates
- Generate HTML capacity report

**Pseudocode:**
```powershell
# Query dba_tablespaces for all tablespaces
# For each tablespace:
#   - Calculate total size from dba_data_files
#   - Calculate free space from dba_free_space
#   - Calculate used percentage
#   - Check autoextend status
#   - Categorize (Critical >90%, Warning 80-90%)
# Generate HTML table of tablespace status
# Update custom fields with summary data
# Flag critical tablespaces for alerting
```

### Script 39: Oracle Session Monitor

**Purpose:** Session and connection tracking  
**Frequency:** Every 4 hours  
**Runtime:** 15-20 seconds  
**Priority:** Medium

**Key Functions:**
- Count active sessions
- Identify blocked sessions
- Detect long-running queries
- Check session limit utilization
- Alert on session issues

**Pseudocode:**
```powershell
# Query v$session for session counts
# Filter active sessions (status='ACTIVE')
# Query v$session_wait for blocked sessions
# Query v$session_longops for long operations
# Calculate session utilization vs max
# Generate session summary
# Update custom fields
```

### Script 40: Oracle Performance Metrics

**Purpose:** Database performance indicators  
**Frequency:** Every 4 hours  
**Runtime:** 25-35 seconds  
**Priority:** Medium

**Key Functions:**
- Collect buffer cache hit ratio
- Track library cache performance
- Identify top wait events
- Monitor physical I/O rates
- CPU usage tracking

**Pseudocode:**
```powershell
# Query v$sysstat for performance statistics
# Calculate buffer cache hit ratio
# Calculate library cache hit ratio
# Query v$system_event for top wait events
# Query v$osstat for CPU statistics
# Generate performance HTML summary
# Update custom fields
```

### Script 41: Oracle Backup Monitor

**Purpose:** Backup status and recovery verification  
**Frequency:** Daily  
**Runtime:** 20-25 seconds  
**Priority:** Critical

**Key Functions:**
- Verify last full/incremental backup dates
- Check RMAN backup job status
- Monitor archive log generation
- Verify recovery area usage
- Alert on backup failures

**Pseudocode:**
```powershell
# Query v$rman_backup_job_details for recent backups
# Identify last full backup (BACKUP_TYPE='D')
# Identify last incremental backup
# Calculate days since last full backup
# Query v$archived_log for archive log count
# Check v$recovery_file_dest usage
# Determine backup status (Current/Aging/Critical)
# Update custom fields
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

**Deliverables:**
- Core connection module
- Credential management system
- Query helper functions
- Test harness
- Documentation framework

**Tasks:**
1. Create Oracle connection wrapper with error handling
2. Implement secure credential storage (Windows Credential Manager)
3. Develop query execution helper with retry logic
4. Create connection testing utility
5. Write initial documentation

**Success Criteria:**
- Successful connection to test Oracle database
- Credential retrieval working
- Error handling validated
- Unit tests passing

### Phase 2: Core Monitoring Scripts (Week 3-4)

**Deliverables:**
- Script 37: Instance Health Monitor
- Script 38: Tablespace Monitor
- Custom field definitions
- HTML output formatting

**Tasks:**
1. Develop instance health monitoring script
2. Implement tablespace capacity tracking
3. Create custom field definitions in NinjaRMM
4. Design HTML output templates
5. Implement health score calculation

**Success Criteria:**
- Accurate instance status detection
- Correct tablespace capacity calculations
- Custom fields populating in NinjaRMM
- HTML output renders correctly

### Phase 3: Advanced Monitoring (Week 5-6)

**Deliverables:**
- Script 39: Session Monitor
- Script 40: Performance Metrics
- Script 41: Backup Monitor
- Performance optimization

**Tasks:**
1. Develop session monitoring functionality
2. Implement performance metrics collection
3. Create backup status verification
4. Optimize query performance
5. Add caching mechanisms

**Success Criteria:**
- All monitoring scripts operational
- Performance targets met (runtime <40s)
- Backup status accurately reported
- No false positives in testing

### Phase 4: Integration & Testing (Week 7-8)

**Deliverables:**
- Complete integration with NinjaRMM
- Test suite
- Troubleshooting guide
- Production deployment package

**Tasks:**
1. Integration testing with NinjaRMM
2. Develop automated test suite
3. Create troubleshooting documentation
4. Performance and load testing
5. Security review and hardening

**Success Criteria:**
- All integration tests passing
- Documentation complete
- Security review approved
- Ready for production deployment

---

## Testing Strategy

### Unit Testing

**Scope:**
- Individual function validation
- Error handling verification
- Input sanitization
- Output format validation

**Test Cases:**
1. Connection failure scenarios
2. Invalid credentials handling
3. Query timeout handling
4. Malformed data handling
5. Null value processing

### Integration Testing

**Scope:**
- End-to-end script execution
- NinjaRMM field population
- Multi-instance support
- Concurrent execution

**Test Scenarios:**
1. Single instance monitoring
2. Multiple instance monitoring
3. Database offline scenarios
4. Network interruption handling
5. High load conditions

### Performance Testing

**Targets:**
- Script execution time <40 seconds
- Memory usage <100 MB
- CPU usage <10% average
- No memory leaks

**Methodology:**
- Baseline performance measurement
- Load testing with multiple instances
- Long-duration monitoring (24h+)
- Resource utilization tracking

### Security Testing

**Focus Areas:**
- Credential handling
- SQL injection prevention
- Secure logging (no credential exposure)
- Least privilege verification

**Validation:**
- Code security review
- Credential encryption verification
- SQL parameterization check
- Log file security audit

---

## Integration with NinjaRMM

### Custom Field Setup

**Steps:**
1. Create custom field category: "Oracle Database"
2. Define 35 custom fields per specification
3. Configure field visibility and permissions
4. Set up field grouping for dashboard

### Script Deployment

**Deployment Method:**
- NinjaRMM Script Repository
- Scheduled execution via NinjaRMM policies
- Device-level or organization-level assignment

**Execution Schedule:**
- Script 37 (Instance Health): Every 4 hours
- Script 38 (Tablespace): Daily at 2:00 AM
- Script 39 (Sessions): Every 4 hours
- Script 40 (Performance): Every 4 hours
- Script 41 (Backup): Daily at 6:00 AM

### Condition Monitors

**Critical Conditions:**
- `ORADBHealthStatus` = "Critical"
- `ORATBSCriticalCount` > 0
- `ORABKPDaysSinceFullBackup` > 2
- `ORADBStatus` != "OPEN"

**Warning Conditions:**
- `ORADBHealthStatus` = "Warning"
- `ORATBSWarningCount` > 0
- `ORABKPDaysSinceFullBackup` > 1
- `ORADBSessionUtilization` > 80

---

## Monitoring Metrics

### Key Performance Indicators (KPIs)

#### Availability Metrics
- **Database Uptime:** Target >99.9%
- **Service Availability:** Target 100%
- **Connection Success Rate:** Target >99.5%

#### Capacity Metrics
- **Tablespace Utilization:** Warning at 80%, Critical at 90%
- **Session Utilization:** Warning at 80%, Critical at 95%
- **Recovery Area Usage:** Warning at 80%, Critical at 90%

#### Performance Metrics
- **Buffer Cache Hit Ratio:** Target >95%
- **Library Cache Hit Ratio:** Target >95%
- **Average Response Time:** Target <100ms

#### Backup Metrics
- **Backup Frequency:** Full backup every 24 hours
- **Backup Success Rate:** Target 100%
- **Recovery Point Objective (RPO):** 24 hours

### Baseline Establishment

**Baseline Collection Period:** 7 days

**Baseline Metrics:**
- Average session count
- Typical tablespace growth rate
- Normal performance ratios
- Standard backup durations

**Baseline Usage:**
- Anomaly detection
- Trend analysis
- Capacity planning
- Performance degradation alerts

---

## Alerting Strategy

### Alert Levels

#### Critical Alerts (Immediate Response)
- Database instance down
- Any tablespace >95% full
- Backup failure or >48 hours old
- Critical sessions blocked >10 minutes
- Health score <30

#### Warning Alerts (Review within 4 hours)
- Database health score 30-60
- Tablespace 80-95% full
- Backup >24 hours old
- Session utilization >80%
- Performance degradation >20%

#### Informational Alerts (Review daily)
- Long-running queries detected
- Increased archive log generation
- Performance trends
- Capacity planning notifications

### Alert Routing

**Notification Channels:**
- NinjaRMM dashboard alerts
- Email notifications
- Ticketing system integration
- SMS for critical alerts (optional)

**Escalation Path:**
1. **Tier 1 (0-15 min):** Automated ticket creation
2. **Tier 2 (15-30 min):** Database administrator notification
3. **Tier 3 (30-60 min):** Manager escalation
4. **Tier 4 (60+ min):** Executive notification

---

## Documentation Requirements

### Technical Documentation

1. **Installation Guide**
   - Prerequisites checklist
   - Step-by-step installation
   - Configuration procedures
   - Troubleshooting common issues

2. **Administrator Guide**
   - Custom field reference
   - Script execution details
   - Alert configuration
   - Performance tuning

3. **Developer Guide**
   - Code architecture
   - Module documentation
   - Extension guidelines
   - Testing procedures

### Operational Documentation

1. **Runbook**
   - Standard operating procedures
   - Alert response procedures
   - Escalation protocols
   - Recovery procedures

2. **Troubleshooting Guide**
   - Common error messages
   - Diagnostic procedures
   - Resolution steps
   - FAQ section

3. **Change Log**
   - Version history
   - Feature additions
   - Bug fixes
   - Breaking changes

---

## Timeline and Milestones

### 8-Week Implementation Schedule

```
Week 1-2: Foundation
├── Day 1-3: Connection module development
├── Day 4-5: Credential management
├── Day 6-7: Query helpers
├── Day 8-10: Testing framework
└── Milestone: Core modules complete

Week 3-4: Core Monitoring
├── Day 11-13: Instance health monitoring
├── Day 14-16: Tablespace monitoring
├── Day 17-18: Custom field setup
├── Day 19-20: HTML formatting
└── Milestone: Core scripts operational

Week 5-6: Advanced Monitoring
├── Day 21-23: Session monitoring
├── Day 24-26: Performance metrics
├── Day 27-29: Backup monitoring
├── Day 30: Performance optimization
└── Milestone: All scripts complete

Week 7-8: Integration & Deployment
├── Day 31-33: Integration testing
├── Day 34-35: Documentation
├── Day 36-37: Security review
├── Day 38-39: Production preparation
├── Day 40: Production deployment
└── Milestone: Production ready
```

### Key Deliverables

| Week | Deliverable | Status |
|------|-------------|--------|
| 1-2 | Core modules and connection framework | Planned |
| 3-4 | Instance & tablespace monitoring | Planned |
| 5-6 | Session, performance, backup monitoring | Planned |
| 7-8 | Complete integration and documentation | Planned |

---

## Success Criteria

### Technical Criteria
- [ ] All 5 monitoring scripts functional
- [ ] All 35 custom fields populating correctly
- [ ] Script execution time <40 seconds average
- [ ] Zero false positive alerts in testing
- [ ] 100% test coverage for critical paths
- [ ] Security review passed
- [ ] Performance targets met

### Operational Criteria
- [ ] Documentation complete and reviewed
- [ ] Training materials prepared
- [ ] Runbooks finalized
- [ ] Alert thresholds validated
- [ ] Escalation procedures defined
- [ ] Backup and recovery tested

### Business Criteria
- [ ] Stakeholder approval obtained
- [ ] Budget within allocation
- [ ] Timeline met
- [ ] Risk mitigation plan approved
- [ ] Production deployment authorized

---

## Risk Assessment

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Oracle version incompatibility | High | Medium | Test against all supported versions |
| Performance degradation | High | Low | Implement query optimization and caching |
| Credential security breach | Critical | Low | Use Windows Credential Manager, encrypt at rest |
| Network connectivity issues | Medium | Medium | Implement retry logic and timeout handling |

### Operational Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| False positive alerts | Medium | Medium | Extensive testing and threshold tuning |
| Monitoring overhead | Medium | Low | Performance testing and optimization |
| Database permission issues | High | Medium | Document required privileges, provide setup script |
| Alert fatigue | Medium | High | Proper alert categorization and throttling |

---

## Next Steps

### Immediate Actions (Week 1)

1. **Environment Setup**
   - Provision test Oracle database
   - Install Oracle client on monitoring server
   - Configure NinjaRMM test environment
   - Set up development workspace

2. **Team Preparation**
   - Assign development resources
   - Schedule kickoff meeting
   - Review standards and guidelines
   - Establish communication channels

3. **Technical Preparation**
   - Review Oracle documentation
   - Study NinjaRMM API
   - Research PowerShell Oracle modules
   - Prototype basic connection

### Approval Requirements

- [ ] Technical architecture approved
- [ ] Custom field design approved
- [ ] Resource allocation approved
- [ ] Timeline approved
- [ ] Budget approved
- [ ] Security review scheduled

---

## Appendix

### A: Reference Architecture

See existing NinjaRMM scripts for patterns:
- Script 3: DNS Server Monitor (infrastructure pattern)
- Script 11: MySQL/MariaDB Monitor (database pattern)
- Script 28: Security Surface Telemetry (HTML formatting)

### B: Naming Conventions

Follows WAF standards:
- Script naming: `{Number}-{Category}-{Function}.ps1`
- Function naming: `{Verb}-{Noun}` (PowerShell approved verbs)
- Variable naming: camelCase for local, PascalCase for global
- No emojis or special characters in code

### C: Tools and Resources

**Development Tools:**
- Visual Studio Code with PowerShell extension
- Oracle SQL Developer
- NinjaRMM web console
- Git for version control

**Testing Tools:**
- Pester (PowerShell testing framework)
- PSScriptAnalyzer (code quality)
- Oracle Enterprise Manager (validation)

**Documentation Tools:**
- Markdown for all documentation
- Mermaid for diagrams
- GitHub for repository

---

## Document Control

**Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|----------|
| 1.0 | 2026-02-11 | WAF Team | Initial action plan created |

**Review Schedule:**
- Weekly progress reviews
- Bi-weekly stakeholder updates
- Phase gate reviews at end of each phase

**Approval:**

| Role | Name | Date | Signature |
|------|------|------|----------|
| Technical Lead | | | |
| DBA Lead | | | |
| Project Manager | | | |
| Security Officer | | | |

---

**Document End**
