param(
  [string]$AdapterName = "Wi-Fi",
  [string]$Target = "192.168.4.1"
)

$ErrorActionPreference = "Continue"

Write-Host "=== FARMCART SMARTGROW R8.14 - WINDOWS WLAN / RF SURVEY READONLY ==="
Write-Host "MODE=READ_ONLY"
Write-Host "ESP_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "RTC_WRITE=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host "FLASH_WRITE=NO"
Write-Host ("ADAPTER=" + $AdapterName)
Write-Host ("TARGET=" + $Target)
Write-Host ""

Write-Host "=== WLAN INTERFACE ==="
netsh wlan show interfaces
Write-Host ""

Write-Host "=== WLAN DRIVERS ==="
netsh wlan show drivers
Write-Host ""

Write-Host "=== NET ADAPTER ==="
Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue | Format-List Name,InterfaceDescription,Status,LinkSpeed,MacAddress,DriverInformation
Write-Host ""

Write-Host "=== POWER MANAGEMENT ==="
Get-NetAdapterPowerManagement -Name $AdapterName -ErrorAction SilentlyContinue | Format-List *
Write-Host ""

Write-Host "=== ADVANCED PROPERTIES ==="
Get-NetAdapterAdvancedProperty -Name $AdapterName -ErrorAction SilentlyContinue |
  Sort-Object DisplayName |
  Format-Table -AutoSize DisplayName,DisplayValue,RegistryKeyword
Write-Host ""

Write-Host "=== SURROUNDING APs / CHANNELS ==="
netsh wlan show networks mode=bssid
Write-Host ""

Write-Host "=== ARP TARGET ==="
arp -a | findstr $Target
Write-Host ""

Write-Host "=== ROUTE TARGET ==="
route print $Target
Write-Host ""

Write-Host "=== SHORT PING RECHECK ==="
ping -n 20 -w 1000 $Target
Write-Host ""

Write-Host "=== SURVEY RESULT ==="
Write-Host "WLAN_RF_SURVEY=COMPLETE"
Write-Host "NEXT=Return complete output for adapter power/driver/channel analysis."
exit 0
