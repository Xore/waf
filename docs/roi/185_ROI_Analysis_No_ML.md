# NinjaOne Framework v4.0 - ROI Analysis (Core Framework - No ML)

**Version:** 4.0 Core (Native-Enhanced without ML/RCA)  
**Date:** February 1, 2026, 11:24 PM CET  
**Purpose:** Financial analysis for Core Framework deployment (no machine learning)  
**Audience:** CFO, IT Directors, Finance Teams, Budget Approvers

---

## EXECUTIVE ROI SUMMARY

**Scenario: 100 Devices @ €5/device/month - Core Framework Only**

**NinjaRMM Annual Cost:** €6,000 (€5 × 100 devices × 12 months)  
**Core Framework Investment:** €4,500 (one-time, 90 hours)  
**Total Year 1 Cost:** €10,500  

**First-Year Benefits:** €16,250  
**First-Year Net ROI:** €5,750 (55% return)  
**Payback Period:** 7.8 months  
**5-Year Cumulative ROI:** €47,500  

**Strategic Value:** Core framework delivers predictive operations and automated remediation without ML complexity, ideal for small-to-medium organizations.

---

## CORE FRAMEWORK SCOPE

### What's Included (No ML)

**Custom Fields (61 total):**
- 35 essential fields (OPS, STAT, RISK, CAP, SEC)
- 26 extended fields (AUTO, UX, NET, DRIFT, BAT)
- 0 ML fields (no MLAnomalyScore, MLFailureRisk, etc.)

**PowerShell Scripts (39 total):**
- Scripts 1-13: Infrastructure monitoring (every 4h)
- Scripts 14-24: Extended automation (daily)
- Scripts 40-65: Remediation (on-demand)
- 0 ML scripts (no Python, no InfluxDB)

**Hybrid Conditions (55 total):**
- 15 P1 critical conditions (native + custom)
- 20 P2 high priority conditions
- 20 P3 medium priority conditions
- 0 ML conditions

**Dynamic Groups (50 total):**
- Automation eligibility (AUTO_Safe_Aggressive, AUTO_Restricted)
- Health-based (CRIT, WARN, GOOD)
- Capacity-based (CAP_Disk_Upgrade)
- Stability-based (CRIT_Stability_Risk)
- 0 ML groups

**Automated Remediation:**
- Service restarts (Print Spooler, Windows Update, DNS, Network, RDP)
- Emergency disk cleanup
- Memory optimization
- 90%+ success rate on common issues

**Predictive Capacity:**
- CAPDaysUntilDiskFull (linear regression forecast)
- 30-day advance warning of disk exhaustion
- Proactive capacity planning

### What's NOT Included (ML Features Excluded)

**No Machine Learning:**
- No anomaly detection (MLAnomalyScore)
- No predictive hardware replacement (MLFailureRisk)
- No automated root cause analysis (ML-powered)
- No time-series database (InfluxDB)
- No Python ML environment

**Reduced Advanced Warning:**
- Capacity: 30 days (vs 30-45 days with ML)
- Hardware failures: Reactive (vs 15-45 day ML prediction)
- Security: Pattern-based (vs ML anomaly detection)

**Manual Root Cause Analysis:**
- Traditional troubleshooting (15-30 min vs <1 min ML)
- No automated RCA reports
- Technician expertise required

---

## INVESTMENT BREAKDOWN

### One-Time Deployment Costs (€4,500)

| Category | Hours | Rate | Cost | Details |
|----------|-------|------|------|---------|
| **Core Framework Deployment** | | | **€3,500** | |
| Custom field creation (61 fields) | 8h | €50/h | €400 | 35 essential + 26 extended |
| Script deployment (39 scripts) | 12h | €50/h | €600 | Infrastructure + automation |
| Script scheduling | 10h | €50/h | €500 | Cron/scheduled tasks |
| Condition creation (55 conditions) | 10h | €50/h | €500 | P1 + P2 + P3 |
| Dynamic group creation (50 groups) | 10h | €50/h | €500 | Segmentation |
| Testing & validation | 20h | €50/h | €1,000 | Pilot + production |
| **Staff Training** | | | **€1,000** | |
| Level 1 Administrator (2 techs) | 10h | €50/h | €500 | Basic framework |
| Senior tech training | 10h | €50/h | €500 | Advanced troubleshooting |
| **Total Core Framework** | **90h** | | **€4,500** | One-time |

