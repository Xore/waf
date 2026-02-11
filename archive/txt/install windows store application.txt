try {
  # verify that winget is available
  if(-not (Get-Command winget -ErrorAction Stop)) {
    throw "winget is not installed or not available in PATH."
  }
  
  winget install -e -i --id=$env:packageid --source=msstore --accept-package-agreements --accept-source-agreements
  
  if($LASTEXITCODE -ne 0) {
    throw "winget installation failed with exit code $LASTEXITCODE."
  }
  
  Write-Host "Application installed susscessfully: $env:packageid"
  exit 0
}
catch {
  Write-Error "Application installation failed. $_"
  exit 1
}