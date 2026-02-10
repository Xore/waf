# NinjaRMM Custom Field Framework - Database and Web Server Infrastructure
**File:** 12_ROLE_Database_Web.md  
**Categories:** IIS (Web Server) + MSSQL (SQL Server) + MYSQL (MySQL/MariaDB)  
**Field Count:** 26 fields  
**Target:** Servers running IIS, SQL Server, or MySQL

---

## Overview

Comprehensive monitoring for web and database server infrastructure including IIS websites, SQL Server instances, and MySQL databases with health status tracking.

**Note:** Scripts 9-11 referenced below are incorrectly assigned. Script 9 is Risk Classifier, Script 10 is Update Compliance Monitor, Script 11 is NET Location Tracker. IIS, MSSQL, and MySQL monitoring scripts need to be implemented.

---

## IIS - Web Server Fields (11 fields)

### IISInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **TBD: IIS Web Server Monitor** (Script 9 conflict - currently Risk Classifier)
- **Update Frequency:** Every 4 hours

### IISSiteCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISSiteStatusSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISAppPoolCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISAppPoolsStopped
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISWorkerProcessCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISRequestQueueLength
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISFailedRequestCount24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISLastError
- **Type:** Text
- **Max Length:** 1000 characters
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISVersion
- **Type:** Text
- **Max Length:** 50 characters
- **Default:** Not Installed
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

### IISHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **TBD: IIS Web Server Monitor**
- **Update Frequency:** Every 4 hours

---

## MSSQL - SQL Server Fields (8 fields)

### MSSQLInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **TBD: MSSQL Server Monitor** (Script 10 conflict - currently Update Compliance)
- **Update Frequency:** Every 4 hours

### MSSQLInstanceCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: MSSQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MSSQLInstanceSummary
- **Type:** WYSIWYG
- **Default:** Empty
- **Populated By:** **TBD: MSSQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MSSQLDatabaseCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: MSSQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MSSQLFailedJobsCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: MSSQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MSSQLLastBackup
- **Type:** DateTime
- **Default:** Empty
- **Populated By:** **TBD: MSSQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MSSQLTransactionLogSizeMB
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: MSSQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MSSQLHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **TBD: MSSQL Server Monitor**
- **Update Frequency:** Every 4 hours

---

## MYSQL - MySQL/MariaDB Fields (7 fields)

### MYSQLInstalled
- **Type:** Checkbox
- **Default:** False
- **Populated By:** **TBD: MySQL Server Monitor** (Script 11 conflict - currently NET Location)
- **Update Frequency:** Every 4 hours

### MYSQLVersion
- **Type:** Text
- **Max Length:** 100 characters
- **Default:** Not Installed
- **Populated By:** **TBD: MySQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MYSQLDatabaseCount
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: MySQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MYSQLReplicationStatus
- **Type:** Dropdown
- **Valid Values:** N/A, Master, Slave, Error, Unknown
- **Default:** N/A
- **Populated By:** **TBD: MySQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MYSQLReplicationLag
- **Type:** Integer
- **Default:** 0
- **Purpose:** Seconds behind master
- **Populated By:** **TBD: MySQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MYSQLSlowQueries24h
- **Type:** Integer
- **Default:** 0
- **Populated By:** **TBD: MySQL Server Monitor**
- **Update Frequency:** Every 4 hours

### MYSQLHealthStatus
- **Type:** Dropdown
- **Valid Values:** Healthy, Warning, Critical, Unknown
- **Default:** Unknown
- **Populated By:** **TBD: MySQL Server Monitor**
- **Update Frequency:** Every 4 hours

---

## Compound Conditions

### IIS Application Pool Failure
```
Condition:
  IISInstalled = True
  AND IISAppPoolsStopped > 0

Action:
  Priority: P2 High
  Automation: **TBD: Script 42** - Restart IIS App Pools (not yet implemented)
  Ticket: IIS application pool stopped
```

### SQL Backup Overdue
```
Condition:
  MSSQLInstalled = True
  AND (MSSQLLastBackup > 24 hours OR MSSQLLastBackup = NULL)

Action:
  Priority: P1 Critical
  Automation: **TBD: Script 43** - Trigger SQL Backup (not yet implemented)
  Ticket: SQL Server backup overdue
```

### MySQL Replication Broken
```
Condition:
  MYSQLInstalled = True
  AND MYSQLReplicationStatus = "Error"

Action:
  Priority: P1 Critical
  Automation: **TBD: Script 44** - MySQL Replication Repair (not yet implemented)
  Ticket: MySQL replication failure
```

---

**Total Fields This File:** 26 fields  
**Scripts Required:** IIS, MSSQL, MySQL monitors (TBD) + Scripts 42-44 (remediation - TBD)  
**Update Frequency:** Every 4 hours  
**Priority Level:** Critical (Infrastructure Services)

**Critical Issue:** All 26 fields in this document have NO script support. Scripts 9-11 are already used for other purposes. New monitoring scripts must be created.

---

**File:** 12_ROLE_Database_Web.md  
**Last Updated:** February 2, 2026  
**Framework Version:** 3.0 Complete
