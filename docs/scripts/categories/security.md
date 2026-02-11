# Security & Compliance Monitoring

**Complete guide to security and compliance scripts in the WAF framework.**

---

## Overview

The WAF Security & Compliance suite provides 15+ scripts for endpoint protection, threat detection, compliance validation, and security posture monitoring. Designed for security-conscious environments with regulatory requirements and zero-trust principles.

### Script Categories

| Category | Script Count | Primary Focus |
|----------|--------------|---------------|
| Encryption & Protection | 2 | BitLocker monitoring |
| Certificate Management | 2 | SSL/TLS lifecycle |
| Firewall & Network Security | 2 | Windows Firewall audit |
| Threat Detection | 3 | EDR-style monitoring |
| Compliance | 4 | Regulatory compliance |

**Total:** 15+ scripts | **Complexity:** Intermediate to Advanced

---

## Quick Start

### Prerequisites

**System Requirements:**
- Windows 10/11 or Server 2016+
- PowerShell 5.1 or later
- Administrator privileges
- Security audit rights
- NinjaOne agent (for RMM integration)

**Permissions Required:**
- Local Administrator
- Security Log read access
- TPM management (for BitLocker)
- Certificate store access

### First Deployment

```powershell
# Check BitLocker status
.\BitLockerMonitor_v2.ps1

# Audit firewall status
.\Firewall-AuditStatus2.ps1

# Check certificate expiration
.\Certificates-GetExpiring.ps1 -DaysWarning 30
```

---

## Encryption & Protection

### BitLockerMonitor_v1.ps1 & BitLockerMonitor_v2.ps1

**Purpose:** Monitor BitLocker encryption status across endpoints.

**Key Features:**
- Drive encryption status
- Protection method verification
- Key escrow validation
- TPM status checking
- Encryption percentage tracking
- Recovery key backup status

**Version Differences:**

| Feature | v1 | v2 |
|---------|----|----||
| Basic encryption status | ✅ | ✅ |
| TPM validation | ❌ | ✅ |
| Key escrow check | ❌ | ✅ |
| Detailed diagnostics | ❌ | ✅ |
| Performance impact | Lower | Slightly higher |

**Encryption States:**
```powershell
FullyEncrypted      # All volumes encrypted
FullyDecrypted      # No encryption
EncryptionInProgress # Currently encrypting
DecryptionInProgress # Currently decrypting
EncryptionPaused    # Encryption paused
EncryptionSuspended # Encryption suspended
```

**NinjaOne Custom Fields:**
```powershell
bitlocker_status            # Overall status
bitlocker_encrypted_volumes # Count of encrypted volumes
bitlocker_total_volumes     # Total volumes
bitlocker_tpm_present       # TPM chip present
bitlocker_tpm_enabled       # TPM enabled
bitlocker_recovery_key      # Recovery key backed up
bitlocker_protection_method # Protection method (TPM, Password, etc.)
```

**Usage (v2 - Recommended):**

```powershell
# Basic status check
.\BitLockerMonitor_v2.ps1

# Detailed report with TPM info
.\BitLockerMonitor_v2.ps1 -Detailed

# Check specific volume
.\BitLockerMonitor_v2.ps1 -Volume "C:"

# Verify recovery key backup
.\BitLockerMonitor_v2.ps1 -ValidateRecoveryKey
```

**Output Example:**
```
=== BitLocker Status Report ===
Computer: LAPTOP-001
TPM Present: Yes (Version 2.0)
TPM Enabled: Yes

Volume: C:\ (OS)
  Status: FullyEncrypted
  Method: TPM + PIN
  Strength: AES-256
  Encryption: 100%
  Recovery Key: Backed up to AD ✅

Volume: D:\ (Data)
  Status: FullyEncrypted
  Method: TPM
  Strength: AES-256
  Encryption: 100%
  Recovery Key: Backed up to AD ✅

OVERALL STATUS: COMPLIANT ✅
```

**Alert Conditions:**
- Volume not encrypted: CRITICAL
- Encryption in progress > 24h: WARNING
- TPM not enabled: WARNING
- Recovery key not backed up: CRITICAL
- Weak encryption (AES-128): WARNING

