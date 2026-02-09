$sourceFile = $env:sourceFileOrFolder
$copyToPublic = $env:copyToPublicDesktop

if(-not (Test-Path -LiteralPath $sourceFile)){
    Write-Host "Source file not found : '$sourceFile'"
    exit 1
}

$userprofiles = Get-ChildItem 'C:\Users' -Directory

if($copyToPublic -eq 'false'){
    $userprofiles = Get-ChildItem 'C:\Users' -Directory | Where-Object {
        $_.Name -notin @('All Users', 'Default', 'Default User', 'Public')
    }
}

foreach ($userprofile in $userprofiles)
{
    $desktopPath = Join-Path $userprofile.FullName 'Desktop'

    if(Test-Path -LiteralPath $desktopPath -PathType Container) {
        try{
            Copy-Item -LiteralPath $sourceFile -Destination $desktopPath -Force -ErrorAction Stop
            Write-Host "Copies sourcefile: '$sourcefile' to desktopPath '$desktopPath'"
        } catch {
            Write-Host "Failed to copy to standard desktop: '$desktopPath': $($_.Exception.Message)"
        }
    }

    $oneDriveDesktop = Join-Path $userprofile.FullName 'OneDrive - MöllerGroup GmbH\Desktop'
        if(Test-Path -LiteralPath $oneDriveDesktop -PathType Container) {
            try{
                Copy-Item -LiteralPath $sourceFile -Destination $oneDriveDesktop -Force
                Write-Host "Copies sourcefile: '$sourcefile' to onedriveDesktop '$oneDriveDesktop'"
            } catch {
                Write-Host "Failed to copy to onedriveDesktop: '$oneDriveDesktop': $($_.Exception.Message)"
            }
        }
    }

exit 0