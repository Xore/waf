<#
.SYNOPSIS
    Capacity Analyzer - Resource Capacity and Headroom Assessment

.DESCRIPTION
    Calculates resource capacity score by assessing available headroom across disk storage,
    memory utilization, and disk consumption trends. Provides capacity planning metric to
    identify systems approaching resource exhaustion and requiring hardware upgrades or
    optimization.
    
    Evaluates both current resource consumption and predictive capacity planning metrics
    (days until disk full) to enable proactive capacity management before resource constraints
    impact operations.
    
    Capacity Scoring Model (100 points, deductions applied):
    
    Disk Space Availability (50 points maximum):
    - Free space < 10%: -50 points (critical capacity constraint)
    - Free space < 20%: -30 points (severe capacity concern)
    - Free space < 30%: -15 points (moderate capacity warning)
    - Free space >= 30%: 0 deduction
    
    Memory Utilization (25 points maximum):
    - Memory utilization > 90%: -25 points (critical memory pressure)
    - Memory utilization > 85%: -20 points (high memory pressure)
    - Memory utilization > 80%: -10 points (elevated memory usage)
    - Memory utilization <= 80%: 0 deduction
    
    Disk Consumption Trend (15 points maximum):
    - Days until disk full < 30: -15 points (urgent expansion needed)
    - Days until disk full < 60: -10 points (plan expansion soon)
    - Days until disk full >= 60: 0 deduction
    - Note: Requires trend analysis from capacity tracking scripts
    
    Score Interpretation:
    - 90-100: Excellent capacity - ample headroom
    - 75-89: Good capacity - adequate headroom
    - 60-74: Fair capacity - monitor usage trends
    - 50-59: Poor capacity - planning required
    - Below 50: Critical capacity - immediate action required
    
    Use Cases:
    - Proactive capacity planning
    - Hardware upgrade prioritization
    - Resource constraint identification
    - Budget planning for expansions
    - Preventing service disruptions from resource exhaustion

