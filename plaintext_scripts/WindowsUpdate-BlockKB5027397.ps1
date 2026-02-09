if ( -not (Get-Module -ListAvailable -Name NuGet)) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
}
if ( -not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-Module -Name PSWindowsUpdate -Repository PSGallery -Confirm:$false -Force | Out-Null
}
Set-ExecutionPolicy Bypass -Scope Process

Hide-WindowsUpdate -KBArticleID KB5027397 -Confirm:$false