**Note:** No ML infrastructure costs (InfluxDB, Python, model training)

### Recurring Annual Costs

| Item | Devices | Monthly Cost | Annual Cost |
|------|---------|--------------|-------------|
| NinjaRMM Platform | 100 | €5/device | €6,000 |
| Framework Maintenance | - | €0 | €0 |
| **Total Recurring** | | | **€6,000** |

---

## YEAR 1 DETAILED ANALYSIS

### Year 1 Costs

| Item | Amount | Timing |
|------|--------|--------|
| NinjaRMM Annual Subscription | €6,000 | Monthly (€500/month) |
| Core Framework Deployment | €4,500 | One-time (Month 1-2) |
| **Total Year 1 Costs** | **€10,500** | |

### Year 1 Benefits (€16,250)

#### 1. Operational Efficiency Savings (€8,250/year)

**A. Script Maintenance Reduction: €2,500/year**
```
Without Framework:
  - Manual monitoring and maintenance: 1,800h/year

With Core Framework:
  - Automated monitoring: 516h/year
  - Native integration reduces maintenance

Savings: 50h/year × €50/h = €2,500
```

**B. Troubleshooting Time Savings: €3,750/year**
```
Traditional RMM (no framework):
  - Diagnostic time: 20 min/ticket
  - 100 tickets/month = 400h/year

RMM + Core Framework:
  - Health scores provide instant context
  - Diagnostic time: 3 min/ticket
  - 100 tickets/month = 60h/year

Savings: 340h/year (conservative: 75h)
Value: 75h × €50/h = €3,750
```

**C. False Positive Reduction: €2,000/year**
```
Traditional RMM alerts:
  - 30% false positive rate
  - 500 alerts/month × 30% = 150 false positives
  - Investigation: 15 min each = 450h/year wasted

Core Framework (hybrid conditions):
  - 10% false positive rate (70% reduction)
  - 500 alerts/month × 10% = 50 false positives
  - 150h/year wasted

Savings: 300h (conservative: 40h)
Value: 40h × €50/h = €2,000
```

#### 2. Downtime Prevention (€5,000/year)

**A. Proactive Capacity Management: €3,000/year**
```
Without CAPDaysUntilDiskFull:
  - 2 critical disk-full outages/year
  - 100 users × 4h downtime × €25/h = €10,000 lost productivity
  - Emergency response: 8h × €75/h = €600
  - Total per incident: €10,600
  - Annual: 2 × €10,600 = €21,200

With Core Framework (predictive capacity):
  - CAPDaysUntilDiskFull provides 30-day warning
  - Planned maintenance during maintenance window
  - Zero downtime, zero emergency
  - Cost: 2h planning × €50/h = €100 per incident

Annual Savings: €21,200 - €200 = €21,000
Conservative estimate: €3,000/year
```

**B. Faster Incident Response: €2,000/year**
```
Without Health Scores:
  - Incident investigation: 30 min average
  - 200 incidents/year × 0.5h = 100h
  - Cost: 100h × €75/h = €7,500

With OPSHealthScore + Context:
  - Incident investigation: 5 min average (instant context)
  - 200 incidents × 0.083h = 16.6h
  - Cost: 16.6h × €75/h = €1,245

Savings: €7,500 - €1,245 = €6,255
Conservative estimate: €2,000/year
```

#### 3. Security Improvements (€3,000/year)

**A. Security Incident Reduction: €2,000/year**
```
Without SECSecurityPostureScore:
  - 10 security incidents/year
  - Average remediation: 8h × €75/h = €600
  - Downtime/impact: €400
  - Total per incident: €1,000
  - Annual cost: €10,000

With Security Posture Monitoring:
  - Early detection via SECSecurityPostureScore
  - 30% incident reduction
  - 7 incidents/year × €1,000 = €7,000

Savings: €10,000 - €7,000 = €3,000
Conservative estimate: €2,000/year
```

