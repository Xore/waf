# Windows Automation Framework - Architecture

**Version:** 3.0  
**Document Status:** Current  
**Last Updated:** 2026-02-10

---

## 🏛️ Overview

The Windows Automation Framework (WAF) is an enterprise-grade, modular monitoring and automation platform built on PowerShell, designed for seamless integration with Remote Monitoring and Management (RMM) platforms, specifically NinjaRMM.

### Design Principles

1. **Modularity** - Independent, single-purpose scripts
2. **Reliability** - Comprehensive error handling and validation
3. **Observability** - Detailed logging and execution tracking
4. **Scalability** - Efficient execution across large deployments
5. **Maintainability** - Consistent standards and documentation
6. **Integration** - Native RMM platform compatibility

---

## 🏯 System Architecture

### High-Level Architecture

```
┌────────────────────────────────────────┐
│        NinjaRMM Platform (Cloud)           │
│  ┌──────────────────────────────────┐   │
│  │  Script Repository & Scheduler   │   │
│  │  Custom Field Management         │   │
│  │  Alerting & Notification Engine  │   │
│  └──────────────────────────────────┘   │
└────────────────────────────────────────┘
                    │
                    │ HTTPS/API
                    │
                    ↓
┌────────────────────────────────────────┐
│          NinjaRMM Agent                  │
│      (Installed on each endpoint)        │
└────────────────────────────────────────┘
                    │
                    │ Local Execution
                    │
                    ↓
┌────────────────────────────────────────┐
│       WAF Scripts (PowerShell)           │
│  ┌──────────────────────────────────┐   │
│  │  Core Framework Components      │   │
│  │  - Logging (Write-Log)          │   │
│  │  - Field Updates (Set-NinjaField)│   │
│  │  - Error Tracking               │   │
│  │  - Execution Timing             │   │
│  └──────────────────────────────────┘   │
└────────────────────────────────────────┘
                    │
                    │ WMI/CIM/API
                    │
                    ↓
┌────────────────────────────────────────┐
│       Target System Components          │
│  ┌──────────────────────────────────┐   │
│  │  Windows OS                     │   │
│  │  Hyper-V (if applicable)        │   │
│  │  Server Roles (DNS, File, etc)  │   │
│  │  Performance Counters           │   │
│  │  Event Logs                     │   │
│  │  Registry                       │   │
│  └──────────────────────────────────┘   │
└────────────────────────────────────────┘
```

---

## 📦 Component Architecture

### Script Categories

#### 1. **Hyper-V Monitoring Suite** (👑 Flagship)

**Purpose:** Comprehensive Hyper-V infrastructure monitoring

```
Hyper-V Suite Architecture:

┌──────────────────────────────────────────────┐
│           Script 8: Multi-Host Aggregator          │
│         (Cluster-wide analysis & balance)         │
└──────────────────────────────────────────────┘
      │                          │                      │
      │                          │                      │
┌─────┼─────┐     ┌───────┼───────┐      ┌─────┼─────┐
│ Script 5 │     │  Script 6  │      │ Script 7 │
│ Cluster  │     │Performance│      │ Storage  │
│  Health  │     │  Monitor  │      │   Perf   │
└──────────┘     └─────────────┘      └──────────┘
      │                          │                      │
      │                          │                      │
┌─────┼───────────────────┼───────────────────┼─────┐
│          Core Host & VM Monitoring Layer          │
├───────────────────────────────────────────────┤
│  Script 1: VM Inventory & Health                  │
│  Script 2: VM Backup Status                       │
│  Script 3: Host Resources & Capacity              │
│  Script 4: VM Replication Monitor                 │
└───────────────────────────────────────────────┘
                          │
                          ↓
        ┌───────────────────────────┐
        │   Hyper-V Infrastructure  │
        │  (VMs, Hosts, Clusters)  │
        └───────────────────────────┘
```

**Characteristics:**
- All V3 compliant
- 109 custom fields
- Comprehensive error handling
- HTML report generation
- Threshold-based alerting

#### 2. **Core Monitoring Scripts**

**Categories:**
- Health & Stability (10 scripts)
- Server-Specific Monitoring (8 scripts)
- Security & Compliance (11 scripts)
- Performance & Capacity (5 scripts)
- Remediation Tools (5 scripts)
- Patching & Validation (5 scripts)

**Architecture Pattern:**
```
Script Execution Flow:

1. Initialization
   └─> Set execution start time
   └─> Initialize error tracking
   └─> Log script start

2. Data Collection
   └─> Query system components
   └─> Process data
   └─> Calculate metrics

3. Analysis
   └─> Apply thresholds
   └─> Identify issues
   └─> Generate recommendations

4. Reporting
   └─> Update custom fields
   └─> Generate HTML reports
   └─> Log results

5. Cleanup (finally block)
   └─> Calculate execution time
   └─> Report errors
   └─> Exit with appropriate code
```

