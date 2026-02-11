$sourceFile = $env:Sourcepath
$destinationFolder = "$env:OneDrive\Desktop"
Copy-Item -Path $sourceFile -Destination $destinationFolder -Force
