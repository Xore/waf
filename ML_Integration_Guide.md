# Machine Learning Integration Guide for NinjaOne Framework

**Version:** 1.0  
**Date:** February 1, 2026, 9:28 PM CET  
**Purpose:** Leveraging ML/AI on framework metrics for predictive operations

---

## Executive Summary

The NinjaOne Custom Field Framework generates 277 intelligence fields updated by 110 scripts, producing rich time-series data ideal for machine learning applications. This guide explains how to leverage ML techniques for anomaly detection, predictive maintenance, capacity forecasting, and automated incident response.

**Key ML Opportunities:**
- **Anomaly Detection:** Identify unusual patterns before they become incidents
- **Predictive Maintenance:** Forecast device failures 7-30 days in advance
- **Capacity Forecasting:** Predict resource exhaustion with 90%+ accuracy
- **Root Cause Analysis:** Automatically correlate metrics during incidents
- **False Positive Reduction:** Improve alerting precision by 70%+

---

## Part 1: ML-Ready Data Sources from Framework

### Time-Series Metrics Available for ML

#### High-Frequency Metrics (Every 4 hours - 6 data points/day)

**Performance Metrics:**
- STATCPUAveragePercent (Float) - CPU utilization
- STATMemoryUsedPercent (Float) - Memory utilization
- STATDiskFreePercent (Float) - Disk free space
- STATDiskActivePercent (Float) - Disk I/O activity
- NETGatewayLatencyMs (Integer) - Network latency

**Health Scores:**
- OPSHealthScore (0-100) - Composite health
- OPSStabilityScore (0-100) - System stability
- OPSPerformanceScore (0-100) - Performance rating
- OPSSecurityScore (0-100) - Security posture
- OPSCapacityScore (0-100) - Capacity headroom

**Stability Indicators:**
- STATAppCrashes24h (Integer) - Application crashes
- STATAppHangs24h (Integer) - Application hangs
- STATServiceFailures24h (Integer) - Service failures
- STATUptimeDays (Float) - System uptime

#### Daily Metrics (1 data point/day)

**Security & Compliance:**
- SECFailedLogonCount24h (Integer) - Failed login attempts
- SECSuspiciousLoginScore (0-100) - Anomaly score
- UPDMissingCriticalCount (Integer) - Missing patches
- UPDPatchAgeDays (Integer) - Patch freshness

**User Experience:**
- UXUserSatisfactionScore (0-100) - UX composite
- UXBootTimeSec (Integer) - Boot performance
- UXApplicationHangCount24h (Integer) - App hangs

**Configuration Drift:**
- DRIFTActiveChanges (Integer) - Active drift events
- DRIFTNewAppsCount (Integer) - Shadow IT detection
- DRIFTLocalAdminCount (Integer) - Admin drift

#### Weekly Metrics (Trend Analysis)

**Capacity Forecasting:**
- CAPDaysUntilDiskFull (Integer) - Predicted days until full
- CAPDiskGrowthRateMBDay (Float) - Growth rate
- CAPMemoryForecastRisk (Dropdown) - Memory pressure forecast
- CAPCPUForecastRisk (Dropdown) - CPU trend forecast

**Predictive Indicators:**
- Device age, battery health, SMART status
- Historical failure patterns
- Replacement probability scores

---

## Part 2: ML Use Cases & Algorithms

### Use Case 1: Anomaly Detection (Proactive Issue Detection)

**Objective:** Detect unusual system behavior before it causes outages

**Best Algorithms:**
- **Isolation Forest** - Unsupervised outlier detection
- **Autoencoder Neural Networks** - Reconstruction error-based detection
- **LSTM Autoencoders** - Time-series anomaly detection
- **One-Class SVM** - Novelty detection for normal behavior

**Framework Metrics to Use:**
```
Primary Features:
- OPSHealthScore (time-series)
- STATCPUAveragePercent (time-series)
- STATMemoryUsedPercent (time-series)
- STATAppCrashes24h (count data)
- NETGatewayLatencyMs (time-series)

Contextual Features:
- BASEBusinessCriticality (categorical)
- SRVRole (categorical)
- NETLocationCurrent (categorical)
```

**Implementation Approach:**

1. **Data Collection (Export from NinjaOne):**
   - Export custom field values via NinjaOne API
   - Collect 30-90 days historical data minimum
   - Structure: DeviceID, Timestamp, [277 metrics]

