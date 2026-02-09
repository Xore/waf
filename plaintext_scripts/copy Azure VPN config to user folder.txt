try {
  # -PathType Leaf defines type as file
  if (-not (Test-Path -Path "C:\Temp\AzureVPN\MoellerGroupGlobalVPN.AzureVPN.xml" -PathType Leaf)) {
    throw "Source file does not exist: C:\Temp\AzureVPN\MoellerGroupGlobalVPN.AzureVPN.xml"
  }
  
  Copy-Item -Path "C:\Temp\AzureVPN\MoellerGroupGlobalVPN.AzureVPN.xml" -Destination $env:USERPROFILE\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState\ -Force -ErrorAction Stop
  
  Write-Host "File copies successfully to $env:USERPROFILE\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState\"
  exit 0
}
catch {
  Write-Error "File copy failed. $_"
  exit 1
}