---

## 📊 Data Flow Architecture

### Typical Script Execution Flow

```
┌──────────────────────────────────────────────┐
│            NinjaRMM Scheduler Triggers              │
└──────────────────────────────────────────────┘
                       │
                       ↓
┌──────────────────────────────────────────────┐
│              PowerShell Script Starts               │
├──────────────────────────────────────────────┤
│  1. Initialize tracking variables                  │
│     - $ExecutionStartTime = Get-Date               │
│     - $ErrorsEncountered = 0                       │
│     - $ErrorDetails = @()                          │
└──────────────────────────────────────────────┘
                       │
                       ↓
┌──────────────────────────────────────────────┐
│         2. Query System Components (WMI/CIM)        │
├──────────────────────────────────────────────┤
│  - Get-VM (Hyper-V VMs)                            │
│  - Get-CimInstance Win32_* (System info)          │
│  - Get-Counter (Performance counters)             │
│  - Get-WinEvent (Event logs)                      │
│  - Get-Service (Service status)                   │
└──────────────────────────────────────────────┘
                       │
                       ↓
┌──────────────────────────────────────────────┐
│      3. Process & Analyze Data                      │
├──────────────────────────────────────────────┤
│  - Calculate metrics                               │
│  - Apply threshold logic                          │
│  - Identify issues                                │
│  - Generate recommendations                       │
│  - Create HTML reports                            │
└──────────────────────────────────────────────┘
                       │
                       ↓
┌──────────────────────────────────────────────┐
│     4. Update NinjaRMM Custom Fields               │
├──────────────────────────────────────────────┤
│  Set-NinjaField calls:                             │
│  - Status fields (HEALTHY/WARNING/CRITICAL)       │
│  - Metric fields (counts, percentages)            │
│  - Report fields (HTML WYSIWYG)                   │
│  - Timestamp fields (LastScan)                    │
└──────────────────────────────────────────────┘
                       │
                       ↓
┌──────────────────────────────────────────────┐
│   5. Finally Block (Mandatory Cleanup)            │
├──────────────────────────────────────────────┤
│  - Calculate execution duration                    │
│  - Log execution time                             │
│  - Report error summary                           │
│  - Exit with appropriate code (0-99)              │
└──────────────────────────────────────────────┘
                       │
                       ↓
┌──────────────────────────────────────────────┐
│       NinjaRMM Receives Exit Code & Data          │
├──────────────────────────────────────────────┤
│  - Custom fields updated in database               │
│  - Conditions evaluated for alerting              │
│  - Execution logged                               │
└──────────────────────────────────────────────┘
```

---

## 🛡️ Error Handling Architecture

### V3 Error Handling Standard

```powershell
# Script initialization
$ExecutionStartTime = Get-Date
$ErrorsEncountered = 0
$ErrorDetails = @()

try {
    # Main script logic
    Write-Log "Starting operation..."
    
    # Operation that might fail
    $Result = Get-SomeData -ErrorAction Stop
    
} catch {
    Write-Log "Error: $($_.Exception.Message)" -Level ERROR
    $ErrorsEncountered++
    $ErrorDetails += $_.Exception.Message
    
    # Update error status
    Set-NinjaField -FieldName "scriptStatus" -Value "ERROR"
    
    exit 99  # Unexpected error
} finally {
    # Always executes
    $ExecutionEndTime = Get-Date
    $ExecutionDuration = ($ExecutionEndTime - $ExecutionStartTime).TotalSeconds
    
    Write-Log "Execution Time: $([Math]::Round($ExecutionDuration, 2)) seconds"
    
    if ($ErrorsEncountered -gt 0) {
        Write-Log "Errors Encountered: $ErrorsEncountered"
        Write-Log "Error Summary: $($ErrorDetails -join '; ')"
    }
}
```

### Exit Code Standard

| Exit Code | Meaning | Use Case |
|-----------|---------|----------|
| 0 | Success | Normal completion |
| 1 | Not applicable | Feature not installed |
| 2 | Configuration error | Missing dependencies |
| 3-98 | Specific errors | Component-specific failures |
| 99 | Unexpected error | Unhandled exceptions |

---

## 🔌 Integration Points

### NinjaRMM Integration

#### Custom Field Management

```powershell
function Set-NinjaField {
    param(
        [string]$FieldName,
        [AllowNull()]
        [object]$Value
    )
    
    try {
        # Primary method: Native NinjaRMM cmdlet
        if (Get-Command Ninja-Property-Set -ErrorAction SilentlyContinue) {
            Ninja-Property-Set -Name $FieldName -Value $Value
        }
        
        # Fallback method: Registry
        $RegPath = "HKLM:\SOFTWARE\NinjaRMMAgent\CustomFields"
        if (Test-Path $RegPath) {
            Set-ItemProperty -Path $RegPath -Name $FieldName -Value $Value
        }
    } catch {
        Write-Log "Failed to set field $FieldName : $($_.Exception.Message)" -Level WARNING
    }
}
```

