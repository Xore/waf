$updateSession = New-Object -ComObject Microsoft.Update.Session;
$updateSearcher = $updateSession.CreateUpdateSearcher();
$historyCount = $updateSearcher.GetTotalHistoryCount();
$updates = $updateSearcher.QueryHistory(0, $historyCount) | Where-Object { $_.ResultCode -eq 2 } | Sort-Object -Property Date -Descending | Select-Object -First 1;
$today = Get-Date (Get-Date).ToUniversalTime() -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
$lastUpdateTime = Get-Date ($updates.Date).ToUniversalTime() -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
if ($updates) {
  $updateoverdue = "false"
  $dayssinceupdate = (NEW-TIMESPAN -Start $lastUpdateTime -End $today).Days;
  
  if ( $dayssinceupdate -ge $env:daysThreshold) { $updateoverdue = "true" }
  
  Set-NinjaProperty -Name lastwindowsupdatedate -Value (Get-Date($lastUpdateTime) -Format "yyyy-MM-ddTHH:mm:ss")
  Set-NinjaProperty -Name lastwindowsupdatename -Value $($updates.Title)
  Set-NinjaProperty -Name lastwindowsupdateoverdue -Value $updateoverdue
} else { Write-Output "No updates found in the history." }