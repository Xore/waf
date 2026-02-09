$executionpolicy = Get-ExecutionPolicy
If ($executionpolicy -eq 'Restricted') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}
function Get-NinjaOneCard($Title, $Body, [string]$Icon, [string]$TitleLink, [String]$Classes) {
    <#
    $Info = 'This is the body of a card it is wrapped in a paragraph'

    Get-NinjaOneCard -Title "Tenant Details" -Data $Info
    #>

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
    # outputting for activity log
    $WifiDriverHtml = (netsh wlan show driver).Trim()  | ConvertTo-Json
    $WifiDrive = Get-NinjaOneCard -Title 'WiFi Driver Details' -Body $WifiDriverHtml -Icon 'fas fa-wifi style="color:#0364b8;'
    $CombinedHTML = '<div class="row g-1 rows-cols-2">' + 
    '<div class="col-xl-4 col-lg-4 col-md-4 col-sm-4 d-flex">' + $ODHTML + 
    '</div>' + $WifiDrive +
    '</div>'
    $CombinedHTML | Ninja-Property-Set-Piped -Name wifidriver

If ($executionpolicy -eq 'Restricted') {
    Set-ExecutionPolicy -ExecutionPolicy $executionpolicy -Force
}
