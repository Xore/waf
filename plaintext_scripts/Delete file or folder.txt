$target = $env:fileOrFolder

if([string]::IsNullOrWhiteSpace($target)) {
  Write-Host "Target not set or is empty"
  exit 1
}

if(-not (Test-Path -LiteralPath $target)){
    Write-Host "The specified path does not exist: '$target'"
    exit 1
}

try {
    Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
    Write-Host "Successfully deleted: '$target'"
    exit 0
} catch {
    Write-Host "Filed to delete '$target'. Error: $($_.Exception.Message)"
    exit 1
}