.NOTES
    Frequency: Daily
    Runtime: ~15 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - OPSCapacityScore (Integer: 0-100 capacity score)
    - OPSLastScoreUpdate (Text: timestamp in yyyy-MM-dd HH:mm:ss format)
    
    Fields Read:
    - CAPDaysUntilDiskFull (Integer: from capacity tracking scripts)
    
    Dependencies:
    - WMI/CIM: Win32_LogicalDisk, Win32_OperatingSystem
    - Capacity tracking scripts for trend data
    
    Metrics Tracked:
    - Disk free space percentage (C: drive)
    - Physical memory utilization percentage
    - Projected days until disk full (trend-based)
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Capacity Analyzer (v4.0)..."

    # Initialize score at maximum
    $capacityScore = 100
    $constraints = @()

    # Assess disk capacity
    Write-Output "INFO: Assessing disk capacity..."
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
    $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskSizeGB = [math]::Round($disk.Size / 1GB, 2)
    
    Write-Output "INFO: Disk C: - $diskFreeGB GB free of $diskSizeGB GB ($diskFreePercent%)"

    if ($diskFreePercent -lt 10) {
        $capacityScore -= 50
        $constraints += "Critical disk space: $diskFreePercent% free (-50)"
        Write-Output "CRITICAL: Disk space critically low ($diskFreePercent%) - immediate cleanup required (-50 points)"
    } elseif ($diskFreePercent -lt 20) {
        $capacityScore -= 30
        $constraints += "Low disk space: $diskFreePercent% free (-30)"
        Write-Output "WARNING: Disk space low ($diskFreePercent%) - cleanup recommended (-30 points)"
    } elseif ($diskFreePercent -lt 30) {
        $capacityScore -= 15
        $constraints += "Moderate disk space: $diskFreePercent% free (-15)"
        Write-Output "INFO: Disk space moderate ($diskFreePercent%) - monitor consumption (-15 points)"
    } else {
        Write-Output "PASS: Disk space adequate ($diskFreePercent%)"
    }

    # Assess memory utilization
    Write-Output "INFO: Assessing memory capacity..."
    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
    $memUsedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    $memTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    
    Write-Output "INFO: Memory - $memUsedGB GB used of $memTotalGB GB ($memUtilization%)"

    if ($memUtilization -gt 90) {
        $capacityScore -= 25
        $constraints += "Critical memory pressure: $memUtilization% used (-25)"
        Write-Output "CRITICAL: Memory pressure critical ($memUtilization%) - upgrade or optimize (-25 points)"
    } elseif ($memUtilization -gt 85) {
        $capacityScore -= 20
        $constraints += "High memory pressure: $memUtilization% used (-20)"
        Write-Output "WARNING: Memory pressure high ($memUtilization%) - consider upgrade (-20 points)"
    } elseif ($memUtilization -gt 80) {
        $capacityScore -= 10
        $constraints += "Elevated memory usage: $memUtilization% used (-10)"
        Write-Output "INFO: Memory usage elevated ($memUtilization%) - monitor trends (-10 points)"
    } else {
        Write-Output "PASS: Memory capacity adequate ($memUtilization%)"
    }

    # Assess disk consumption trend
    Write-Output "INFO: Checking disk consumption forecast..."
    $daysUntilFull = Ninja-Property-Get CAPDaysUntilDiskFull
    if ([string]::IsNullOrEmpty($daysUntilFull)) { 
        $daysUntilFull = 999
        Write-Output "INFO: No disk consumption trend data available (assuming adequate)"
    } else {
        Write-Output "INFO: Projected days until disk full: $daysUntilFull"
    }

    if ($daysUntilFull -lt 30 -and $daysUntilFull -gt 0) {
        $capacityScore -= 15
        $constraints += "Disk full in $daysUntilFull days (-15)"
        Write-Output "CRITICAL: Disk will be full in $daysUntilFull days - urgent expansion required (-15 points)"
    } elseif ($daysUntilFull -lt 60 -and $daysUntilFull -gt 0) {
        $capacityScore -= 10
        $constraints += "Disk full in $daysUntilFull days (-10)"
        Write-Output "WARNING: Disk will be full in $daysUntilFull days - plan expansion (-10 points)"
    } elseif ($daysUntilFull -gt 0 -and $daysUntilFull -lt 999) {
        Write-Output "INFO: Disk consumption trend acceptable ($daysUntilFull days until full)"
    }

    # Enforce score boundaries
    if ($capacityScore -lt 0) { $capacityScore = 0 }
    if ($capacityScore -gt 100) { $capacityScore = 100 }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating capacity metrics..."
    Ninja-Property-Set OPSCapacityScore $capacityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Capacity analysis complete"
    Write-Output "FINAL SCORE: $capacityScore/100"
    Write-Output "CAPACITY METRICS:"
    Write-Output "  - Disk Free: $diskFreePercent% ($diskFreeGB GB of $diskSizeGB GB)"
    Write-Output "  - Memory Utilization: $memUtilization% ($memUsedGB GB of $memTotalGB GB)"
    Write-Output "  - Days Until Disk Full: $daysUntilFull"
    
    if ($constraints.Count -gt 0) {
        Write-Output "CAPACITY CONSTRAINTS IDENTIFIED:"
        $constraints | ForEach-Object { Write-Output "  - $_" }
    } else {
        Write-Output "No capacity constraints detected"
    }
    
    # Provide capacity assessment
    if ($capacityScore -ge 90) {
        Write-Output "ASSESSMENT: Excellent capacity - ample headroom"
    } elseif ($capacityScore -ge 75) {
        Write-Output "ASSESSMENT: Good capacity - adequate headroom"
    } elseif ($capacityScore -ge 60) {
        Write-Output "ASSESSMENT: Fair capacity - monitor usage trends"
    } elseif ($capacityScore -ge 50) {
        Write-Output "ASSESSMENT: Poor capacity - planning required"
    } else {
        Write-Output "ASSESSMENT: Critical capacity - immediate action required"
    }
    
    # Provide recommendations
    if ($diskFreePercent -lt 20 -or $memUtilization -gt 85) {
        Write-Output "RECOMMENDATION: Hardware upgrade or optimization needed"
    }
    if ($daysUntilFull -lt 60 -and $daysUntilFull -gt 0) {
        Write-Output "RECOMMENDATION: Plan disk expansion within $daysUntilFull days"
    }

    exit 0
} catch {
    Write-Output "ERROR: Capacity Analyzer failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