#### Custom Field Types

| Type | Use Case | Example |
|------|----------|----------|
| **Text** | Status, lists, short strings | "HEALTHY", "WARNING" |
| **Integer** | Counts, IDs | 15, 42 |
| **Float** | Percentages, ratios | 85.5, 2.3 |
| **DateTime** | Timestamps | "2026-02-10 23:51:00" |
| **WYSIWYG** | HTML reports | `<div>...</div>` |

---

## 📋 Logging Architecture

### Standardized Logging Function

```powershell
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'ERROR'   { Write-Error $LogMessage }
        'WARNING' { Write-Warning $LogMessage }
        'DEBUG'   { Write-Verbose $LogMessage }
        default   { Write-Output $LogMessage }
    }
}
```

### Log Levels

- **INFO:** Normal operational messages
- **WARNING:** Non-critical issues detected
- **ERROR:** Failures requiring attention
- **DEBUG:** Detailed diagnostic information

---

## 🚀 Performance Optimization

### Design Patterns for Performance

1. **Efficient Data Collection**
   - Use `-ErrorAction SilentlyContinue` for optional operations
   - Batch WMI/CIM queries where possible
   - Filter data at source, not in PowerShell

2. **Minimal Memory Footprint**
   - Stream large datasets
   - Clear variables after use
   - Avoid unnecessary object creation

3. **Execution Time Limits**
   - All scripts have documented timeout values
   - Operations designed to complete within timeouts
   - Fallback mechanisms for slow operations

4. **Parallel Execution Support**
   - Scripts designed to run concurrently
   - No file system locks
   - Independent data collection

---

## 🔒 Security Architecture

### Execution Context

**All scripts require:**
- Administrator privileges (except where noted)
- PowerShell 5.1+
- Execution Policy: RemoteSigned or higher

### Security Best Practices

1. **No Credential Storage**
   - No hardcoded credentials
   - Use SYSTEM context via NinjaRMM
   - Leverage Windows authentication

2. **Minimal Permissions**
   - Read-only operations where possible
   - Write only to designated registry keys
   - No modifications to system files

3. **Audit Trail**
   - All operations logged
   - Execution times recorded
   - Error tracking maintained

---

## 📊 Scalability Considerations

### Large-Scale Deployment

**Tested Scales:**
- **Hyper-V:** Up to 100 VMs per host
- **Endpoints:** 1000+ devices per tenant
- **Execution:** 50+ concurrent script runs

**Performance Characteristics:**
- **CPU Impact:** <5% during execution
- **Memory:** 50-200 MB per script
- **Network:** Minimal (local queries)
- **Disk I/O:** Read-only, low impact

### Optimization Strategies

1. **Staggered Scheduling**
   - Distribute execution across time windows
   - Avoid concurrent resource-intensive scripts
   - Use execution frequency guidelines

2. **Resource Pooling**
   - Reuse WMI/CIM sessions
   - Cache static data
   - Batch operations where possible

3. **Efficient Querying**
   - Filter at source (WMI WHERE clauses)
   - Limit result sets
   - Use performance counters efficiently

---

## 👥 Modularity & Extensibility

### Adding New Scripts

**Template Structure:**
```powershell
#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    [Script purpose]

.DESCRIPTION
    [Detailed description]

.NOTES
    Author: Windows Automation Framework
    Version: 1.0
    Created: [Date]
#>

[CmdletBinding()]
param()

# Configuration
$ScriptVersion = "1.0"
$FieldPrefix = "customPrefix"

# Execution tracking
$ExecutionStartTime = Get-Date
$ErrorsEncountered = 0
$ErrorDetails = @()

# Functions
function Write-Log { ... }
function Set-NinjaField { ... }

# Main logic
try {
    # Your code here
} catch {
    # Error handling
} finally {
    # Cleanup and reporting
}
```

---

## 📚 Reference Architecture Documents

### Related Documentation

- **[README.md](README.md)** - Quick start and overview
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development guidelines
- **[DOCUMENTATION_PROGRESS.md](DOCUMENTATION_PROGRESS.md)** - Implementation tracker

### Future Architecture Enhancements

- 🔄 Real-time monitoring capabilities
- 📊 Advanced analytics and ML integration
- 🔗 Multi-RMM platform support
- 🌐 Cloud-native execution options
- 📦 Module packaging and distribution

---

**Document Version:** 1.0  
**Last Review:** 2026-02-10  
**Next Review:** 2026-03-10
