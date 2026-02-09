try {
  if (-not (Test-Path -Path "C:\Temp\AzureVPN\AzVpnAppx_4.0.1.0_ARM64_x86_x64.msixbundle" -PathType Leaf)){
    throw "Package file not found: C:\Temp\AzureVPN\AzVpnAppx_4.0.1.0_ARM64_x86_x64.msixbundle"
  }
  
  Add-AppxPackage C:\Temp\AzureVPN\AzVpnAppx_4.0.1.0_ARM64_x86_x64.msixbundle -ErrorAction Stop
  
  Write-Host "Appx package installed successfully."
  exit 0
}
catch {
  Write-Error "Appx package installation failed."
  Write-Error "Error details: $($_.Exception.Message)"
  
  if ($_.ErrorDetails) {
    Write-Error "Extended details: $($_.ErrorDetails.Message)"
  }
  exit 1
}