# Script 22: Capacity Trend Forecaster
# Predict resource exhaustion and track utilization trends
# Version 4.3 - Adjusted thresholds to reduce false positives

param(
    [Parameter()]
    [String]$Testrun = $env:testrun
)

try {
    # Check if testrun mode is enabled
    $isTestMode = ($Testrun -eq "True")
    
    if ($isTestMode) {
        Write-Host "========================================="
        Write-Host "TESTRUN MODE ENABLED"
        Write-Host "Using only Base64 test data"
        Write-Host "Today's real values will be ignored"
        Write-Host "========================================="
        Write-Host ""
    }
    
    Write-Host "Starting Capacity Trend Forecaster (v4.3)"

    # ============================================
    # BASE64 HELPER FUNCTIONS
    # ============================================
    
    function Write-Base64Field {
        param(
            [string]$FieldName,
            [object]$Data
        )
        
        if ($isTestMode) {
            Write-Host "  [TESTRUN] Skipped saving $FieldName"
            return
        }
        
        $json = $Data | ConvertTo-Json -Compress -Depth 10
        $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
        Ninja-Property-Set $FieldName $base64
    }

    function Read-Base64Field {
        param([string]$FieldName)
        
        $value = Ninja-Property-Get $FieldName
        if ([string]::IsNullOrEmpty($value)) { return $null }
        
        try {
            $json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value))
            return ($json | ConvertFrom-Json)
        } catch {
            return $null
        }
    }

    # ============================================
    # LINEAR REGRESSION
    # ============================================
    
    function Get-Regression {
        param([array]$Points)
        
        if ($Points.Count -lt 2) {
            return @{ Slope = 0; Valid = $false }
        }
        
        $n = $Points.Count
        $sumX = 0
        $sumY = 0
        $sumXY = 0
        $sumX2 = 0
        
        foreach ($p in $Points) {
            $sumX += $p.X
            $sumY += $p.Y
            $sumXY += ($p.X * $p.Y)
            $sumX2 += ($p.X * $p.X)
        }
        
        $denom = ($n * $sumX2) - ($sumX * $sumX)
        if ($denom -eq 0) { return @{ Slope = 0; Valid = $false } }
        
        $slope = (($n * $sumXY) - ($sumX * $sumY)) / $denom
        
        return @{ Slope = $slope; Valid = $true }
    }

    # ============================================
    # DROPDOWN MAPPINGS
    # ============================================
    
    $memTrendGuid = @{
        "Stable" = "2b702e1e-5f4b-4e88-800c-865cbcd9f9a6"
        "Increasing" = "b9533a91-54be-446e-bd72-c6bfea5c9a20"
        "Decreasing" = "ff3f265c-c876-4159-aad0-3b112c5ef657"
        "Volatile" = "f1d2956a-4210-43a6-b61c-e809e658e1c1"
    }
    
    $cpuTrendGuid = @{
        "Stable" = "88a57615-3d6d-4c51-a8e8-69fabe0ad5a7"
        "Increasing" = "059d6033-aeba-4ae4-90a3-77c2d2d7dfd4"
        "Decreasing" = "1badb13a-e32c-4a30-8f5a-915c7918d212"
        "Volatile" = "257619b0-8955-478c-b9d5-b8aaea0fa15c"
    }

    # ============================================
    # DISK CAPACITY
    # ============================================
    
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskSizeGB = [math]::Round($disk.Size / 1GB, 2)
    $diskUsedGB = $diskSizeGB - $diskFreeGB
    $diskFreePercent = [math]::Round(($diskFreeGB / $diskSizeGB) * 100, 2)

    # Read disk history
    $diskHistory = Read-Base64Field "capHistoricalDiskUsage"
    
    if ($null -eq $diskHistory) {
        $diskHistory = @(@{ Date = (Get-Date -Format "yyyy-MM-dd"); UsedGB = $diskUsedGB })
        Write-Host "Initialized disk history"
    } else {
        if ($diskHistory -isnot [array]) { $diskHistory = @($diskHistory) }
        
        # IN TESTRUN MODE: Skip updating today's entry, use Base64 data as-is
        if (-not $isTestMode) {
            $today = Get-Date -Format "yyyy-MM-dd"
            $found = $false
            
            for ($i = 0; $i -lt $diskHistory.Count; $i++) {
                if ($diskHistory[$i].Date -eq $today) {
                    $diskHistory[$i].UsedGB = $diskUsedGB
                    $found = $true
                    Write-Host "Updated disk entry for $today"
                    break
                }
            }
            
            if (-not $found) {
                $diskHistory += @{ Date = $today; UsedGB = $diskUsedGB }
                Write-Host "Added disk entry for $today"
            }
            
            if ($diskHistory.Count -gt 30) {
                $diskHistory = $diskHistory | Select-Object -Last 30
            }
        } else {
            Write-Host "[TESTRUN] Using Base64 disk data as-is ($($diskHistory.Count) records)"
        }
    }

    # Calculate disk growth
    $daysUntilFull = 999
    $diskGrowth = 0
    
    if ($diskHistory.Count -ge 2) {
        $baseDate = [DateTime]::ParseExact($diskHistory[0].Date, "yyyy-MM-dd", $null)
        $points = @()
        
        foreach ($entry in $diskHistory) {
            try {
                $date = [DateTime]::ParseExact($entry.Date, "yyyy-MM-dd", $null)
                $points += @{ X = ($date - $baseDate).Days; Y = $entry.UsedGB }
            } catch { }
        }
        
        $reg = Get-Regression -Points $points
        
        if ($reg.Valid -and $reg.Slope -gt 0.01) {
            $diskGrowth = $reg.Slope
            
            # In testrun mode, calculate based on last entry in Base64 data
            if ($isTestMode) {
                $lastEntry = $diskHistory[-1]
                $lastUsedGB = $lastEntry.UsedGB
                $diskFreeFromTest = $diskSizeGB - $lastUsedGB
                $daysUntilFull = [math]::Round($diskFreeFromTest / $diskGrowth)
            } else {
                $daysUntilFull = [math]::Round($diskFreeGB / $diskGrowth)
            }
            
            if ($daysUntilFull -gt 999 -or $daysUntilFull -lt 0) { $daysUntilFull = 999 }
        }
    }

    Write-Base64Field "capHistoricalDiskUsage" $diskHistory

    # ============================================
    # MEMORY UTILIZATION
    # ============================================
    
    $os = Get-CimInstance Win32_OperatingSystem
    $memUtil = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    # Read memory history
    $memHistory = Read-Base64Field "capHistoricalMemUsage"
    
    if ($null -eq $memHistory) {
        $memHistory = @(@{ Date = (Get-Date -Format "yyyy-MM-dd"); Utilization = $memUtil })
        $memTrend = "Stable"
        $memAvg = $memUtil
        Write-Host "Initialized memory history"
    } else {
        if ($memHistory -isnot [array]) { $memHistory = @($memHistory) }
        
        # IN TESTRUN MODE: Skip updating today's entry, use Base64 data as-is
        if (-not $isTestMode) {
            $today = Get-Date -Format "yyyy-MM-dd"
            $found = $false
            
            for ($i = 0; $i -lt $memHistory.Count; $i++) {
                if ($memHistory[$i].Date -eq $today) {
                    $memHistory[$i].Utilization = $memUtil
                    $found = $true
                    Write-Host "Updated memory entry for $today"
                    break
                }
            }
            
            if (-not $found) {
                $memHistory += @{ Date = $today; Utilization = $memUtil }
                Write-Host "Added memory entry for $today"
            }
            
            if ($memHistory.Count -gt 30) {
                $memHistory = $memHistory | Select-Object -Last 30
            }
        } else {
            Write-Host "[TESTRUN] Using Base64 memory data as-is ($($memHistory.Count) records)"
        }

        # Calculate memory trend - ADJUSTED THRESHOLDS
        if ($memHistory.Count -ge 7) {  # Require 7 days minimum for better trend detection
            $values = $memHistory | ForEach-Object { $_.Utilization }
            $memAvg = ($values | Measure-Object -Average).Average
            $variance = ($values | ForEach-Object { [math]::Pow($_ - $memAvg, 2) } | Measure-Object -Average).Average
            $stdDev = [math]::Sqrt($variance)
            
            # Coefficient of Variation (CV) - measures relative volatility
            $cv = if ($memAvg -gt 0) { ($stdDev / $memAvg) * 100 } else { 0 }

            $baseDate = [DateTime]::ParseExact($memHistory[0].Date, "yyyy-MM-dd", $null)
            $points = @()
            
            foreach ($entry in $memHistory) {
                try {
                    $date = [DateTime]::ParseExact($entry.Date, "yyyy-MM-dd", $null)
                    $points += @{ X = ($date - $baseDate).Days; Y = $entry.Utilization }
                } catch { }
            }
            
            $reg = Get-Regression -Points $points
            $weeklyGrowth = if ($reg.Valid -and $memAvg -gt 0) { ($reg.Slope * 7 / $memAvg) * 100 } else { 0 }

            # ADJUSTED: Higher thresholds to reduce false positives
            # Volatile: CV > 30% (was 20%) - only flag if truly erratic
            # Increasing: Weekly growth > 5% (was 2%) - only flag significant trends
            # Decreasing: Weekly decline < -5% (was -2%)
            
            if ($cv -gt 30) { 
                $memTrend = "Volatile" 
                Write-Host "  Memory: Volatile detected (CV=$([math]::Round($cv, 2))%)"
            }
            elseif ($weeklyGrowth -gt 5) { 
                $memTrend = "Increasing" 
                Write-Host "  Memory: Increasing detected (Weekly growth=$([math]::Round($weeklyGrowth, 2))%)"
            }
            elseif ($weeklyGrowth -lt -5) { 
                $memTrend = "Decreasing" 
                Write-Host "  Memory: Decreasing detected (Weekly decline=$([math]::Round($weeklyGrowth, 2))%)"
            }
            else { 
                $memTrend = "Stable" 
                Write-Host "  Memory: Stable (CV=$([math]::Round($cv, 2))%, Weekly=$([math]::Round($weeklyGrowth, 2))%)"
            }
        } else {
            $memTrend = "Stable"
            $memAvg = $memUtil
            Write-Host "  Memory: Insufficient data ($($memHistory.Count) days, need 7+)"
        }
    }

    Write-Base64Field "capHistoricalMemUsage" $memHistory

    # ============================================
    # CPU UTILIZATION
    # ============================================
    
    # CPU Counter mit Sprach-Erkennung
    try {
        # Versuche englischen Counter
        $cpuUtil = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 -ErrorAction Stop | 
            Select-Object -ExpandProperty CounterSamples | 
            Measure-Object -Property CookedValue -Average).Average, 2)
    } catch {
        try {
            # Fallback: Deutscher Counter
            $cpuUtil = [math]::Round((Get-Counter '\Prozessor(_Total)\Prozessorzeit (%)' -SampleInterval 2 -MaxSamples 3 -ErrorAction Stop | 
                Select-Object -ExpandProperty CounterSamples | 
                Measure-Object -Property CookedValue -Average).Average, 2)
        } catch {
            Write-Host "[Warning] Could not read CPU counter. Using 0% as fallback."
            $cpuUtil = 0
        }
    }
    
    # Read CPU history
    $cpuHistory = Read-Base64Field "capHistoricalCPUUsage"
    
    if ($null -eq $cpuHistory) {
        $cpuHistory = @(@{ Date = (Get-Date -Format "yyyy-MM-dd"); Utilization = $cpuUtil })
        $cpuTrend = "Stable"
        $cpuAvg = $cpuUtil
        Write-Host "Initialized CPU history"
    } else {
        if ($cpuHistory -isnot [array]) { $cpuHistory = @($cpuHistory) }
        
        # IN TESTRUN MODE: Skip updating today's entry, use Base64 data as-is
        if (-not $isTestMode) {
            $today = Get-Date -Format "yyyy-MM-dd"
            $found = $false
            
            for ($i = 0; $i -lt $cpuHistory.Count; $i++) {
                if ($cpuHistory[$i].Date -eq $today) {
                    $cpuHistory[$i].Utilization = $cpuUtil
                    $found = $true
                    Write-Host "Updated CPU entry for $today"
                    break
                }
            }
            
            if (-not $found) {
                $cpuHistory += @{ Date = $today; Utilization = $cpuUtil }
                Write-Host "Added CPU entry for $today"
            }
            
            if ($cpuHistory.Count -gt 30) {
                $cpuHistory = $cpuHistory | Select-Object -Last 30
            }
        } else {
            Write-Host "[TESTRUN] Using Base64 CPU data as-is ($($cpuHistory.Count) records)"
        }

        # Calculate CPU trend - ADJUSTED THRESHOLDS
        if ($cpuHistory.Count -ge 7) {  # Require 7 days minimum for better trend detection
            $values = $cpuHistory | ForEach-Object { $_.Utilization }
            $cpuAvg = ($values | Measure-Object -Average).Average
            $variance = ($values | ForEach-Object { [math]::Pow($_ - $cpuAvg, 2) } | Measure-Object -Average).Average
            $stdDev = [math]::Sqrt($variance)
            
            # Coefficient of Variation (CV) - measures relative volatility
            $cv = if ($cpuAvg -gt 0) { ($stdDev / $cpuAvg) * 100 } else { 0 }

            $baseDate = [DateTime]::ParseExact($cpuHistory[0].Date, "yyyy-MM-dd", $null)
            $points = @()
            
            foreach ($entry in $cpuHistory) {
                try {
                    $date = [DateTime]::ParseExact($entry.Date, "yyyy-MM-dd", $null)
                    $points += @{ X = ($date - $baseDate).Days; Y = $entry.Utilization }
                } catch { }
            }
            
            $reg = Get-Regression -Points $points
            $weeklyGrowth = if ($reg.Valid -and $cpuAvg -gt 0) { ($reg.Slope * 7 / $cpuAvg) * 100 } else { 0 }

            # ADJUSTED: Higher thresholds to reduce false positives
            # For CPU around 20%, normal fluctuations are expected
            # Volatile: CV > 40% (was 20%) - CPU naturally varies more than memory
            # Increasing: Weekly growth > 8% (was 2%) - only flag significant sustained growth
            # Decreasing: Weekly decline < -8% (was -2%)
            
            if ($cv -gt 40) { 
                $cpuTrend = "Volatile" 
                Write-Host "  CPU: Volatile detected (CV=$([math]::Round($cv, 2))%)"
            }
            elseif ($weeklyGrowth -gt 8) { 
                $cpuTrend = "Increasing" 
                Write-Host "  CPU: Increasing detected (Weekly growth=$([math]::Round($weeklyGrowth, 2))%)"
            }
            elseif ($weeklyGrowth -lt -8) { 
                $cpuTrend = "Decreasing" 
                Write-Host "  CPU: Decreasing detected (Weekly decline=$([math]::Round($weeklyGrowth, 2))%)"
            }
            else { 
                $cpuTrend = "Stable" 
                Write-Host "  CPU: Stable (CV=$([math]::Round($cv, 2))%, Weekly=$([math]::Round($weeklyGrowth, 2))%)"
            }
        } else {
            $cpuTrend = "Stable"
            $cpuAvg = $cpuUtil
            Write-Host "  CPU: Insufficient data ($($cpuHistory.Count) days, need 7+)"
        }
    }

    Write-Base64Field "capHistoricalCPUUsage" $cpuHistory

    # ============================================
    # HEALTH SCORE - ADJUSTED THRESHOLDS
    # ============================================
    
    $health = 100

    # In testrun mode, calculate disk free % based on last entry in Base64 data
    if ($isTestMode -and $diskHistory.Count -gt 0) {
        $lastEntry = $diskHistory[-1]
        $lastUsedGB = $lastEntry.UsedGB
        $testDiskFreeGB = $diskSizeGB - $lastUsedGB
        $testDiskFreePercent = [math]::Round(($testDiskFreeGB / $diskSizeGB) * 100, 2)
        
        if ($testDiskFreePercent -lt 10) { $health -= 40 }
        elseif ($testDiskFreePercent -lt 20) { $health -= 20 }
    } else {
        if ($diskFreePercent -lt 10) { $health -= 40 }
        elseif ($diskFreePercent -lt 20) { $health -= 20 }
    }

    if ($daysUntilFull -lt 30) { $health -= 30 }
    elseif ($daysUntilFull -lt 90) { $health -= 15 }

    # ADJUSTED: Higher thresholds for memory and CPU penalties
    # Memory: Only penalize if consistently above 90% (was 80%)
    # CPU: Only penalize if consistently above 85% (was 75%)
    if ($memAvg -gt 90) { $health -= 15 }
    if ($cpuAvg -gt 85) { $health -= 15 }
    
    # Only penalize for "Increasing" trend, not "Volatile" (normal for CPU/Memory)
    if ($memTrend -eq "Increasing") { $health -= 10 }
    if ($cpuTrend -eq "Increasing") { $health -= 10 }

    if ($health -lt 0) { $health = 0 }

    # ============================================
    # ALERT
    # ============================================
    
    $alert = ($daysUntilFull -lt 30 -or $health -lt 50)

    # ============================================
    # UPDATE FIELDS
    # ============================================
    
    if (-not $isTestMode) {
        Ninja-Property-Set capDaysUntilDiskFull $daysUntilFull
        Ninja-Property-Set -Type Dropdown capMemoryUtilizationTrend $memTrendGuid[$memTrend]
        Ninja-Property-Set -Type Dropdown capCPUUtilizationTrend $cpuTrendGuid[$cpuTrend]
        Ninja-Property-Set capCapacityHealthScore $health
        Ninja-Property-Set capCapacityAlert $alert
    } else {
        Write-Host ""
        Write-Host "[TESTRUN] Would update custom fields:"
        Write-Host "  capDaysUntilDiskFull = $daysUntilFull"
        Write-Host "  capMemoryUtilizationTrend = $memTrend ($($memTrendGuid[$memTrend]))"
        Write-Host "  capCPUUtilizationTrend = $cpuTrend ($($cpuTrendGuid[$cpuTrend]))"
        Write-Host "  capCapacityHealthScore = $health"
        Write-Host "  capCapacityAlert = $alert"
    }

    # ============================================
    # OUTPUT
    # ============================================
    
    Write-Host ""
    if ($isTestMode) {
        Write-Host "========================================="
        Write-Host "TESTRUN COMPLETED - NO DATA WRITTEN"
        Write-Host "Results based purely on Base64 test data"
        Write-Host "========================================="
    } else {
        Write-Host "SUCCESS: Capacity forecast completed"
    }
    Write-Host ""
    Write-Host "=== DISK CAPACITY ==="
    if ($isTestMode -and $diskHistory.Count -gt 0) {
        $lastEntry = $diskHistory[-1]
        $testUsed = $lastEntry.UsedGB
        $testFree = $diskSizeGB - $testUsed
        $testFreePercent = [math]::Round(($testFree / $diskSizeGB) * 100, 2)
        Write-Host "  [TESTRUN] Disk Used (from test data): $testUsed GB"
        Write-Host "  [TESTRUN] Disk Free (calculated): $testFree GB ($testFreePercent%)"
    } else {
        Write-Host "  Disk Free: $diskFreeGB GB ($diskFreePercent%)"
    }
    Write-Host "  Growth Rate: $([math]::Round($diskGrowth, 3)) GB/day"
    Write-Host "  Days Until Full: $daysUntilFull"
    Write-Host "  History Records: $($diskHistory.Count)"
    Write-Host ""
    Write-Host "=== UTILIZATION TRENDS ==="
    Write-Host "  Memory Trend: $memTrend"
    Write-Host "  Memory Avg: $([math]::Round($memAvg, 2))%"
    Write-Host "  Memory Records: $($memHistory.Count)"
    Write-Host "  CPU Trend: $cpuTrend"
    Write-Host "  CPU Avg: $([math]::Round($cpuAvg, 2))%"
    Write-Host "  CPU Records: $($cpuHistory.Count)"
    Write-Host ""
    Write-Host "=== CAPACITY HEALTH ==="
    Write-Host "  Health Score: $health/100"
    Write-Host "  Alert Status: $alert"

    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "Stack: $($_.ScriptStackTrace)"
    exit 1
}