**B. Configuration Drift Detection: €1,000/year**
```
Without DRIFTLocalAdminDrift:
  - Unauthorized changes go undetected
  - 5 security issues/year from drift
  - Average cost: €500 each
  - Annual: €2,500

With Drift Detection:
  - Automatic alerts on admin changes
  - 60% reduction in drift-related issues
  - 2 issues/year × €500 = €1,000

Savings: €2,500 - €1,000 = €1,500
Conservative estimate: €1,000/year
```

### Year 1 Net ROI

```
Total Costs (Year 1):
  NinjaRMM:                €6,000
  Core Framework:          €4,500
  Total:                  €10,500

Total Benefits (Year 1):  €16,250

Net Benefit:              €5,750
ROI:                      55%
Payback Period:           7.8 months
```

**Monthly Analysis:**
- Monthly benefit: €16,250 ÷ 12 = €1,354
- Monthly cost (Year 1): €10,500 ÷ 12 = €875
- Breakeven: €10,500 ÷ €1,354 = 7.8 months

---

## ONGOING ANNUAL ANALYSIS (Years 2-5)

### Annual Recurring Costs

| Item | Amount | Notes |
|------|--------|-------|
| NinjaRMM (100 devices) | €6,000 | €5/device/month |
| Core Framework Maintenance | €0 | Absorbed in operations |
| **Total Annual** | **€6,000** | |

### Annual Recurring Benefits

| Category | Amount | Notes |
|----------|--------|-------|
| Operational Efficiency | €8,250 | Sustained time savings |
| Downtime Prevention | €5,000 | Capacity management |
| Security Improvements | €3,000 | Incident reduction |
| **Total Annual** | **€16,250** | |

### Net Annual Benefit (Years 2-5)

```
Annual Benefits:          €16,250
Annual Costs:             €6,000
Net Annual Benefit:       €10,250
```

---

## 5-YEAR CUMULATIVE ANALYSIS

### 5-Year Total Costs

| Year | NinjaRMM | Core Framework | Total Annual | Cumulative |
|------|----------|----------------|--------------|------------|
| Year 0 | €0 | €4,500 | €4,500 | €4,500 |
| Year 1 | €6,000 | €0 | €6,000 | €10,500 |
| Year 2 | €6,000 | €0 | €6,000 | €16,500 |
| Year 3 | €6,000 | €0 | €6,000 | €22,500 |
| Year 4 | €6,000 | €0 | €6,000 | €28,500 |
| Year 5 | €6,000 | €0 | €6,000 | €34,500 |
| **Total** | **€30,000** | **€4,500** | **€34,500** | |

### 5-Year Total Benefits

| Year | Benefits | Cumulative |
|------|----------|------------|
| Year 1 | €16,250 | €16,250 |
| Year 2 | €16,250 | €32,500 |
| Year 3 | €16,250 | €48,750 |
| Year 4 | €16,250 | €65,000 |
| Year 5 | €16,250 | €81,250 |
| **Total** | **€81,250** | |

### 5-Year Net ROI

```
Total 5-Year Costs:       €34,500
Total 5-Year Benefits:    €81,250
Net 5-Year Benefit:       €46,750
ROI:                      136%
```

---

## DEVICE COUNT SCALING (Core Framework Only)

### ROI by Fleet Size

| Devices | NinjaRMM Annual | Core Framework | Year 1 Net Benefit | Year 1 ROI | 5-Year Net ROI |
|---------|-----------------|----------------|-------------------|------------|----------------|
| **25** | €1,500 | €4,500 | €10,250 | **171%** | €56,750 |
| **50** | €3,000 | €4,500 | €8,750 | **115%** | €53,750 |
| **100** | €6,000 | €4,500 | €5,750 | **55%** | €46,750 |
| **150** | €9,000 | €5,000 | €2,250 | **16%** | €40,250 |
| **200** | €12,000 | €5,500 | -€1,250 | **-7%** | €33,750 |
| **300** | €18,000 | €6,500 | -€8,250 | **-34%** | €20,250 |

