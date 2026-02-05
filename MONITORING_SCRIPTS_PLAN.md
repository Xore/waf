# Monitoring Subfolder Documentation Plan

## Goal
Document all 15 specialized monitoring scripts in /scripts/monitoring with comprehensive descriptions, field mappings, and enhanced logging.

## Script Inventory

### Infrastructure Services (5 scripts)
1. Script_01_Apache_Web_Server_Monitor.ps1 - Apache HTTP monitoring
2. Script_02_DHCP_Server_Monitor.ps1 - DHCP scope and lease tracking
3. Script_03_DNS_Server_Monitor.ps1 - DNS zone and query monitoring
4. Script_37_IIS_Web_Server_Monitor.ps1 - IIS application pool and site monitoring
5. Script_48_Veeam_Backup_Monitor.ps1 - Veeam backup job monitoring

### Database Servers (2 scripts)
6. Script_38_MSSQL_Server_Monitor.ps1 - SQL Server database monitoring
7. Script_39_MySQL_Server_Monitor.ps1 - MySQL/MariaDB monitoring

### File & Print Services (2 scripts)
8. Script_45_File_Server_Monitor.ps1 - SMB share monitoring
9. Script_46_Print_Server_Monitor.ps1 - Print queue monitoring

### Enterprise Services (3 scripts)
10. Script_42_Active_Directory_Monitor.ps1 - AD health and replication (largest: 20KB)
11. Script_43_Group_Policy_Monitor.ps1 - GPO processing and compliance
12. Script_47_FlexLM_License_Monitor.ps1 - FlexLM license server monitoring

### System Monitoring (3 scripts)
13. Script_40_Network_Monitor.ps1 - Network adapter and connectivity
14. Script_41_Battery_Health_Monitor.ps1 - Laptop battery monitoring
15. Script_44_Event_Log_Monitor.ps1 - Event log health and analysis

## Execution Plan

### Batch 6: Infrastructure Services (5 scripts)
- Apache, DHCP, DNS, IIS, Veeam
- Estimated time: 45 minutes
- Priority: High (core infrastructure)

### Batch 7: Database & File Services (4 scripts)
- MSSQL, MySQL, File Server, Print Server
- Estimated time: 35 minutes
- Priority: High (data services)

### Batch 8: Enterprise & System (6 scripts)
- Active Directory, Group Policy, FlexLM, Network, Battery, Event Logs
- Estimated time: 55 minutes
- Priority: Medium (specialized monitoring)

## Documentation Standards

Apply same standards as main scripts:
- Comprehensive .SYNOPSIS and .DESCRIPTION
- Detailed monitoring scope and health classifications
- Field documentation with data types
- Dependencies and prerequisites
- Enhanced logging with INFO/WARNING/ERROR/SUCCESS
- Security notes where applicable
- Framework Version 4.0 tagging

## Progress Tracking

- [ ] Batch 6: Infrastructure Services (0/5)
- [ ] Batch 7: Database & File Services (0/4)
- [ ] Batch 8: Enterprise & System (0/6)

## Total Scope
- 15 specialized monitoring scripts
- Estimated total time: 2-3 hours
- Expected completion: Same session

## Created
February 5, 2026 - 5:00 PM CET
