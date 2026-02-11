$DSRegOutput = [PSObject]::New()
& dsregcmd.exe /status | Where-Object { $_ -match ' : ' } | ForEach-Object {
    $Item = $_.Trim() -split '\s:\s'
    $DSRegOutput | Add-Member -MemberType NoteProperty -Name $($Item[0] -replace '[:\s]', '') -Value $Item[1] -ErrorAction SilentlyContinue
}
function Get-NinjaOneCard($Title, $Body, [string]$Icon, [string]$TitleLink, [String]$Classes) {
    [System.Collections.Generic.List[String]]$OutputHTML = @()
    $OutputHTML.add('<div class="card flex-grow-1' + $(if ($classes) {
                ' ' + $classes 
            }) + '" >')
    if ($Title) {
        $OutputHTML.add('<div class="card-title-box"><div class="card-title" >' + $(if ($Icon) {
                    '<i class="' + $Icon + '"></i>&nbsp;&nbsp;' 
                }) + $Title + '</div>')
        if ($TitleLink) {
            $OutputHTML.add('<div class="card-link-box"><a href="' + $TitleLink + '" target="_blank" class="card-link" ><i class="fas fa-arrow-up-right-from-square" style="color: #337ab7;"></i></a></div>')
        }
        $OutputHTML.add('</div>')
    }
    $OutputHTML.add('<div class="card-body" >')
    $OutputHTML.add('<p class="card-text" >' + $Body + '</p>')
    $OutputHTML.add('</div></div>')

    return $OutputHTML -join ''
}
function Get-NinjaOneInfoCard($Title, $Data, [string]$Icon, [string]$TitleLink) {
    [System.Collections.Generic.List[String]]$ItemsHTML = @()
    foreach ($Item in $Data.PSObject.Properties) {
        $ItemsHTML.add('<p ><b >' + $Item.Name + '</b><br />' + $Item.Value + '</p>')
    }
    return Get-NinjaOneCard -Title $Title -Body ($ItemsHTML -join '') -Icon $Icon -TitleLink $TitleLink
}

$table = $DSRegOutput | Select-Object *joined
$enrollmentHTML = (Get-NinjaOneInfoCard -Title "Domain/Intune Enrollment" -Data $table -Icon 'fas fa-building" style="color:#1e3050;')
$enrollmentHTML | Ninja-Property-Set-Piped -Name enrollmentstatus