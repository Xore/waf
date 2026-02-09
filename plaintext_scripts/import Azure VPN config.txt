# stop the azure vpn process when running
Get-Process | where {$_.Name -like "azvpnappx"} | Stop-Process 
AzureVpn.exe -i MoellerGroupGlobalVPN.AzureVPN.xml