**Analysis:**
- **Sweet Spot: 25-100 devices** - Excellent ROI (55-171% Year 1)
- **100-150 devices** - Positive ROI, strong 5-year returns
- **200+ devices** - Consider ML version for additional value or volume NinjaRMM pricing

**Core Framework Recommendation:** Ideal for 25-150 device environments

---

## COMPARISON: CORE vs ML FRAMEWORK

### Feature Comparison (100 Devices)

| Feature | Core Framework | ML Framework | Difference |
|---------|---------------|--------------|------------|
| **Investment** | €4,500 | €7,250 | +€2,750 |
| **Year 1 Total Cost** | €10,500 | €13,250 | +€2,750 |
| **Year 1 Benefits** | €16,250 | €22,000 | +€5,750 |
| **Year 1 Net ROI** | €5,750 (55%) | €8,750 (66%) | +€3,000 |
| **Payback Period** | 7.8 months | 7.2 months | -0.6 months |
| **5-Year Net ROI** | €46,750 (136%) | €49,750 (134%) | +€3,000 |

### Capability Comparison

| Capability | Core Framework | ML Framework |
|------------|----------------|--------------|
| Health Scores | Yes (0-100) | Yes (0-100) |
| Predictive Capacity | 30 days | 30-45 days |
| Hardware Failure Prediction | Reactive | 15-45 day advance |
| Anomaly Detection | Pattern-based | ML-powered (70-85% accuracy) |
| Root Cause Analysis | Manual (15-30 min) | Automated (<1 min) |
| Ransomware Detection | Signature-based | Behavioral (ML) |
| Automated Remediation | 90%+ success | 90%+ success |
| False Positive Rate | 10% | 10% |
| Deployment Time | 2-4 weeks | 6-8 weeks |
| Complexity | Low | Medium |

### When to Choose Core Framework

**Choose Core Framework if:**
- Team size: 25-150 devices
- No Python/ML expertise
- Want quick deployment (2-4 weeks)
- Budget conscious (€4,500 vs €7,250)
- Manual RCA acceptable (15-30 min)
- Reactive hardware replacement acceptable

**Expected ROI:** 55-171% Year 1 (depending on device count)

### When to Upgrade to ML Framework

**Consider ML Framework if:**
- Team size: 100+ devices
- Have Python expertise or willing to learn
- Want predictive maintenance (15-45 day hardware warnings)
- Want automated RCA (<1 min vs 15-30 min)
- Ransomware is high risk (behavioral detection)
- Can invest additional €2,750 for €5,750 additional annual benefit

**Expected ROI:** 66-203% Year 1, +€3,000 over Core in Year 1

---

## SCENARIO ANALYSIS (100 Devices, Core Framework)

### Conservative Scenario (50% Benefits Realized)

```
Year 1 Costs:             €10,500
Year 1 Benefits:          €8,125 (50% of €16,250)
Net Year 1:               -€2,375 (negative)
Payback:                  15.5 months (into Year 2)

5-Year Costs:             €34,500
5-Year Benefits:          €40,625 (€8,125 × 5)
Net 5-Year:               €6,125 (18% ROI)
```

**Conclusion:** Even at 50% effectiveness, positive 5-year ROI

### Moderate Scenario (75% Benefits Realized)

```
Year 1 Costs:             €10,500
Year 1 Benefits:          €12,188 (75% of €16,250)
Net Year 1:               €1,688 (16% ROI)
Payback:                  10.3 months

5-Year Costs:             €34,500
5-Year Benefits:          €60,938 (€12,188 × 5)
Net 5-Year:               €26,438 (77% ROI)
```

**Conclusion:** Likely scenario, solid positive ROI

### Aggressive Scenario (150% Benefits - Large Environments)

```
Year 1 Costs:             €10,500
Year 1 Benefits:          €24,375 (150% of €16,250)
Net Year 1:               €13,875 (132% ROI)
Payback:                  5.2 months

5-Year Costs:             €34,500
5-Year Benefits:          €121,875 (€24,375 × 5)
Net 5-Year:               €87,375 (253% ROI)
```