2. **Feature Engineering:**
   - Calculate rolling averages (7-day, 14-day, 30-day)
   - Compute rate of change (delta from previous day)
   - Create interaction features (HealthScore * StabilityScore)
   - Encode categorical variables (SRVRole, NETLocation)

3. **Model Training (Isolation Forest Example):**
```python
from sklearn.ensemble import IsolationForest
import pandas as pd

# Load historical data
df = pd.read_csv('ninjaone_metrics_historical.csv')

# Select features
features = [
    'OPSHealthScore', 'OPSStabilityScore', 
    'STATCPUAveragePercent', 'STATMemoryUsedPercent',
    'STATAppCrashes24h', 'NETGatewayLatencyMs'
]

X = df[features].fillna(df[features].median())

# Train Isolation Forest
model = IsolationForest(
    contamination=0.1,  # Expect 10% anomalies
    random_state=42,
    n_estimators=200
)
model.fit(X)

# Predict anomalies (-1 = anomaly, 1 = normal)
df['anomaly'] = model.predict(X)
df['anomaly_score'] = model.score_samples(X)

# Flag devices with anomalies
anomalies = df[df['anomaly'] == -1]
print(f"Detected {len(anomalies)} anomalous devices")
```

4. **Deployment:**
   - Daily: Export current metrics from NinjaOne
   - Run ML model on current data
   - Flag devices with anomaly_score < threshold
   - Create NinjaOne alerts for anomalous devices
   - Update custom field: MLAnomalyDetected (Checkbox)

**Expected Results:**
- 70% reduction in false positives vs static thresholds
- 3-7 day advance warning before critical failures
- 90%+ accuracy in identifying degrading systems

---

### Use Case 2: Predictive Maintenance (Failure Forecasting)

**Objective:** Predict device failures 7-30 days in advance

**Best Algorithms:**
- **Random Forest Classifier** - Feature importance + accuracy
- **XGBoost/LightGBM** - Gradient boosting for imbalanced data
- **LSTM Networks** - Sequential pattern recognition
- **Survival Analysis** - Time-to-failure prediction

**Framework Metrics to Use:**
```
Reliability Indicators:
- STATBSODCount30d (failure history)
- STATAppCrashes24h (stability)
- STATServiceFailures24h (system health)
- STATUptimeDays (restart frequency)

Hardware Health:
- BATHealthPercent (battery degradation)
- Native SMART Status (drive health)
- STATDiskActivePercent (IO stress)

Performance Degradation:
- OPSHealthScore_trend (7-day rolling avg)
- OPSStabilityScore_trend (declining stability)
- STATBootTimeSec (increasing boot time)
```

**Implementation Approach:**

1. **Label Historical Failures:**
   - Identify devices that failed in past 12 months
   - Extract their metrics 30 days before failure
   - Label: 1 = failed within 30 days, 0 = healthy

2. **Feature Engineering:**
```python
# Create degradation indicators
df['HealthScore_7d_trend'] = df.groupby('DeviceID')['OPSHealthScore'].rolling(7).mean().reset_index(0, drop=True)
df['CrashCount_increasing'] = (df['STATAppCrashes24h'] > df['STATAppCrashes24h'].shift(7)).astype(int)
df['BootTime_increasing'] = (df['STATBootTimeSec'] > df['STATBootTimeSec'].shift(7)).astype(int)

# Days since last issue
df['DaysSinceLastCrash'] = df.groupby('DeviceID')['STATAppCrashes24h'].apply(lambda x: (x > 0).cumsum())
```

3. **Model Training (Random Forest):**
```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

features = [
    'OPSHealthScore', 'OPSStabilityScore',
    'STATBSODCount30d', 'STATAppCrashes24h',
    'HealthScore_7d_trend', 'CrashCount_increasing',
    'BATHealthPercent', 'STATBootTimeSec'
]

X = df[features].fillna(0)
y = df['failed_within_30d']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = RandomForestClassifier(
    n_estimators=300,
    max_depth=10,
    class_weight='balanced',  # Handle imbalanced data
    random_state=42
)

model.fit(X_train, y_train)

# Evaluate
y_pred = model.predict(X_test)
print(classification_report(y_test, y_pred))

# Feature importance
importance = pd.DataFrame({
    'feature': features,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False)
print(importance)
```

