param(
  [string]$BaseUrl = "http://192.168.4.1",
  [string]$ExpectedFirmware = "0.8.0-5f-r8.14-stability-1",
  [string]$ExpectedHardwareProfile = "smart_farm_8ch_v1",
  [int]$TimeoutSec = 8
)

$ErrorActionPreference = "Stop"

function Get-JsonEndpoint([string]$Path) {
  $uri = $BaseUrl.TrimEnd("/") + $Path
  $lastError = $null
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
      Write-Host ("HTTP_GET=" + $Path + " TRY=" + $attempt)
      $result = Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec $TimeoutSec -DisableKeepAlive
      Write-Host ("HTTP_GET_PASS=" + $Path + " TRY=" + $attempt)
      Start-Sleep -Milliseconds 350
      return $result
    } catch {
      $lastError = $_.Exception.Message
      Write-Host ("HTTP_GET_RETRY=" + $Path + " TRY=" + $attempt + " ERROR=" + $lastError)
      Start-Sleep -Milliseconds 700
    }
  }
  Write-Host ("HTTP_GET_FAIL=" + $Path)
  Write-Host ("HTTP_GET_ERROR=" + $lastError)
  exit 31
}

Write-Host "=== FARMCART SMARTGROW R8.14 - RTC SYNC APPROVED ==="
Write-Host "MODE=RTC_SYNC_APPROVED"
Write-Host "RTC_WRITE=YES"
Write-Host "FLASH_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host "BASE_URL=$BaseUrl"
Write-Host ""

$device = Get-JsonEndpoint "/api/device"
$before = Get-JsonEndpoint "/api/v3/clock"

if ($device.firmwareVersion -ne $ExpectedFirmware) {
  Write-Host ("ERROR=FW_RUNTIME_MISMATCH ACTUAL=" + $device.firmwareVersion)
  exit 32
}
if ($device.hardwareProfile -ne $ExpectedHardwareProfile) {
  Write-Host ("ERROR=HARDWARE_PROFILE_MISMATCH ACTUAL=" + $device.hardwareProfile)
  exit 33
}
if ($null -eq $before.clock -or -not [bool]$before.clock.available -or [string]$before.clock.source -ne "ds3231") {
  Write-Host "ERROR=DS3231_NOT_AVAILABLE"
  $before | ConvertTo-Json -Depth 8
  exit 34
}

$nowOffset = [DateTimeOffset]::Now
$offsetMinutes = [int]$nowOffset.Offset.TotalMinutes
Write-Host ("PC_LOCAL_NOW=" + $nowOffset.ToString("yyyy-MM-ddTHH:mm:sszzz"))
Write-Host ("PC_UTC_OFFSET_MINUTES=" + $offsetMinutes)

if ($offsetMinutes -ne 420) {
  Write-Host "ERROR=PC_TIMEZONE_NOT_UTC_PLUS_7"
  Write-Host "RTC_WRITE=BLOCKED"
  exit 35
}

$now = [DateTime]::Now
$dotNetDow = [int]$now.DayOfWeek
$dayOfWeek = if ($dotNetDow -eq 0) { 7 } else { $dotNetDow }

$payload = [ordered]@{
  year      = $now.Year
  month     = $now.Month
  day       = $now.Day
  dayOfWeek = $dayOfWeek
  hour      = $now.Hour
  minute    = $now.Minute
  second    = $now.Second
}
$json = $payload | ConvertTo-Json -Compress

Write-Host ""
Write-Host "--- RTC BEFORE ---"
$before | ConvertTo-Json -Depth 8
Write-Host ("SYNC_PAYLOAD=" + $json)
Write-Host "DAY_OF_WEEK_CONVENTION=MONDAY_1_SUNDAY_7"
Write-Host ""

