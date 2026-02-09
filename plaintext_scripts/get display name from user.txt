$userInfo = Get-WmiObject -Class Win32_ComputerSystem
$username = $($userInfo.UserName).Trim("DE\")
$displayname = ""
try{
  $strFilter = "(&(objectCategory=User)(samAccountName=$username))"
    
  $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
  $objSearcher.Filter = $strFilter
  
  $objPath = $objSearcher.FindOne()
  $objUser = $objPath.GetDirectoryEntry()
  $displayname = $objUser.Properties['displayname']
 if($displayname -ne "")  {
   Set-NinjaProperty -Name $env:customFieldName -Value $displayname
   write-host $displayname
   exit 0
 }
} catch {
    write-host "Fehler abgefangen: `r`n $_"
    exit 1
}