4. **Deployment:**
   - Daily prediction on all active devices
   - Probability score: model.predict_proba(X)[:, 1]
   - Update NinjaOne field: MLFailureRisk (0-100)
   - Alert if MLFailureRisk > 70 (High), > 90 (Critical)
   - Trigger proactive maintenance workflows

**Expected Results:**
- 85-95% accuracy in predicting failures 30 days ahead
- 60-70% reduction in unplanned downtime
- Proactive hardware replacement saves €2,000-€5,000 per failure

---

### Use Case 3: Capacity Forecasting (Time-Series Prediction)

**Objective:** Predict when resources (disk, memory, CPU) will be exhausted

**Best Algorithms:**
- **ARIMA** - Classical time-series forecasting
- **Prophet (Facebook)** - Automatic seasonality detection
- **LSTM Networks** - Deep learning for complex patterns
- **Temporal Fusion Transformer** - State-of-the-art forecasting

**Framework Metrics to Use:**
```
Time-Series Targets:
- STATDiskFreePercent (predict when < 10%)
- STATMemoryUsedPercent (predict when > 90%)
- STATCPUAveragePercent (predict sustained high load)

Existing Forecasts (to validate/improve):
- CAPDaysUntilDiskFull (current rule-based forecast)
- CAPDiskGrowthRateMBDay (linear trend)
```

**Implementation Approach (Facebook Prophet):**

```python
from prophet import Prophet
import pandas as pd

# Load historical disk usage data
df = pd.read_csv('disk_usage_timeseries.csv')
# Format: DeviceID, Timestamp, STATDiskFreePercent

# Prepare data for Prophet (requires 'ds' and 'y' columns)
device_id = 'DEVICE-12345'
device_data = df[df['DeviceID'] == device_id][['Timestamp', 'STATDiskFreePercent']]
device_data.columns = ['ds', 'y']

# Train Prophet model
model = Prophet(
    yearly_seasonality=False,
    weekly_seasonality=True,
    daily_seasonality=False,
    changepoint_prior_scale=0.05  # Detect trend changes
)
model.fit(device_data)

# Forecast next 90 days
future = model.make_future_dataframe(periods=90)
forecast = model.predict(future)

# Find when disk space will be < 10%
critical_date = forecast[forecast['yhat'] < 10]['ds'].min()
days_until_critical = (critical_date - pd.Timestamp.now()).days

print(f"Disk will be critical in {days_until_critical} days")

# Update NinjaOne field: CAPDaysUntilDiskFull_ML
```

**Advanced: Multi-Device Forecasting at Scale:**

```python
# Use Spark for parallel forecasting across 1000+ devices
from pyspark.sql import SparkSession
from pyspark.sql.functions import pandas_udf, PandasUDFType

spark = SparkSession.builder.appName("CapacityForecasting").getOrCreate()

@pandas_udf("int", PandasUDFType.GROUPED_AGG)
def forecast_days_until_critical(timestamps, disk_free_pct):
    # Prophet forecasting logic here
    # Return days until < 10%
    pass

# Apply to all devices in parallel
forecasts = spark_df.groupBy('DeviceID').agg(
    forecast_days_until_critical('Timestamp', 'STATDiskFreePercent').alias('DaysUntilCritical')
)
```

**Expected Results:**
- 90-95% accuracy in predicting capacity exhaustion
- 30-90 day advance warning for procurement
- Reduce emergency hardware purchases by 80%

---

### Use Case 4: Root Cause Analysis (Incident Correlation)

**Objective:** Automatically identify which metrics correlate with incidents

**Best Algorithms:**
- **Correlation Analysis** - Pearson/Spearman correlation
- **Granger Causality** - Time-series causality testing
- **Graph Neural Networks** - Dependency mapping
- **Association Rule Mining** - Frequent pattern detection

**Framework Metrics to Use:**
```
All 277 metrics during incident windows:
- 4 hours before incident
- During incident
- 2 hours after resolution

Focus on high-variance metrics:
- OPS scores (sudden drops)
- STAT telemetry (spikes in crashes/hangs)
- SEC metrics (failed logins, suspicious activity)
- NET metrics (latency spikes, disconnects)
```

**Implementation Approach:**