**Compliance Checks:**
```powershell
# NIST 800-171 compliance
- All removable drives encrypted: Required
- TPM protection: Required
- Recovery key escrow: Required

# HIPAA compliance
- Full disk encryption: Required
- AES-256: Required
- Key management: Required

# PCI-DSS compliance
- Cardholder data encrypted: Required
- Strong cryptography: Required
```

---

## Certificate Management

### Certificates-GetExpiring.ps1

**Purpose:** Monitor SSL/TLS certificate expiration across infrastructure.

**Key Features:**
- Local certificate store scanning
- Remote server certificate checking
- Multiple store support (Personal, Web Hosting, etc.)
- Expiration threshold configuration
- Self-signed certificate detection
- Certificate chain validation

**Certificate Stores Scanned:**
```powershell
Cert:\LocalMachine\My              # Personal certificates
Cert:\LocalMachine\WebHosting      # IIS certificates
Cert:\LocalMachine\Root            # Trusted root CAs
Cert:\CurrentUser\My               # User certificates
```

**Usage:**

```powershell
# Find certificates expiring in 30 days
.\Certificates-GetExpiring.ps1 -DaysWarning 30

# Check specific store
.\Certificates-GetExpiring.ps1 -Store "My" -DaysWarning 60

# Check remote server
.\Certificates-GetExpiring.ps1 -ComputerName "webserver.contoso.com" -Port 443

# Export to CSV
.\Certificates-GetExpiring.ps1 -DaysWarning 90 -ExportCSV -Path "C:\Reports"

# Include expired certificates
.\Certificates-GetExpiring.ps1 -IncludeExpired
```

**NinjaOne Fields:**
```powershell
cert_expiring_30days        # Count expiring within 30 days
cert_expiring_60days        # Count expiring within 60 days
cert_expired                # Count already expired
cert_self_signed            # Count of self-signed certs
cert_next_expiration        # Date of next expiring cert
```

**Output Example:**
```
=== Certificate Expiration Report ===
Computer: WEB-SERVER-01
Scan Date: 2026-02-11 20:54:00

Expiring Certificates (30 days):

⚠️  URGENT (< 7 days):
  Subject: www.contoso.com
  Issuer: Let's Encrypt
  Expires: 2026-02-15 (4 days)
  Store: WebHosting
  Thumbprint: 1A2B3C4D...

⚠️  WARNING (< 30 days):
  Subject: mail.contoso.com
  Issuer: DigiCert
  Expires: 2026-03-05 (22 days)
  Store: My
  Thumbprint: 5E6F7G8H...

Total Certificates: 15
Expiring Soon: 2
Expired: 0

RECOMMENDATIONS:
1. Renew www.contoso.com immediately
2. Schedule renewal for mail.contoso.com
```

---

### Certificates-LocalExpirationAlert.ps1

**Purpose:** Proactive alerting for certificate expiration.

**Features:**
- Email notifications
- Slack/Teams integration
- Escalation based on days remaining
- Auto-renewal trigger (if supported)

**Usage:**

```powershell
# Send email alerts
.\Certificates-LocalExpirationAlert.ps1 -SMTPServer "mail.company.com" -To "it@company.com"

# Multiple alert thresholds
.\Certificates-LocalExpirationAlert.ps1 -CriticalDays 7 -WarningDays 30 -InfoDays 60

# Integrate with Teams
.\Certificates-LocalExpirationAlert.ps1 -TeamsWebhook "https://outlook.office.com/webhook/..."
```

**Alert Escalation:**
```
> 60 days: INFO (monthly notification)
30-60 days: WARNING (weekly notification)
7-30 days: WARNING (daily notification)
< 7 days: CRITICAL (hourly notification)
Expired: CRITICAL (immediate notification)
```

---

## Firewall & Network Security

### Firewall-AuditStatus.ps1 & Firewall-AuditStatus2.ps1

**Purpose:** Windows Firewall configuration audit and compliance validation.

**Key Features:**
- Firewall profile status (Domain, Private, Public)
- Rule count and analysis
- Unauthorized rule detection
- Port exposure audit
- Logging configuration
- Exception policy validation

