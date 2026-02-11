# Getting Started with Windows Automation Framework (WAF)

Complete guide to setting up and deploying WAF in your environment.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Understanding Repository Structure](#understanding-repository-structure)
- [First Script Deployment](#first-script-deployment)
- [NinjaOne Integration](#ninjaone-integration)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## Prerequisites

### System Requirements

**Supported Operating Systems:**
- Windows Server 2016 or later
- Windows Server 2019 (recommended)
- Windows Server 2022
- Windows 10 (for workstation scripts)
- Windows 11 (for workstation scripts)

**PowerShell Requirements:**
- PowerShell 5.1 or later (included in supported OS versions)
- Execution policy allowing script execution
- Administrator privileges for most scripts

### Network Requirements

- Internet connectivity (for downloading from GitHub)
- Access to monitored resources (servers, services, etc.)
- NinjaOne agent installed (for RMM integration)
- Firewall rules allowing required protocols:
  - LDAP/LDAPS for Active Directory scripts
  - WMI for remote monitoring
  - RPC for various operations

### Knowledge Prerequisites

- Basic PowerShell scripting
- Windows Server administration
- Understanding of monitored systems (AD, DNS, etc.)
- NinjaOne platform familiarity (for integration)

---

## Environment Setup

### 1. Clone the Repository

**Option A: Using Git (Recommended)**

```powershell
# Install Git if not already installed
# Download from: https://git-scm.com/download/win

# Clone repository to your preferred location
cd C:\Scripts
git clone https://github.com/Xore/waf.git
cd waf

# Verify structure
Get-ChildItem
```

**Option B: Download ZIP**

```powershell
# Download from GitHub
# https://github.com/Xore/waf/archive/refs/heads/main.zip

# Extract to C:\Scripts\waf
# Open PowerShell in extracted directory
cd C:\Scripts\waf
```

### 2. Configure Execution Policy

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy (choose based on security requirements)
# Option 1: Allow all local scripts (recommended for testing)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Option 2: Bypass for specific session (temporary)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Option 3: Unblock downloaded scripts
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
```

### 3. Verify PowerShell Version

```powershell
# Check version (should be 5.1 or higher)
$PSVersionTable.PSVersion

# Expected output:
# Major  Minor  Build  Revision
# -----  -----  -----  --------
# 5      1      xxxxx  xxxx
```

---

## Understanding Repository Structure

### Directory Layout

```
waf/
├── plaintext_scripts/    # Main script library (200+ scripts)
│   ├── Active Directory scripts (AD-*.ps1)
│   ├── Network scripts (Network-*.ps1)
│   ├── Hardware monitoring (Hardware-*.ps1)
│   ├── Hyper-V suite (HyperV*.ps1)
│   ├── Server role monitoring (*Monitor*.ps1)
│   └── System operations (various)
│
├── scripts/              # Organized by category
│   └── Security/         # Security-focused scripts
│
├── docs/                 # Documentation
│   ├── standards/        # Coding standards
│   └── GETTING_STARTED.md (this file)
│
├── archive/              # Historical documentation
│
├── README.md             # Project overview
├── CONTRIBUTING.md       # Contribution guidelines
├── CHANGELOG.md          # Version history
└── LICENSE               # MIT License
```

### Script Naming Patterns

**Prefix-Based Organization:**
- `AD-*.ps1` - Active Directory operations
- `Network-*.ps1` - Network management
- `Hardware-*.ps1` - Hardware monitoring
- `HyperV*.ps1` - Hyper-V virtualization
- `IIS-*.ps1` - IIS web server
- `GPO-*.ps1` - Group Policy

**Version Suffixes:**
- `Script_v1.ps1` - First version
- `Script_v2.ps1` - Enhanced version
- `Script_v3.ps1` - Latest version

**Priority Indicators:**
- `P1CriticalDeviceValidator.ps1` - Mission-critical
- `P2HighPriorityValidator.ps1` - High importance
- `P3P4MediumLowValidator.ps1` - Standard devices

---

## First Script Deployment

### Example: System Health Check

Let's deploy a simple monitoring script to verify your setup.

#### Step 1: Review the Script

```powershell
# Open script in editor
code ./plaintext_scripts/HealthScoreCalculator.ps1
# OR
notepad ./plaintext_scripts/HealthScoreCalculator.ps1

# Read the header section:
# - Synopsis: What the script does
# - Parameters: Required inputs
# - Examples: Usage examples
# - Requirements: Dependencies
```

#### Step 2: Test Execution

```powershell
# Run with verbose output
./plaintext_scripts/HealthScoreCalculator.ps1 -Verbose

# Expected output:
VERBOSE: Starting health score calculation...
VERBOSE: Checking CPU usage...
VERBOSE: Checking memory usage...
VERBOSE: Checking disk space...
VERBOSE: Calculating overall health score...

Health Score: 85/100
Status: HEALTHY
```

#### Step 3: Review Results

```powershell
# Scripts typically output to:
# 1. Console (for immediate viewing)
# 2. NinjaOne custom fields (if integrated)
# 3. Event Log (for audit trail)
# 4. Log files (if configured)

# Check Windows Event Log
Get-EventLog -LogName Application -Source "WAF" -Newest 10
```

### Example: Network Monitoring

```powershell
# Test network connectivity
./plaintext_scripts/Network-TestConnectivity.ps1 -Target "google.com" -Verbose

# Check public IP
./plaintext_scripts/Network-GetPublicIP.ps1

# Test DNS resolution
./plaintext_scripts/DNSServerMonitor_v3.ps1 -Verbose
```

---

## NinjaOne Integration

### Prerequisites

1. **NinjaOne Account** - Active tenant with admin access
2. **Agent Installed** - NinjaOne agent on target systems
3. **Custom Fields Created** - Define fields for data collection
4. **Script Categories** - Organize scripts in NinjaOne library

### Setting Up Custom Fields

#### Step 1: Access NinjaOne Administration

1. Log into NinjaOne web portal
2. Navigate to **Administration** → **Devices** → **Custom Fields**
3. Click **Add Custom Field**

#### Step 2: Create Field for Script Output

**Example: Health Score Field**

```
Field Name: health_score
Display Name: System Health Score
Field Type: Number
Category: Monitoring
Description: Overall system health score (0-100)
Technical Name: healthScore
```

**Common Field Patterns:**

```
hw_battery_health     - Hardware: Battery health percentage
sys_uptime_days       - System: Uptime in days
net_public_ip         - Network: Public IP address
ad_replication_status - Active Directory: Replication status
hv_vm_count          - Hyper-V: Virtual machine count
```

#### Step 3: Update Script with Field Reference

```powershell
# In your script, populate custom field:
Ninja-Property-Set healthScore $healthScoreValue

# Example from HealthScoreCalculator.ps1:
$healthScore = 85
Ninja-Property-Set healthScore $healthScore
```

### Deploying Scripts via NinjaOne

#### Step 1: Upload Script

1. Navigate to **Administration** → **Library** → **Automation**
2. Click **Add** → **New Script**
3. Set properties:
   - **Name:** Health Score Calculator
   - **Category:** Monitoring
   - **Script Type:** PowerShell
   - **Language:** PowerShell
4. Paste script content
5. **Save**

#### Step 2: Create Automation Policy

1. Navigate to **Administration** → **Policies**
2. Create new policy or edit existing
3. Add **Automation** → **Scheduled Task**
4. Configure:
   - **Script:** Health Score Calculator
   - **Schedule:** Daily at 2:00 AM
   - **Conditions:** Run on all devices

#### Step 3: Assign to Devices

1. Navigate to **Devices**
2. Select device or organization
3. Assign policy
4. Verify execution in **Activity** log

### Creating Alerts

```powershell
# In NinjaOne, create condition-based alerts
# Example: Alert if health score < 70

Condition:
  Field: health_score
  Operator: Less than
  Value: 70
  
Alert:
  Severity: Warning
  Message: "System health score is low: {health_score}"
  Notify: IT Team
```

---

## Common Scenarios

### Scenario 1: Monitor Active Directory

**Objective:** Monitor domain controller health and replication.

```powershell
# Step 1: Review available AD scripts
Get-ChildItem ./plaintext_scripts -Filter "AD-*.ps1" | Select-Object Name

# Step 2: Test DC health monitoring
./plaintext_scripts/AD-DomainControllerHealthReport.ps1 -Verbose

# Step 3: Check replication status
./plaintext_scripts/AD-ReplicationHealthReport.ps1

# Step 4: Setup scheduled monitoring in NinjaOne
# Upload scripts and schedule daily execution
```

### Scenario 2: Hyper-V Infrastructure

**Objective:** Comprehensive Hyper-V monitoring.

```powershell
# Available Hyper-V scripts (8 in suite)
Get-ChildItem ./plaintext_scripts -Filter "HyperV*.ps1"

# Primary monitoring
./plaintext_scripts/HyperVMonitor.ps1 -Verbose

# Health check
./plaintext_scripts/HyperVHealthCheck.ps1

# Performance metrics
./plaintext_scripts/HyperVPerformanceMonitor.ps1

# Capacity planning
./plaintext_scripts/HyperVCapacityPlanner.ps1

# For multiple hosts
./plaintext_scripts/HyperVMultiHostAggregator.ps1 -Hosts @("HV01", "HV02", "HV03")
```

### Scenario 3: Security Compliance

**Objective:** Audit security posture across estate.

```powershell
# BitLocker status
./plaintext_scripts/BitLockerMonitor_v2.ps1

# Firewall status
./plaintext_scripts/Firewall-AuditStatus2.ps1

# Certificate expiration
./plaintext_scripts/Certificates-GetExpiring.ps1 -DaysWarning 30

# Local administrator drift
./plaintext_scripts/LocalAdmin-Monitor.ps1

# Windows licensing
./plaintext_scripts/Licensing-UnlicensedWindowsAlert.ps1
```

### Scenario 4: Priority-Based Patch Management

**Objective:** Implement phased patching strategy.

```powershell
# Step 1: Validate device priorities
./plaintext_scripts/P1CriticalDeviceValidator.ps1    # Mission-critical
./plaintext_scripts/P2HighPriorityValidator.ps1      # High importance
./plaintext_scripts/P3P4MediumLowValidator.ps1       # Standard devices

# Step 2: Deploy patches by ring
./plaintext_scripts/PR1PatchRing1Deployment.ps1      # Test ring
# Wait 48 hours, validate
./plaintext_scripts/PR2PatchRing2Deployment.ps1      # Production ring
```

---

## Troubleshooting

### Common Issues

#### Issue: Script Won't Execute

**Error:** "Cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set appropriate policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# OR unblock specific script
Unblock-File ./plaintext_scripts/ScriptName.ps1
```

#### Issue: Permission Denied

**Error:** "Access denied" or "Insufficient privileges"

**Solution:**
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → Run as Administrator

# Verify admin privileges
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# Should return: True
```

#### Issue: Module Not Found

**Error:** "The term 'cmdlet-name' is not recognized"

**Solution:**
```powershell
# Check script requirements in header
# Install missing modules

# Example: Active Directory module
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Import module
Import-Module ActiveDirectory

# Verify
Get-Module -ListAvailable
```

#### Issue: NinjaOne Custom Field Not Updating

**Solution:**
```powershell
# Verify NinjaOne agent is running
Get-Service NinjaRMMAgent

# Check agent connectivity
Test-NetConnection -ComputerName ninjarmm.com -Port 443

# Verify custom field exists in NinjaOne portal
# Check field technical name matches script

# Test field update manually
Ninja-Property-Set testField "test value"
```

### Debugging Scripts

```powershell
# Enable verbose output
./script.ps1 -Verbose

# Enable debug output
./script.ps1 -Debug

# Capture full output
./script.ps1 -Verbose *> C:\Temp\script-output.txt

# Review error details
$Error[0] | Format-List * -Force
```

### Getting Help

```powershell
# View script help
Get-Help ./script.ps1 -Full

# View examples
Get-Help ./script.ps1 -Examples

# View parameters
Get-Help ./script.ps1 -Parameter *
```

---

## Next Steps

### Expand Your Deployment

1. **Review Script Catalog**
   - Browse `/plaintext_scripts/` for relevant scripts
   - Read script headers for functionality
   - Test in lab environment first

2. **Create Monitoring Baseline**
   - Deploy health check scripts
   - Establish custom fields
   - Configure alerting thresholds

3. **Implement Automation**
   - Schedule regular script execution
   - Set up automated remediation
   - Create reporting dashboards

### Dive Deeper

- **[Coding Standards](/docs/standards/CODING_STANDARDS.md)** - Understand V3 framework
- **[Script Refactoring Guide](/docs/standards/SCRIPT_REFACTORING_GUIDE.md)** - Customize scripts
- **[Contributing Guidelines](/CONTRIBUTING.md)** - Contribute improvements

### Community

- **[GitHub Issues](https://github.com/Xore/waf/issues)** - Report bugs or request features
- **[GitHub Discussions](https://github.com/Xore/waf/discussions)** - Ask questions
- **Pull Requests** - Submit improvements

---

## Quick Reference

### Essential Commands

```powershell
# Navigate to script directory
cd C:\Scripts\waf\plaintext_scripts

# List all scripts
Get-ChildItem -Filter *.ps1

# Search for specific functionality
Get-ChildItem -Filter "*Monitor*.ps1"

# View script help
Get-Help ./ScriptName.ps1 -Full

# Execute script
./ScriptName.ps1 -Parameter Value -Verbose

# Update repository (if using Git)
git pull origin main
```

### Script Patterns

| Pattern | Purpose |
|---------|----------|
| `*Monitor*.ps1` | Monitoring and health checks |
| `AD-*.ps1` | Active Directory operations |
| `Network-*.ps1` | Network management |
| `Hardware-*.ps1` | Hardware monitoring |
| `HyperV*.ps1` | Hyper-V virtualization |
| `P1*.ps1` | Priority 1 (critical) devices |
| `PR1*.ps1` | Patch Ring 1 (test) |

---

**Questions?** Check the [documentation](/docs/) or create an [issue](https://github.com/Xore/waf/issues).

**Ready to contribute?** Read [CONTRIBUTING.md](/CONTRIBUTING.md) to get started.
