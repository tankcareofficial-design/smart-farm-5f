param(
  [string]$BaseUrl = "http://192.168.4.1",
  [string]$ExpectedFirmware = "0.8.0-5f-r8.14-stability-1",
  [string]$ExpectedHardwareProfile = "smart_farm_8ch_v1",
  [int]$TimeoutSec = 5
)

$ErrorActionPreference = "Stop"

function Get-JsonEndpoint([string]$Path) {
  $uri = $BaseUrl.TrimEnd("/") + $Path
  try {
    return Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec $TimeoutSec
  } catch {
    Write-Host ("HTTP_GET_FAIL=" + $Path)
    Write-Host ("HTTP_GET_ERROR=" + $_.Exception.Message)
    exit 21
  }
}

Write-Host "=== FARMCART SMARTGROW R8.14 - AP HTTP RUNTIME SMOKE READONLY ==="
Write-Host "MODE=AP_HTTP_RUNTIME_SMOKE_READONLY"
Write-Host "HTTP_METHOD=GET_ONLY"
Write-Host "ESP_WRITE=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "FLASH_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host ("BASE_URL=" + $BaseUrl)
Write-Host ""

$device = Get-JsonEndpoint "/api/device"
$state  = Get-JsonEndpoint "/api/state"
$relays = Get-JsonEndpoint "/api/relays"
$clock  = Get-JsonEndpoint "/api/v3/clock"

Write-Host "--- /api/device ---"
$device | ConvertTo-Json -Depth 8
Write-Host ""
Write-Host "--- /api/state ---"
$state | ConvertTo-Json -Depth 8
Write-Host ""
Write-Host "--- /api/relays ---"
$relays | ConvertTo-Json -Depth 8
Write-Host ""
Write-Host "--- /api/v3/clock ---"
$clock | ConvertTo-Json -Depth 8
Write-Host ""

$fail = $false

if ($device.firmwareVersion -eq $ExpectedFirmware) {
  Write-Host "FW_RUNTIME=PASS"
} else {
  Write-Host ("FW_RUNTIME=FAIL ACTUAL=" + $device.firmwareVersion)
  $fail = $true
}

if ($device.hardwareProfile -eq $ExpectedHardwareProfile) {
  Write-Host "HARDWARE_PROFILE_RUNTIME=PASS"
} else {
  Write-Host ("HARDWARE_PROFILE_RUNTIME=FAIL ACTUAL=" + $device.hardwareProfile)
  $fail = $true
}

if ([string]::IsNullOrWhiteSpace([string]$device.deviceId)) {
  Write-Host "DEVICE_ID_RUNTIME=FAIL_EMPTY"
  $fail = $true
} else {
  Write-Host ("DEVICE_ID_RUNTIME=PASS VALUE=" + $device.deviceId)
}

if ([int]$device.relayCount -eq 8) {
  Write-Host "RELAY_COUNT_RUNTIME=PASS"
} else {
  Write-Host ("RELAY_COUNT_RUNTIME=FAIL ACTUAL=" + $device.relayCount)
  $fail = $true
}

Write-Host ("PROVISIONING_CONFIGURED=" + $device.provisioningConfigured)
Write-Host ("PROVISIONING_STATE=" + $device.provisioningState)
Write-Host ("STATION_CONNECTED=" + $device.stationConnected)
Write-Host ("STATION_SSID=" + $device.stationSsid)
Write-Host ("STATION_IP=" + $device.stationIp)
Write-Host ("EMERGENCY_LATCHED=" + $device.emergencyLatched)
Write-Host ("UPTIME_MS=" + $device.uptimeMs)

$relayArray = @()
if ($null -ne $relays.relays) {
  $relayArray = @($relays.relays)
} elseif ($null -ne $state.relays) {
  $relayArray = @($state.relays)
}

if ($relayArray.Count -ne 8) {
  Write-Host ("RELAY_ARRAY=FAIL COUNT=" + $relayArray.Count)
  $fail = $true
} else {
  Write-Host "RELAY_ARRAY=PASS COUNT=8"
}

$onChannels = @()
for ($i = 0; $i -lt $relayArray.Count; $i++) {
  $on = [bool]$relayArray[$i].on
  $gpio = $relayArray[$i].gpio
  Write-Host ("RELAY_CH" + ($i+1) + "_ON=" + $on + " GPIO=" + $gpio)
  if ($on) { $onChannels += ($i + 1) }
}

if ($onChannels.Count -eq 0 -and $relayArray.Count -eq 8) {
  Write-Host "ALL_RELAYS_OFF=PASS"
} else {
  Write-Host ("ALL_RELAYS_OFF=FAIL ON_CHANNELS=" + ($onChannels -join ","))
  $fail = $true
}

$clockValid = $null
$clockQuality = ""
$clockError = ""
if ($null -ne $clock.clock) {
  $clockValid = $clock.clock.valid
  $clockQuality = [string]$clock.clock.quality
  $clockError = [string]$clock.clock.errorCode
} else {
  $clockValid = $clock.valid
  $clockQuality = [string]$clock.quality
  $clockError = [string]$clock.errorCode
}
Write-Host ("RTC_VALID=" + $clockValid)
Write-Host ("RTC_QUALITY=" + $clockQuality)
Write-Host ("RTC_ERROR=" + $clockError)

Write-Host ""
Write-Host "=== AP HTTP SMOKE RESULT ==="
if ($fail) {
  Write-Host "AP_HTTP_SMOKE=FAIL"
  Write-Host "RELAY_LOAD_POWER=KEEP_DISCONNECTED"
  Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
  Write-Host "RUNTIME_ACCEPTANCE=NOT_YET_PASS"
  exit 22
}

Write-Host "AP_HTTP_SMOKE=PASS"
Write-Host "RELAY_LOAD_POWER=KEEP_DISCONNECTED"
Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
Write-Host "RUNTIME_ACCEPTANCE=NOT_YET_PASS"
Write-Host "NEXT=Return this complete output before reconnecting relay load/pump power."
exit 0