**Firewall Profiles:**
```powershell
Domain Profile   # On domain networks
Private Profile  # On private networks  
Public Profile   # On public networks
```

**Security Checks:**
1. **Profile Status**
   - Firewall enabled on all profiles
   - Inbound connections blocked by default
   - Outbound connections allowed (with logging)

2. **Rule Analysis**
   - Total rules count
   - Enabled vs disabled rules
   - Allow vs block rules
   - Dangerous rules (Any/Any/Any)

3. **Port Exposure**
   - Open ports inventory
   - Unnecessary services exposed
   - Remote management ports (3389, 5985)

4. **Logging Configuration**
   - Dropped packets logged
   - Successful connections logged
   - Log file location and size

**NinjaOne Fields:**
```powershell
fw_domain_enabled           # Domain profile enabled
fw_private_enabled          # Private profile enabled
fw_public_enabled           # Public profile enabled
fw_total_rules              # Total firewall rules
fw_enabled_rules            # Enabled rules
fw_dangerous_rules          # Risky rules count
fw_open_ports               # Open ports list
fw_logging_enabled          # Logging configured
```

**Usage (v2 - Enhanced):**

```powershell
# Basic firewall audit
.\Firewall-AuditStatus2.ps1

# Detailed rule analysis
.\Firewall-AuditStatus2.ps1 -DetailedRules

# Find dangerous rules
.\Firewall-AuditStatus2.ps1 -FindDangerousRules

# Export audit report
.\Firewall-AuditStatus2.ps1 -ExportReport -Path "C:\Reports"

# Compliance check
.\Firewall-AuditStatus2.ps1 -ComplianceMode -Standard "CIS"
```

**Output Example:**
```
=== Windows Firewall Audit ===
Computer: SERVER-01
Audit Date: 2026-02-11

Profile Status:
  Domain:  ✅ Enabled (Default: Block Inbound)
  Private: ✅ Enabled (Default: Block Inbound)
  Public:  ✅ Enabled (Default: Block Inbound)

Firewall Rules:
  Total Rules: 245
  Enabled: 187
  Disabled: 58
  Allow Rules: 165
  Block Rules: 22

⚠️  Dangerous Rules Found: 3
  1. "Allow All Traffic" (Any/Any/Any) - DISABLE IMMEDIATELY
  2. "RDP from Any" (TCP/3389/0.0.0.0/0) - RESTRICT SOURCE
  3. "SMB External" (TCP/445/0.0.0.0/0) - CRITICAL RISK

Open Ports (Inbound):
  TCP 80, 443 (HTTP/HTTPS) - Web Server ✅
  TCP 3389 (RDP) - From ANY ⚠️
  TCP 5985 (WinRM) - From 10.0.0.0/8 ✅
  UDP 161 (SNMP) - From monitoring server ✅

Logging:
  Dropped Packets: ✅ Enabled
  Successful Connections: ❌ Disabled
  Log Location: C:\Windows\System32\LogFiles\Firewall

COMPLIANCE STATUS: FAILED ❌
ISSUES TO REMEDIATE: 3 critical

RECOMMENDATIONS:
1. Disable "Allow All Traffic" rule immediately
2. Restrict RDP access to management subnet
3. Block SMB (445) from external networks
4. Enable logging for successful connections
```

**Compliance Standards:**
```powershell
# CIS Benchmark
- Firewall enabled: All profiles
- Default inbound: Block
- Logging enabled: Required
- Remote admin ports: Restricted

# NIST 800-53
- SC-7: Boundary protection
- AC-4: Information flow enforcement
- AU-2: Audit events logging
```

---

## Threat Detection

### AdvancedThreatTelemetry.ps1

**Purpose:** Advanced threat detection metrics and behavioral analysis.

**Monitored Indicators:**
- Suspicious process creation
- Unusual network connections
- Registry modification patterns
- File system anomalies
- PowerShell execution tracking
- Privilege escalation attempts

**Detection Categories:**