```python
import pandas as pd
from scipy.stats import spearmanr

# Load metrics during incident window
incident_data = df[(df['Timestamp'] >= incident_start - pd.Timedelta(hours=4)) &
                   (df['Timestamp'] <= incident_end)]

# Calculate correlation with incident severity
correlations = {}
for metric in metrics_list:
    corr, p_value = spearmanr(incident_data[metric], incident_data['IncidentSeverity'])
    if p_value < 0.05:  # Statistically significant
        correlations[metric] = abs(corr)

# Rank by correlation strength
top_causes = sorted(correlations.items(), key=lambda x: x[1], reverse=True)[:10]

print("Top 10 correlated metrics:")
for metric, corr in top_causes:
    print(f"{metric}: {corr:.3f}")
```

**Expected Results:**
- Reduce MTTR (Mean Time To Resolve) by 50%
- Automatic identification of root cause in 70% of incidents
- Build knowledge base of metric patterns → failure modes

---

### Use Case 5: Smart Alerting (False Positive Reduction)

**Objective:** Improve alert precision using ML-based thresholds

**Best Algorithms:**
- **Dynamic Thresholding** - Statistical control limits
- **Multi-Metric Classification** - Alert vs non-alert prediction
- **Ensemble Methods** - Combine multiple signals

**Current Challenge:**
- Static thresholds (e.g., CPU > 90%) generate false positives
- Need context-aware thresholds based on device profile

**ML Solution:**

```python
from sklearn.ensemble import GradientBoostingClassifier

# Training data: historical alerts labeled as true positive or false positive
# Features: metric values at time of alert
# Label: 1 = true positive (real issue), 0 = false positive

features = [
    'STATCPUAveragePercent',
    'STATMemoryUsedPercent',
    'OPSHealthScore',
    'OPSStabilityScore',
    'STATAppCrashes24h',
    'BASEBusinessCriticality_encoded'
]

X_train = alert_history[features]
y_train = alert_history['true_positive']

model = GradientBoostingClassifier(n_estimators=200)
model.fit(X_train, y_train)

# Real-time: when static threshold triggers, ask ML model
current_metrics = get_current_metrics(device_id)
alert_probability = model.predict_proba([current_metrics])[0, 1]

if alert_probability > 0.7:
    send_alert("High confidence alert", device_id)
elif alert_probability > 0.4:
    send_alert("Medium confidence - investigate", device_id)
else:
    suppress_alert("Likely false positive", device_id)
```

**Expected Results:**
- 70% reduction in false positive alerts
- Alert confidence scoring (0-100%)
- Improved alert fatigue for operations team

---

## Part 3: ML Implementation Architecture

