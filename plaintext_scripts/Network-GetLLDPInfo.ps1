if ( -not (Get-Module -ListAvailable -Name NuGet)) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
}
if ( -not (Get-Module -ListAvailable -Name PSDiscoveryProtocol)) {
    Install-Module -Name PSDiscoveryProtocol -Repository PSGallery -Confirm:$false -Force | Out-Null
}
Set-ExecutionPolicy Bypass -Scope Process

do {
    $Packet = Invoke-DiscoveryProtocolCapture -Type LLDP -ErrorAction SilentlyContinue
    $lldp = Get-DiscoveryProtocolData -Packet $Packet
} until ($lldp.Device -notlike "Polycom*")
$lldp | ConvertTo-Html | Ninja-Property-Set-Piped -Name lldpinfo