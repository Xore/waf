# V3 Migration Tracking - Scripts Requiring Migration

This document tracks the migration status of scripts that were moved into the `plaintext_scripts` folder and need V3 migration to use NinjaRMM custom fields and WAF framework.

## Migration Status

**Total Scripts to Migrate:** 76
**Files Renamed:** Complete (commit 1c4223f2)
**Migrated to V3:** 9
**In Progress:** 0
**Remaining:** 67
**Progress:** 11.8%

---

## Scripts Ready for V3 Migration

### High Priority - Security & Critical Monitoring (14 scripts)

1. [x] **SecurityAnalyzer.ps1** - Core security analysis (Migrated: commit 75f7316d)
2. [x] **SecurityPostureConsolidator.ps1** - Security aggregation (Migrated: commit ad9f58b9)
3. [x] **SuspiciousLoginPatternDetector.ps1** - Behavioral analytics (Migrated: commit 177e65ea)
4. [x] **SecuritySurfaceTelemetry.ps1** - Attack surface (Migrated: commit 08b767d9)
5. [x] **AdvancedThreatTelemetry.ps1** - Threat detection (Migrated: commit 647d9acb)
6. [x] **EndpointDetectionResponse.ps1** - EDR monitoring (Migrated: commit dc7caa44)
7. [x] **ComplianceAttestationReporter.ps1** - Compliance (Migrated: commit 65c4121a)
8. [x] **P1CriticalDeviceValidator.ps1** - P1 validation (Migrated: commit 7a93d8d4)
9. [x] **P2HighPriorityValidator.ps1** - P2 validation (Migrated: commit 0253c92e)
10. [ ] **P3P4MediumLowValidator.ps1** - P3/P4 validation
11. [ ] **PR1PatchRing1Deployment.ps1** - Patch ring 1
12. [ ] **PR2PatchRing2Deployment.ps1** - Patch ring 2
13. [ ] **HealthScoreCalculator.ps1** - Health scoring
14. [ ] **StabilityAnalyzer.ps1** - Stability analysis

---

## Completed Migrations

### Sprint 1: Security Scripts (COMPLETE - 7/7)
1-7. Security monitoring suite (see previous commits)

### Sprint 2: Priority Validators (IN PROGRESS - 2/7)

8. **P1CriticalDeviceValidator.ps1** - Migrated 2026-02-11
   - Location: `scripts/Validation/P1CriticalDeviceValidator.ps1`
   - Commit: [7a93d8d4](https://github.com/Xore/waf/commit/7a93d8d46cd704a41e8ab1b0151836fea6e48919)
   - Thresholds: Health 80+, Stability 80+, Backup 24h, Disk 15GB, Crashes <=2
   - Validates: P1 critical devices before patch deployment

9. **P2HighPriorityValidator.ps1** - Migrated 2026-02-11
   - Location: `scripts/Validation/P2HighPriorityValidator.ps1`
   - Commit: [0253c92e](https://github.com/Xore/waf/commit/0253c92e08314894e4e425235e989d4dacfd2cc5)
   - Thresholds: Health 70+, Stability 70+, Backup 72h, Disk 10GB, Crashes <=5
   - Validates: P2 high priority devices with balanced standards

---

## Progress Tracking

### Sprint 1: Security Scripts (COMPLETE - 7/7)
- [x] All security monitoring scripts complete

### Sprint 2: Priority Validators & Health (IN PROGRESS - 2/7)
- [x] P1CriticalDeviceValidator.ps1
- [x] P2HighPriorityValidator.ps1
- [ ] P3P4MediumLowValidator.ps1 (next)
- [ ] PR1PatchRing1Deployment.ps1
- [ ] PR2PatchRing2Deployment.ps1
- [ ] HealthScoreCalculator.ps1
- [ ] StabilityAnalyzer.ps1

---

## Reference

- **Scripts location:** `plaintext_scripts/` (source), `scripts/` (migrated)
- **Total scripts:** 76
- **V3 Standard Version:** 3.0.0
