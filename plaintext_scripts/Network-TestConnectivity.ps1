#Requires -Version 5.1

<#
.SYNOPSIS
    Tests network connectivity to specified hosts using ping and port tests.

.DESCRIPTION
    This script performs comprehensive network connectivity tests including ICMP ping and TCP 
    port connectivity checks. It can test multiple hosts and ports, providing detailed results 
    for each test. This is useful for troubleshooting network issues, verifying firewall rules, 
    and monitoring service availability.
    
    The script supports:
    - ICMP ping tests with configurable count
    - TCP port connectivity tests
    - Multiple hosts and ports
    - Detailed response time reporting
    - Success/failure status for each test

.PARAMETER Hosts
    Comma-separated list of hostnames or IP addresses to test.
    Example: "google.com,8.8.8.8,192.168.1.1"

.PARAMETER Ports
    Comma-separated list of TCP ports to test. If specified, performs port tests in addition to ping.
    Example: "80,443,3389"

.PARAMETER PingCount
    Number of ping attempts per host. Default: 4

.PARAMETER Timeout
    Timeout in milliseconds for each connection attempt. Default: 1000 (1 second)

.PARAMETER SaveToCustomField
    Name of a custom field to save the connectivity test results.

.EXAMPLE
    -Hosts "google.com,8.8.8.8"

    [Info] Testing connectivity to 2 host(s)...
    Host: google.com
      Ping: Success (4/4 replies, avg 15ms)
    Host: 8.8.8.8
      Ping: Success (4/4 replies, avg 12ms)

.EXAMPLE
    -Hosts "webserver.local" -Ports "80,443" -PingCount 2

    [Info] Testing connectivity to 1 host(s) on 2 port(s)...
    Host: webserver.local
      Ping: Success (2/2 replies, avg 5ms)
      Port 80: Open (response time 2ms)
      Port 443: Open (response time 3ms)

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release notes: v3.0.0 - Upgraded to V3.0.0 standards (script-scoped exit code)
    
.COMPONENT
    Test-Connection - PowerShell network testing cmdlet
    System.Net.Sockets.TcpClient - TCP connectivity testing
    
.LINK
    https://github.com/Xore/waf

.FUNCTIONALITY
    - Performs ICMP ping tests to verify host reachability
    - Tests TCP port connectivity to verify service availability
    - Supports multiple hosts and ports
    - Reports success rates and response times
    - Configurable ping count and timeout values
    - Can save comprehensive test results to custom fields
    - Useful for network troubleshooting and monitoring
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Hosts,
    [string]$Ports,
    [int]$PingCount = 4,
    [int]$Timeout = 1000,
    [string]$SaveToCustomField
)

begin {
    if ($env:hosts -and $env:hosts -notlike "null") {
        $Hosts = $env:hosts
    }
    if ($env:ports -and $env:ports -notlike "null") {
        $Ports = $env:ports
    }
    if ($env:pingCount -and $env:pingCount -notlike "null") {
        $PingCount = [int]$env:pingCount
    }
    if ($env:timeout -and $env:timeout -notlike "null") {
        $Timeout = [int]$env:timeout
    }
    if ($env:saveToCustomField -and $env:saveToCustomField -notlike "null") {
        $SaveToCustomField = $env:saveToCustomField
    }

    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value
        )
        $NinjaValue = $Value
        $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }

    function Test-TcpPort {
        param(
            [string]$Host,
            [int]$Port,
            [int]$Timeout
        )
        
        try {
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $StartTime = Get-Date
            $AsyncResult = $TcpClient.BeginConnect($Host, $Port, $null, $null)
            $Wait = $AsyncResult.AsyncWaitHandle.WaitOne($Timeout, $false)
            
            if ($Wait) {
                try {
                    $TcpClient.EndConnect($AsyncResult)
                    $ResponseTime = ((Get-Date) - $StartTime).TotalMilliseconds
                    $TcpClient.Close()
                    return @{ Success = $true; ResponseTime = [math]::Round($ResponseTime, 0) }
                } catch {
                    $TcpClient.Close()
                    return @{ Success = $false; Error = $_.Exception.Message }
                }
            } else {
                $TcpClient.Close()
                return @{ Success = $false; Error = "Connection timeout" }
            }
        } catch {
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    }

    $script:ExitCode = 0
    $HostArray = @()
    $PortArray = @()
    
    if ($Hosts) {
        $HostArray = $Hosts -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
    
    if ($Ports) {
        $PortArray = $Ports -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
}

process {
    if ($HostArray.Count -eq 0) {
        Write-Host "[Error] No hosts specified"
        exit 1
    }

    try {
        if ($PortArray.Count -gt 0) {
            Write-Host "[Info] Testing connectivity to $($HostArray.Count) host(s) on $($PortArray.Count) port(s)..."
        } else {
            Write-Host "[Info] Testing connectivity to $($HostArray.Count) host(s)..."
        }

        $Report = @()
        $FailureCount = 0

        foreach ($Host in $HostArray) {
            Write-Host "`nHost: $Host"
            $HostReport = "Host: $Host"
            
            try {
                $PingResult = Test-Connection -ComputerName $Host -Count $PingCount -ErrorAction SilentlyContinue
                
                if ($PingResult) {
                    $SuccessCount = ($PingResult | Measure-Object).Count
                    $AvgTime = [math]::Round(($PingResult | Measure-Object -Property ResponseTime -Average).Average, 0)
                    Write-Host "  Ping: Success ($SuccessCount/$PingCount replies, avg ${AvgTime}ms)"
                    $HostReport += " | Ping: $SuccessCount/$PingCount (${AvgTime}ms)"
                } else {
                    Write-Host "  Ping: Failed (0/$PingCount replies)"
                    $HostReport += " | Ping: Failed"
                    $FailureCount++
                }
            } catch {
                Write-Host "  Ping: Error - $_"
                $HostReport += " | Ping: Error"
                $FailureCount++
            }
            
            foreach ($Port in $PortArray) {
                $PortTest = Test-TcpPort -Host $Host -Port $Port -Timeout $Timeout
                
                if ($PortTest.Success) {
                    Write-Host "  Port $Port: Open (response time $($PortTest.ResponseTime)ms)"
                    $HostReport += " | Port $Port: Open ($($PortTest.ResponseTime)ms)"
                } else {
                    Write-Host "  Port $Port: Closed or unreachable"
                    $HostReport += " | Port $Port: Closed"
                    $FailureCount++
                }
            }
            
            $Report += $HostReport
        }

        if ($FailureCount -gt 0) {
            Write-Host "`n[Warn] $FailureCount test(s) failed"
            $script:ExitCode = 1
        } else {
            Write-Host "`n[Info] All connectivity tests passed"
        }

        if ($SaveToCustomField) {
            try {
                $Report -join "; " | Set-NinjaProperty -Name $SaveToCustomField
                Write-Host "[Info] Results saved to custom field '$SaveToCustomField'"
            } catch {
                Write-Host "[Error] Failed to save to custom field: $_"
                $script:ExitCode = 1
            }
        }
    }
    catch {
        Write-Host "[Error] Failed to test connectivity: $_"
        $script:ExitCode = 1
    }

    exit $script:ExitCode
}

end {
}
