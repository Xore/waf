# Script 02: OPS Stability Analyzer

**File:** Script_02_OPS_Stability_Analyzer.md  
**Version:** v1.0  
**Script Number:** 02  
**Category:** Core Monitoring - OPS Scores  
**Last Updated:** February 2, 2026

---

## Purpose

Calculate system and application stability score based on crashes and failures.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~10 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Reads **Windows Event Log** (native) for service failures
- Combines with custom crash counts ([STATAppCrashes24h](../core/11_STAT_Core_Telemetry.md), [STATBSODCount30d](../core/11_STAT_Core_Telemetry.md))

---

## Fields Updated

- [OPSStabilityScore](../core/10_OPS_Core_Operational_Scores.md) (Integer 0-100)
- [OPSLastScoreUpdate](../core/10_OPS_Core_Operational_Scores.md) (DateTime)

---

## Scoring Logic

```text
Base Score: 100

Deductions:
  - Each application crash (24h): -2 points
  - Each application hang (24h): -1.5 points
  - Each service failure: -3 points
  - Each BSOD (30d): -20 points
  - Uptime < 24h with crashes: -10 points

Minimum Score: 0
```

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Stability Analyzer (v1.0 Native-Enhanced)"

    # Initialize base score
    $stabilityScore = 100

    # Query custom telemetry
    $crashes = Ninja-Property-Get STATAppCrashes24h
    if ([string]::IsNullOrEmpty($crashes)) { $crashes = 0 }

    $hangs = Ninja-Property-Get STATAppHangs24h
    if ([string]::IsNullOrEmpty($hangs)) { $hangs = 0 }

    $serviceFailures = Ninja-Property-Get STATServiceFailures24h
    if ([string]::IsNullOrEmpty($serviceFailures)) { $serviceFailures = 0 }

    $bsodCount = Ninja-Property-Get STATBSODCount30d
    if ([string]::IsNullOrEmpty($bsodCount)) { $bsodCount = 0 }

    $uptimeDays = Ninja-Property-Get STATUptimeDays
    if ([string]::IsNullOrEmpty($uptimeDays)) { $uptimeDays = 0 }

    # Calculate deductions
    $stabilityScore -= ($crashes * 2)
    $stabilityScore -= ($hangs * 1.5)
    $stabilityScore -= ($serviceFailures * 3)
    $stabilityScore -= ($bsodCount * 20)

    # Uptime penalty if crashes detected
    if ($uptimeDays -lt 1 -and $crashes -gt 0) {
        $stabilityScore -= 10
    }

    # Ensure score stays within bounds
    if ($stabilityScore -lt 0) { $stabilityScore = 0 }
    if ($stabilityScore -gt 100) { $stabilityScore = 100 }

    # Update fields
    Ninja-Property-Set OPSStabilityScore $stabilityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Stability Score = $stabilityScore"
    Write-Output "  Crashes (24h): $crashes"
    Write-Output "  Hangs (24h): $hangs"
    Write-Output "  Service Failures (24h): $serviceFailures"
    Write-Output "  BSODs (30d): $bsodCount"
    Write-Output "  Uptime (days): $uptimeDays"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [OPS Custom Fields](../core/10_OPS_Core_Operational_Scores.md)
- [STAT Telemetry Fields](../core/11_STAT_Core_Telemetry.md)
- [Script 01: Health Score Calculator](Script_01_OPS_Health_Score_Calculator.md)
- [Script 06: Telemetry Collector](Script_06_STAT_Telemetry_Collector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_02_OPS_Stability_Analyzer.md  
**Version:** v1.0  
**Status:** Production Ready