1. **Process Anomalies**
   - Unsigned executables
   - Processes running from temp directories
   - Parent-child process mismatches
   - Injection techniques

2. **Network Indicators**
   - Connections to known bad IPs
   - Unusual ports
   - High-frequency beaconing
   - Data exfiltration patterns

3. **Persistence Mechanisms**
   - Startup folder modifications
   - Registry Run keys
   - Scheduled tasks
   - WMI subscriptions

4. **Credential Access**
   - LSASS memory access
   - SAM database access
   - Credential dumping tools

**Usage:**

```powershell
# Collect threat telemetry
.\AdvancedThreatTelemetry.ps1

# Real-time monitoring (5-minute intervals)
.\AdvancedThreatTelemetry.ps1 -RealTime -Interval 300

# High-sensitivity mode
.\AdvancedThreatTelemetry.ps1 -Sensitivity High
```

**NinjaOne Fields:**
```powershell
threat_risk_score           # Overall risk (0-100)
threat_indicators           # Active threat indicators
threat_suspicious_processes # Suspicious process count
threat_network_anomalies    # Network anomaly count
threat_last_detection       # Last threat detection time
```

---

### EndpointDetectionResponse.ps1

**Purpose:** EDR-style endpoint monitoring and response.

**Response Actions:**
- Process termination
- Network isolation
- File quarantine
- User notification
- Evidence collection

**Usage:**

```powershell
# Monitor only (no automated response)
.\EndpointDetectionResponse.ps1 -MonitorOnly

# Automated response enabled
.\EndpointDetectionResponse.ps1 -AutoRespond -Sensitivity Medium

# Collect forensic evidence
.\EndpointDetectionResponse.ps1 -CollectEvidence -OutputPath "C:\Evidence"
```

---

### SecuritySurfaceTelemetry.ps1

**Purpose:** Security posture measurement and attack surface analysis.

**Metrics Collected:**
- Open ports and services
- Outdated software
- Missing security patches
- Weak configurations
- Exposed credentials
- Attack surface score (0-100)

**Usage:**

```powershell
# Calculate attack surface
.\SecuritySurfaceTelemetry.ps1

# Detailed analysis
.\SecuritySurfaceTelemetry.ps1 -DetailedReport

# Compare against baseline
.\SecuritySurfaceTelemetry.ps1 -BaselineComparison
```

**NinjaOne Fields:**
```powershell
sec_attack_surface_score    # Attack surface (lower=better)
sec_open_services           # Exposed services count
sec_outdated_software       # Outdated software count
sec_missing_patches         # Missing critical patches
sec_posture_grade           # A-F grade
```

---

## Compliance

### ComplianceAttestationReporter.ps1

**Purpose:** Automated compliance reporting and attestation.

**Supported Standards:**
- NIST 800-53
- CIS Benchmarks
- PCI-DSS
- HIPAA
- GDPR (technical controls)
- SOC 2

**Compliance Checks:**
```powershell
# Security Configuration
- Password policy compliance
- Account lockout settings
- Audit policy configuration
- User rights assignment

# Encryption
- BitLocker enabled
- TLS 1.2+ enforced
- Certificate management

# Access Control
- Administrative account usage
- Privilege escalation monitoring
- MFA enforcement

# Logging & Monitoring
- Security event logging
- Log retention
- SIEM integration
```

**Usage:**

```powershell
# Generate compliance report
.\ComplianceAttestationReporter.ps1 -Standard "NIST-800-53"

# Multiple standards
.\ComplianceAttestationReporter.ps1 -Standards @("CIS", "PCI-DSS")

# Export attestation document
.\ComplianceAttestationReporter.ps1 -Standard "HIPAA" -ExportAttestation
```