### Data Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  NinjaOne Framework (277 Custom Fields + Native Metrics)    │
│  - 110 Scripts collect data every 4h / daily / weekly       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Data Export Layer                                           │
│  - NinjaOne API: GET /api/v2/devices/{id}/custom-fields     │
│  - Scheduled export: Daily CSV/JSON dumps                    │
│  - Time-series database: InfluxDB, TimescaleDB              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Feature Engineering & Storage                               │
│  - Data warehouse: Snowflake, BigQuery, Databricks          │
│  - Feature store: Feast, Tecton                             │
│  - Transformations: Rolling averages, deltas, encoding      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ML Model Training & Deployment                              │
│  - Training: Python (scikit-learn, PyTorch, TensorFlow)     │
│  - MLOps: MLflow, Weights & Biases, Kubeflow               │
│  - Serving: FastAPI, TensorFlow Serving, Seldon            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Prediction Feedback Loop                                    │
│  - Daily batch predictions on all devices                    │
│  - Update NinjaOne custom fields:                           │
│    • MLAnomalyScore (0-100)                                 │
│    • MLFailureRisk (0-100)                                  │
│    • MLCapacityForecast (Days until critical)               │
│  - Trigger NinjaOne alerts/automation based on ML scores    │
└─────────────────────────────────────────────────────────────┘
```

### Recommended Tech Stack

**Data Export & Storage:**
- **InfluxDB** - Purpose-built for time-series data
- **TimescaleDB** - PostgreSQL extension for time-series
- **Apache Parquet** - Columnar storage for analytics

**ML Frameworks:**
- **scikit-learn** - Classical ML (Random Forest, Isolation Forest)
- **Prophet** - Time-series forecasting (Facebook)
- **PyTorch/TensorFlow** - Deep learning (LSTM, autoencoders)
- **XGBoost/LightGBM** - Gradient boosting for tabular data

**MLOps & Deployment:**
- **MLflow** - Experiment tracking, model registry
- **Docker** - Containerized model serving
- **FastAPI** - REST API for model inference
- **Airflow/Prefect** - Workflow orchestration

**Monitoring & Observability:**
- **Prometheus + Grafana** - Model performance monitoring
- **Evidently AI** - Data drift detection
- **WhyLabs** - ML observability

---

## Part 4: Quick Start Implementation Plan

### Phase 1: Data Collection (Week 1-2)

**Action Items:**
1. Set up automated NinjaOne API exports
   - Export all 277 custom fields daily
   - Include device metadata (DeviceID, Name, Type, Role)
   - Store in TimescaleDB or InfluxDB

2. Create data quality checks
   - Monitor field population rate (should be >95%)
   - Detect missing values and outliers
   - Validate timestamp consistency

3. Collect 30-90 days historical data
   - Minimum for ML model training
   - More data = better model accuracy

**Deliverable:** Data pipeline exporting NinjaOne metrics to time-series database

---

### Phase 2: Anomaly Detection MVP (Week 3-4)

**Action Items:**
1. Select 20-50 pilot devices
2. Train Isolation Forest model on OPS/STAT metrics
3. Deploy daily batch predictions
4. Create new NinjaOne custom field: MLAnomalyScore (Integer 0-100)
5. Update field daily with ML predictions
6. Create compound condition: MLAnomalyScore > 80

**Success Criteria:**
- Model detects 3-5 anomalies per day
- 70%+ of anomalies are validated as real issues
- 50%+ reduction in false positives vs static thresholds

**Deliverable:** Working anomaly detection alerting to operations team

---

### Phase 3: Predictive Maintenance (Week 5-8)

**Action Items:**
1. Label historical device failures (past 12 months)
2. Train Random Forest failure prediction model
3. Deploy weekly batch predictions
4. Create new fields:
   - MLFailureRisk (Integer 0-100)
   - MLFailurePredictedDate (DateTime)
5. Create alerts for devices with >70% failure risk
6. Trigger proactive maintenance workflows

**Success Criteria:**
- 80%+ accuracy in predicting failures 30 days ahead
- Prevent 5-10 unplanned failures in first quarter
- ROI: €5,000-€15,000 in avoided downtime

**Deliverable:** Proactive maintenance program driven by ML

---

### Phase 4: Capacity Forecasting (Week 9-12)

**Action Items:**
1. Deploy Prophet models for disk/memory/CPU forecasting
2. Run weekly forecasts on all devices
3. Update capacity fields with ML predictions:
   - CAPDaysUntilDiskFull_ML (Integer)
   - CAPMemoryExhaustionDate_ML (DateTime)
4. Create procurement planning reports
5. Automate capacity alerts (60-90 day advance warning)

**Success Criteria:**
- 90%+ forecast accuracy (±7 days)
- Reduce emergency purchases by 80%
- Improve capacity planning cycle time by 50%

**Deliverable:** Automated capacity planning with 90-day forecasts

---

## Part 5: Expected ROI from ML Integration

### Cost Analysis

**Initial Setup (Weeks 1-12):**
- Data engineer: 40 hours @ €100/hour = €4,000
- ML engineer: 80 hours @ €120/hour = €9,600
- Infrastructure (cloud): €500/month × 3 = €1,500
- **Total Investment:** €15,100

**Ongoing Costs (Annual):**
- Cloud infrastructure: €500/month × 12 = €6,000
- Model maintenance: 20 hours/year @ €120/hour = €2,400
- **Annual Operating Cost:** €8,400

### Benefits Analysis (Annual)

**Reduced Downtime:**
- Prevent 10 failures/year @ €2,000/incident = €20,000
- 50% reduction in MTTR saves 100 hours @ €50/hour = €5,000

**Capacity Planning:**
- Avoid 5 emergency purchases @ €1,500 premium = €7,500
- Optimize hardware lifecycle (15% savings) = €10,000

**Operational Efficiency:**
- 70% reduction in false positives saves 200 hours @ €50/hour = €10,000
- Automated root cause analysis saves 150 hours @ €80/hour = €12,000

**Total Annual Benefit:** €64,500

**Net ROI Year 1:** (€64,500 - €15,100 - €8,400) / €15,100 = **271% ROI**

**Ongoing Annual ROI (Year 2+):** (€64,500 - €8,400) / €8,400 = **668% ROI**

---

## Part 6: Best Practices & Pitfalls

### Best Practices

1. **Start Small, Scale Fast**
   - Begin with 20-50 pilot devices
   - Prove value before scaling to 500+ devices
   - Use proven algorithms (Isolation Forest, Random Forest) before complex models

2. **Monitor Model Performance**
   - Track precision, recall, F1 score monthly
   - Retrain models quarterly with new data
   - Detect data drift (input distribution changes)

3. **Human-in-the-Loop**
   - Don't fully automate critical decisions
   - Provide ML confidence scores (0-100%)
   - Allow operators to override ML predictions

4. **Feature Engineering is Key**
   - 80% of ML success comes from good features
   - Use domain knowledge (OPS scores, STAT trends)
   - Create interaction features (HealthScore × StabilityScore)

5. **Version Control Everything**
   - Version models (MLflow model registry)
   - Version training data (DVC, LakeFS)
   - Track experiments (parameters, metrics, artifacts)

### Common Pitfalls

1. **Insufficient Training Data**
   - Need 30-90 days minimum for time-series
   - Need 100+ failure examples for predictive maintenance
   - Solution: Use transfer learning or synthetic data augmentation

2. **Data Quality Issues**
   - Missing values (scripts not running)
   - Outliers (incorrect data)
   - Solution: Implement data quality monitoring from Day 1

3. **Overfitting**
   - Model works great on training data, fails on new data
   - Solution: Use cross-validation, regularization, simpler models

4. **Alert Fatigue**
   - ML generates too many low-confidence alerts
   - Solution: Set confidence thresholds (only alert if >70% confidence)

5. **Lack of Feedback Loop**
   - Don't know if ML predictions were accurate
   - Solution: Label predictions as TP/FP and retrain model

---

## Part 7: Advanced ML Techniques

### Deep Learning for Complex Patterns

**LSTM Autoencoder for Anomaly Detection:**
```python
import tensorflow as tf
from tensorflow.keras.layers import LSTM, RepeatVector, TimeDistributed, Dense