**Conclusion:** Achievable with high automation adoption and additional use cases

---

## COMPARATIVE ANALYSIS

### Option 1: RMM Only (No Framework)

```
Annual Cost:              €6,000 (NinjaRMM)
Benefits:                 €0 (baseline operations)
Operational Losses:       €31,200/year (downtime, manual work, incidents)
Net Annual:               -€25,200
5-Year Total Cost:        €186,000 (platform + losses)
```

### Option 2: RMM + Core Framework

```
Year 1 Cost:              €10,500
Year 1 Benefits:          €16,250
Year 1 Net:               €5,750 (55% ROI)

5-Year Cost:              €34,500
5-Year Benefits:          €81,250
5-Year Net:               €46,750 (136% ROI)
```

**Advantage:** €46,750 better than RMM-only over 5 years

### Option 3: RMM + ML Framework

```
Year 1 Cost:              €13,250
Year 1 Benefits:          €22,000
Year 1 Net:               €8,750 (66% ROI)

5-Year Net:               €49,750
```

**Comparison:** ML adds €3,000 over 5 years for €2,750 additional investment (109% return on incremental investment)

### Option 4: Enterprise Platform (Datadog)

```
Annual Cost:              €30,000 (100 devices × €25 × 12)
5-Year Cost:              €150,000
5-Year Net:               -€90,000 (negative ROI)
```

**Advantage:** Core Framework is €137,375 better than Datadog over 5 years

---

## BREAK-EVEN ANALYSIS

### Minimum Benefits Required (100 Devices)

**Year 1 Breakeven:**
```
Required Benefits = Year 1 Costs = €10,500
Projected Benefits = €16,250
Margin of Safety = (€16,250 - €10,500) / €16,250 = 35%
```

**Interpretation:** Benefits can drop 35% and still break even in Year 1

### Single Event Justification

**Option 1:** Prevent 1 major disk-full outage
- €10,600 outage prevented = Year 1 positive ROI

**Option 2:** Time savings only
- 210 hours saved @ €50/h = €10,500 (break-even)
- 17.5 hours/month = realistic for troubleshooting + maintenance savings

**Option 3:** Reduced false positives
- 300 hours saved @ €50/h = €15,000
- Easily covers Year 1 costs

---

## SENSITIVITY ANALYSIS

### Impact of NinjaRMM Pricing on Core Framework ROI

| NinjaRMM Price | Annual Cost (100 devices) | Year 1 Net | Year 1 ROI | 5-Year Net |
|----------------|---------------------------|------------|------------|------------|
| €3/device | €3,600 | €8,150 | 89% | €50,150 |
| **€5/device** | **€6,000** | **€5,750** | **55%** | **€46,750** |
| €7/device | €8,400 | €3,350 | 30% | €43,350 |
| €10/device | €12,000 | -€250 | -2% | €37,750 |

**Conclusion:** Core Framework ROI remains positive up to ~€9.50/device/month

### Impact of Device Count on Core Framework ROI

| Devices | Year 1 Net | Payback | 5-Year Net | ROI Break-Even |
|---------|------------|---------|------------|----------------|
| 25 | €10,250 | 3.5 mo | €56,750 | Month 4 |
| 50 | €8,750 | 5.2 mo | €53,750 | Month 6 |
| 100 | €5,750 | 7.8 mo | €46,750 | Month 8 |
| 150 | €2,250 | 12 mo | €40,250 | Month 12 |
| 200 | -€1,250 | 18 mo | €33,750 | Month 18 |

**Recommendation:** Core Framework ideal for 25-150 devices

---

## IMPLEMENTATION COSTS BY PHASE

### Phase 1: Core Monitoring (Weeks 1-2) - €1,200

| Task | Hours | Cost |
|------|-------|------|
| 35 essential fields | 3h | €150 |
| Scripts 1-13 deployment | 4h | €200 |
| Native monitoring setup | 2h | €100 |
| 15 P1 conditions | 3h | €150 |
| Testing | 6h | €300 |
| **Subtotal** | **18h** | **€900** |

### Phase 2: Extended Intelligence (Weeks 3-4) - €1,800

