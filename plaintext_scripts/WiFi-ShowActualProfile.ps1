# 1. Get current Wi-Fi interface info
$wifiStatus = netsh wlan show interfaces

# 2. Parse into a hashtable
$wifiInfo = @{}
foreach ($line in $wifiStatus) {
    if ($line -match '^\s*(.+?)\s*:\s*(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $wifiInfo[$key] = $value
    }
}

# 3. Format as a clean multiline string
$wifiFormatted = ($wifiInfo.GetEnumerator() | Sort-Object Name | ForEach-Object {
    "{0,-25}: {1}" -f $_.Key, $_.Value
}) -join "`n"

# 4. Output for troubleshooting. You can skip this line or add a Ninja-Property-Set for Custom Fields
Write-Host "$wifiFormatted"