$postOk = $false
$postError = ""
try {
  Write-Host "HTTP_POST=/api/v3/clock/sync TRY=1"
  $post = Invoke-RestMethod -Method Post -Uri ($BaseUrl.TrimEnd("/") + "/api/v3/clock/sync") -Body $json -ContentType "application/json" -TimeoutSec $TimeoutSec -DisableKeepAlive
  $postOk = $true
  Write-Host "HTTP_POST_PASS=/api/v3/clock/sync TRY=1"
  Write-Host "--- RTC SYNC RESPONSE ---"
  $post | ConvertTo-Json -Depth 8
} catch {
  $postError = $_.Exception.Message
  Write-Host ("HTTP_POST_RESPONSE_UNCERTAIN=/api/v3/clock/sync ERROR=" + $postError)
  Write-Host "NOTE=No automatic POST retry; verifying RTC state by GET instead."
}

Start-Sleep -Milliseconds 900
$after = Get-JsonEndpoint "/api/v3/clock"

Write-Host ""
Write-Host "--- RTC AFTER ---"
$after | ConvertTo-Json -Depth 8

$clock = $after.clock
$fail = $false

if ($null -eq $clock) {
  Write-Host "RTC_CLOCK_OBJECT=FAIL"
  $fail = $true
} else {
  if ([bool]$clock.available) { Write-Host "RTC_AVAILABLE=PASS" } else { Write-Host "RTC_AVAILABLE=FAIL"; $fail = $true }
  if ([string]$clock.source -eq "ds3231") { Write-Host "RTC_SOURCE=PASS" } else { Write-Host ("RTC_SOURCE=FAIL ACTUAL=" + $clock.source); $fail = $true }
  if ([bool]$clock.valid) { Write-Host "RTC_VALID=PASS" } else { Write-Host ("RTC_VALID=FAIL ACTUAL=" + $clock.valid); $fail = $true }
  if (-not [bool]$clock.lostPower) { Write-Host "RTC_LOST_POWER=CLEARED_PASS" } else { Write-Host "RTC_LOST_POWER=FAIL_STILL_SET"; $fail = $true }
  if ([bool]$clock.synchronized) { Write-Host "RTC_SYNCHRONIZED=PASS" } else { Write-Host "RTC_SYNCHRONIZED=FAIL"; $fail = $true }
  if ([int]$clock.readFailures -eq 0) { Write-Host "RTC_READ_FAILURES=PASS_0" } else { Write-Host ("RTC_READ_FAILURES=FAIL ACTUAL=" + $clock.readFailures); $fail = $true }
  if ([string]$clock.errorCode -eq "none") { Write-Host "RTC_ERROR_CODE=PASS_NONE" } else { Write-Host ("RTC_ERROR_CODE=FAIL ACTUAL=" + $clock.errorCode); $fail = $true }

  try {
    $rtcTime = New-Object DateTime ([int]$clock.year),([int]$clock.month),([int]$clock.day),([int]$clock.hour),([int]$clock.minute),([int]$clock.second)
    $pcVerify = [DateTime]::Now
    $delta = [Math]::Abs(($pcVerify - $rtcTime).TotalSeconds)
    Write-Host ("RTC_PC_DELTA_SECONDS=" + [Math]::Round($delta, 1))
    if ($delta -le 5) {
      Write-Host "RTC_TIME_MATCH=PASS"
    } else {
      Write-Host "RTC_TIME_MATCH=FAIL_GT_5S"
      $fail = $true
    }
  } catch {
    Write-Host ("RTC_TIME_PARSE=FAIL " + $_.Exception.Message)
    $fail = $true
  }
}

Write-Host ""
Write-Host "=== RTC SYNC RESULT ==="
if ($fail) {
  Write-Host "RTC_SYNC=FAIL"
  Write-Host ("POST_RESPONSE_RECEIVED=" + $postOk)
  if ($postError) { Write-Host ("POST_ERROR=" + $postError) }
  Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
  Write-Host "RUNTIME_ACCEPTANCE=NOT_YET_PASS"
  exit 36
}

Write-Host "RTC_SYNC=PASS"
Write-Host ("POST_RESPONSE_RECEIVED=" + $postOk)
Write-Host "FLASH_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
Write-Host "RUNTIME_ACCEPTANCE=NOT_YET_PASS"
Write-Host "NEXT=Return this complete output for RTC acceptance review."
exit 0