# Define sequence length (7 days of 4-hour samples = 42 timesteps)
sequence_length = 42
features = 6  # OPSHealthScore, CPU, Memory, Crashes, etc.

# Build LSTM autoencoder
model = tf.keras.Sequential([
    LSTM(128, activation='relu', input_shape=(sequence_length, features)),
    RepeatVector(sequence_length),
    LSTM(128, activation='relu', return_sequences=True),
    TimeDistributed(Dense(features))
])

model.compile(optimizer='adam', loss='mse')

# Train on normal data only
model.fit(normal_sequences, normal_sequences, epochs=50, batch_size=32)

# Detect anomalies based on reconstruction error
reconstructions = model.predict(test_sequences)
reconstruction_errors = np.mean(np.abs(test_sequences - reconstructions), axis=(1,2))

threshold = np.percentile(reconstruction_errors, 95)
anomalies = reconstruction_errors > threshold
```

### Reinforcement Learning for Automated Remediation

**Use RL to learn optimal remediation actions:**
- State: Current device metrics (OPS scores, STAT telemetry)
- Actions: Restart service, clear cache, reboot, escalate to human
- Reward: +10 if issue resolved, -5 if action failed, -20 if downtime increased

### Graph Neural Networks for Infrastructure Mapping

**Model device dependencies:**
- Nodes: Devices (servers, workstations, network equipment)
- Edges: Dependencies (server → database, workstation → domain controller)
- Use GNN to predict cascade failures when one device fails

---

## Conclusion

Machine learning integration with the NinjaOne Custom Field Framework unlocks proactive IT operations, transforming reactive firefighting into predictive maintenance. With 277 rich metrics updated continuously, you have the foundation for world-class ML-powered monitoring.

**Start with anomaly detection (highest ROI, lowest complexity), then expand to predictive maintenance and capacity forecasting.**

---

**File:** ML_Integration_Guide.md  
**Version:** 1.0  
**Last Updated:** February 1, 2026, 9:28 PM CET  
**Status:** Production Ready