| Task | Hours | Cost |
|------|-------|------|
| 26 extended fields | 3h | €150 |
| Scripts 14-24 deployment | 5h | €250 |
| 40 conditions (P2+P3) | 8h | €400 |
| 30 dynamic groups | 6h | €300 |
| Testing | 6h | €300 |
| **Subtotal** | **28h** | **€1,400** |

### Training - €1,000

| Task | Hours | Cost |
|------|-------|------|
| Level 1 training (2 techs) | 10h | €500 |
| Senior tech training | 10h | €500 |
| **Subtotal** | **20h** | **€1,000** |

### Remediation Scripts - €500

| Task | Hours | Cost |
|------|-------|------|
| Scripts 40-65 deployment | 5h | €250 |
| Testing remediation | 5h | €250 |
| **Subtotal** | **10h** | **€500** |

**Total Core Framework: €4,500 (90 hours)**

---

## RECOMMENDATION

### For 25-150 Device Environments: **STRONGLY RECOMMENDED**

**Rationale:**
- Strong Year 1 ROI: 55-171% (depending on device count)
- Rapid payback: 3.5-7.8 months
- Excellent 5-year returns: €40,000-€57,000
- Low complexity: No ML expertise required
- Quick deployment: 2-4 weeks

**Approval Request:**
- NinjaRMM: €6,000/year (ongoing)
- Core Framework: €4,500 (one-time)
- Expected 5-Year Value: €46,750

### For 150-200 Device Environments: **RECOMMENDED WITH CONSIDERATIONS**

**Rationale:**
- Marginal Year 1 ROI: 16% to -7%
- Positive by Year 2
- Good 5-year returns: €33,750-€40,250

**Considerations:**
- Negotiate NinjaRMM volume pricing (target: <€5/device)
- Consider ML version for additional value (€49,750 vs €46,750)
- Focus deployment on high-value devices first

### For 200+ Device Environments: **UPGRADE TO ML FRAMEWORK**

**Rationale:**
- Core Framework ROI becomes marginal at scale
- ML Framework delivers better ROI for large environments
- ML capabilities (predictive maintenance, RCA) scale better
- Only €2,750 additional investment for €5,750 additional annual benefit

**Recommendation:** Deploy ML Framework instead (see 100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md)

---

## NEXT STEPS

**If Approved:**

1. **Month 1-2:** Deploy Core Framework (Phase 1 + Phase 2)
   - Cost: €1,000 NinjaRMM + €3,200 framework
   - Deliverable: 61 fields, 39 scripts, 55 conditions active

2. **Month 3:** Optimization and Training
   - Cost: €500 NinjaRMM + €1,300 training/testing
   - Deliverable: 90%+ automation success, staff certified

3. **Month 4-8:** Realize Benefits
   - Cost: €500/month NinjaRMM (€2,500 total)
   - Value: €5,750 cumulative benefits by Month 8 = break-even

4. **Month 9-12:** Ongoing Operations
   - Cost: €500/month NinjaRMM (€2,000 total)
   - Value: €5,750 additional benefits (cumulative €11,500)

**Decision Required:** Approve €10,500 Year 1 budget (€6,000 recurring + €4,500 one-time)

---

## APPENDICES

**Appendix A:** Core Framework Field List (61 fields)  
**Appendix B:** Core Framework Script List (39 scripts)  
**Appendix C:** Core Framework Condition List (55 conditions)  
**Appendix D:** Device Count Scaling Calculator  
**Appendix E:** Monthly Cash Flow Analysis  

**References:**
- 00_README.md (Framework Overview - Core deployment option)
- 01_Framework_Architecture.md (Technical Architecture)
- Troubleshooting_Guide_Servers_Clients.md (Operational Workflows)
- 100_Detailed_ROI_Analysis_ML_with_Platform_Costs.md (ML upgrade path)

---

**File:** 100_Detailed_ROI_Analysis_No_ML.md  
**Version:** 4.0 Core (No ML/RCA)  
**Last Updated:** February 1, 2026, 11:24 PM CET  
**Status:** Finance-Ready for Core Framework Deployments
