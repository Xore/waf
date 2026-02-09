try {
  # -PathType Leaf defines type as file
  if (-not (Test-Path -Path $env:sourcefile -PathType Leaf)) {
    throw "Source file does not exist: $env:sourcefile"
  }
  Copy-Item -Path $env:sourcefile -Destination $env:destinationpath -Force -ErrorAction Stop
  Write-Host "File copies successfully to $env:destinationpath"
  exit 0
}
catch {
  Write-Error "File copy failed. $_"
  exit 1
}