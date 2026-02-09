$IpLocationMap = @{
    "10.1." = @("https://example1.com", "Location1")
    "10.8." = @("https://example1.com", "Location2")
}
$datei = "C:\Program Files\CONTACT CIM Database Desktop 11.7\cdbpc.ini"
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

# Function to get BDE server URL based on IP
function Get-LocationFromIP {
    param($ipAddress)
    
    foreach ($prefix in $IpLocationMap.Keys) {
        if ($ipAddress.StartsWith($prefix)) {
            # return first Element (CDB WEB URL)
            return $IpLocationMap[$prefix][0]
        }
    }
    return $null
}

# Main execution
$PrivateIPs = Get-PrivateIPs
if ($PrivateIPs.Count -gt 0) {
    foreach ($ip in $PrivateIPs) {
        $location = (Get-LocationFromIP -ipAddress $ip)
        if ($location) {
            # Update CDB server url based on IP location
            "[Login]`nLanguage=de`nLoginUseOIDC=0`nPersistentWebEnv=0`nServerURL=$location" | set-content $datei
            break  # Stop at first match
        }
    }
    exit 0
} else {
    Write-Host "Error: No private IP addresses found"
    exit 1
}