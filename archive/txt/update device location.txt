$IpLocationMap = @{
    "10.1." = "Test1"
    "10.2." = "Test2"
    "10.3." = "Test3"
    "10.254." = "VPN"
}

# Function to get all private IP addresses using ipconfig
function Get-PrivateIPs {
    try {
        # Run ipconfig and capture output
        $ipconfigOutput = ipconfig
        $privateIPs = @()
        
        foreach ($line in $ipconfigOutput) {
            # Look for IPv4 Address lines
            if ($line -match "IPv4.*:\s*(\d+\.\d+\.\d+\.\d+)") {
                $ip = $matches[1]
                # Check if it's a private IP address (excluding loopback)
                if ($ip -match "^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)" -and $ip -ne "127.0.0.1") {
                    $privateIPs += $ip
                }
            }
        }
        
        return $privateIPs
    }
    catch {
        Write-Host "Error: Unable to retrieve private IP addresses using ipconfig."
        return @()
    }
}

# Function to check location based on IP
function Get-LocationFromIP {
    param($ipAddress)
    
    foreach ($prefix in $IpLocationMap.Keys) {
        if ($ipAddress.StartsWith($prefix)) {
            return $IpLocationMap[$prefix]
        }
    }
    return $null
}

# Main execution
$PrivateIPs = Get-PrivateIPs
$oldLocation = Ninja-Property-Get deviceLocation
$locationFound = $false

if ($PrivateIPs.Count -gt 0) {
    foreach ($ip in $PrivateIPs) {
        $location = Get-LocationFromIP -ipAddress $ip
        if ($location) {
            $locationFound = $true
            # Update location if different
            if ($oldLocation -ne $location) {
                Ninja-Property-Set deviceLocation $location
                Write-Host "Location updated to: $location"
            } else {
                Write-Host "Location not changed: $location"
            }
            break  # Stop at first match
        }
    }
    
    if (-not $locationFound) {
        Write-Host "Location: Unknown"
        if ($oldLocation -ne "Unknown") {
            Ninja-Property-Set deviceLocation "Unknown"
            Write-Host "Location updated to: Unknown"
        }
    }
    
    exit 0
} else {
    Write-Host "Error: No private IP addresses found"
    exit 1
}