**Output:**
```
=== Compliance Report: NIST 800-53 ===
Organization: Contoso Corp
Assessment Date: 2026-02-11
System: SERVER-01

Control Family: Access Control (AC)
  AC-2 (Account Management): ✅ COMPLIANT
  AC-3 (Access Enforcement): ✅ COMPLIANT
  AC-7 (Unsuccessful Logon Attempts): ⚠️ PARTIAL
  AC-17 (Remote Access): ✅ COMPLIANT

Control Family: Identification and Authentication (IA)
  IA-2 (User Identification): ✅ COMPLIANT
  IA-5 (Authenticator Management): ✅ COMPLIANT

Control Family: System and Communications Protection (SC)
  SC-7 (Boundary Protection): ⚠️ PARTIAL
  SC-8 (Transmission Confidentiality): ✅ COMPLIANT
  SC-13 (Cryptographic Protection): ✅ COMPLIANT

OVERALL COMPLIANCE: 85% (17/20 controls)

NON-COMPLIANT ITEMS:
  - AC-7: Account lockout threshold set to 10 (required: 5)
  - SC-7: Firewall rules contain Any/Any/Any rules
  - AU-4: Log storage capacity < 30 days

REMEDIATION REQUIRED: 3 items
```

---

### Entra-Audit.ps1

**Purpose:** Microsoft Entra ID (Azure AD) audit logging and monitoring.

**Usage:**

```powershell
# Audit Entra ID
.\Entra-Audit.ps1 -TenantId "xxx-xxx-xxx"
```

---

### Licensing-UnlicensedWindowsAlert.ps1

**Purpose:** Windows licensing compliance monitoring.

**Checks:**
- Activation status
- License type
- Grace period
- KMS connectivity
- MAK/Retail license validation

**Usage:**

```powershell
# Check licensing
.\Licensing-UnlicensedWindowsAlert.ps1

# Alert if unlicensed
.\Licensing-UnlicensedWindowsAlert.ps1 -AlertIfUnlicensed
```

**NinjaOne Fields:**
```powershell
license_status              # Activated/Unlicensed/Grace
license_type                # Volume/OEM/Retail
license_grace_remaining     # Days remaining in grace
```

---

## Deployment Scenarios

### Scenario 1: Basic Security Posture

**Schedule:**
```powershell
# Daily
.\BitLockerMonitor_v2.ps1
.\Firewall-AuditStatus2.ps1
.\Certificates-GetExpiring.ps1 -DaysWarning 30

# Weekly
.\SecuritySurfaceTelemetry.ps1
.\ComplianceAttestationReporter.ps1 -Standard "CIS"
```

---

### Scenario 2: High-Security Environment

**Schedule:**
```powershell
# Every 15 minutes
.\AdvancedThreatTelemetry.ps1
.\EndpointDetectionResponse.ps1 -AutoRespond

# Every 4 hours
.\Firewall-AuditStatus2.ps1 -FindDangerousRules

# Daily
.\BitLockerMonitor_v2.ps1 -ValidateRecoveryKey
.\Certificates-LocalExpirationAlert.ps1
```

---

## Best Practices

### Security Monitoring Frequency

| Script | Recommended Interval | Criticality |
|--------|---------------------|-------------|
| BitLockerMonitor | Daily | High |
| Firewall-AuditStatus | Every 4 hours | High |
| AdvancedThreatTelemetry | 15 minutes | Critical |
| Certificates-GetExpiring | Daily | Medium |
| SecuritySurfaceTelemetry | Weekly | Medium |

### Alert Thresholds

```powershell
# BitLocker
- Unencrypted volume: CRITICAL (immediate)
- No recovery key: CRITICAL (immediate)
- TPM disabled: WARNING (daily)

# Certificates
- Expires < 7 days: CRITICAL (hourly)
- Expires < 30 days: WARNING (daily)
- Self-signed: INFO (weekly)

# Firewall
- Disabled profile: CRITICAL (immediate)
- Dangerous rule: CRITICAL (immediate)
- Open RDP: WARNING (daily)
```

---

## Related Documentation

- **[Script Catalog](/docs/scripts/SCRIPT_CATALOG.md)** - Complete script listing
- **[Getting Started](/docs/GETTING_STARTED.md)** - Setup guide
- **[Compliance Guide](/docs/reference/COMPLIANCE_STANDARDS.md)** - Detailed compliance mapping

---

**Last Updated:** 2026-02-11  
**Scripts:** 15+  
**Complexity:** Intermediate to Advanced  
**Focus:** Endpoint Security & Compliance
