# R8.14 no-load Schedule / Condition Save readback.
# HTTP GET ONLY. Never changes ESP32, NVS, RTC, relays, Wi-Fi, app, or main.
# Windows PowerShell 5.1 compatible. Run while connected to FarmCart AP or LAN.
param(
  [ValidateSet('Preflight', 'Schedule', 'Condition', 'Final')]
  [string]$Stage = 'Preflight',
  [string]$BaseUrl = 'http://192.168.4.1',
  [string]$TestName = 'FarmCart QA TEMP',
  [string]$StartTime = '06:00',
  [string]$EndTime = '06:15'
)
$ErrorActionPreference = 'Stop'
$ExpectedController = 'sf-64B9509FC114'
$ExpectedFirmware = '0.8.0-5f-r8.14-stability-1'
$ExpectedGpio = @(4, 5, 6, 7, 15, 16, 17, 18)
function ReadEndpoint([string]$Path) {
  $uri = $BaseUrl.TrimEnd('/') + $Path
  Write-Host ('HTTP_GET=' + $Path)
  return Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec 7 -DisableKeepAlive
}
function Check([bool]$Ok, [string]$Reason) {
  if (-not $Ok) { throw $Reason }
}
Write-Host '=== FARMCART R8.14 - PROFILE SAVE READBACK ==='
Write-Host 'MODE=READ_ONLY_GET_ONLY'
Write-Host ('STAGE=' + $Stage)
Write-Host 'POST=NO NVS_WRITE=NO RTC_WRITE=NO RELAY_COMMAND=NO FLASH=NO'
try {
  $device = ReadEndpoint '/api/device'
  $relayData = ReadEndpoint '/api/relays'
  $snapshot = ReadEndpoint '/api/v3/snapshot'
  Check ($device.deviceId -eq $ExpectedController) 'CONTROLLER_ID_MISMATCH'
  Check ($device.firmwareVersion -eq $ExpectedFirmware) 'FIRMWARE_MISMATCH'
  Check ([int]$device.relayCount -eq 8) 'RELAY_COUNT_MISMATCH'
  Check ($device.hardwareProfile -eq 'smart_farm_8ch_v1') 'HARDWARE_PROFILE_MISMATCH'
  Check ($snapshot.controllerId -eq $ExpectedController) 'SNAPSHOT_CONTROLLER_ID_MISMATCH'
  Check ($snapshot.sourceOfTruth -eq 'esp32') 'SNAPSHOT_NOT_CONTROLLER_AUTHORITY'
  Check (-not [bool]$device.emergencyLatched) 'ESTOP_LATCHED_STOP'
  $relays = @($relayData.relays)
  Check ($relays.Count -eq 8) 'RELAY_ARRAY_MISMATCH'
  $on = @($relays | Where-Object { [bool]$_.on })
  $rules = @($snapshot.rules | Where-Object { $null -ne $_ })
  $tempRules = @($rules | Where-Object { $_.name -eq $TestName })
  $assigned = @()
  for ($i = 0; $i -lt 8; $i++) {
    Check ([int]$relays[$i].gpio -eq $ExpectedGpio[$i]) ('RELAY_GPIO_MISMATCH_CH' + ($i+1))
  }
  Write-Host ('CONTROLLER=' + $device.deviceId)
  Write-Host ('FIRMWARE=' + $device.firmwareVersion)
  Write-Host ('RELAY_ON_COUNT=' + $on.Count)
  Write-Host ('SNAPSHOT_REVISION=' + $snapshot.revision)
  Write-Host ('RULE_COUNT=' + $rules.Count)
  Write-Host ('RTC_VALID=' + $snapshot.clock.valid)
  Write-Host ('RTC_QUALITY=' + $snapshot.clock.quality)
  Write-Host ('RTC_LOCAL_TIME=' + $snapshot.clock.dateTimeLocal)
  for ($i = 0; $i -lt $rules.Count; $i++) {
    $rule = $rules[$i]
    $actions = @($rule.actions | Where-Object { $null -ne $_ })
    $channelIndex = -1
    if ($actions.Count -gt 0) {
      $channelIndex = [int]$actions[0].relayChannel
      if ($channelIndex -ge 0 -and $channelIndex -lt 8) { $assigned += $channelIndex }
    }
    Write-Host ('RULE' + ($i+1) + '_NAME=' + $rule.name)
    Write-Host ('RULE' + ($i+1) + '_DEVICE_ID=' + $rule.deviceId)
    Write-Host ('RULE' + ($i+1) + '_CHANNEL=' + $(if ($channelIndex -ge 0) {$channelIndex+1} else {'UNKNOWN'}))
  }
  $free = @()
  for ($i = 0; $i -lt 8; $i++) {
    if ($assigned -notcontains $i) { $free += ($i + 1) }
  }
  Write-Host ('FREE_CHANNELS=' + ($free -join ','))
  Write-Host ('TEST_PROFILE_MATCH_COUNT=' + $tempRules.Count)
  Check ($on.Count -eq 0) 'ABORT_RELAY_NOT_ALL_OFF'
  Check ($tempRules.Count -le 1) 'ABORT_DUPLICATE_TEST_PROFILES'
  if ($Stage -eq 'Preflight') {
    Check ($tempRules.Count -eq 0) 'ABORT_TEST_PROFILE_ALREADY_EXISTS'
    Check ($free.Count -gt 0) 'ABORT_NO_FREE_CHANNEL'
    if ([bool]$snapshot.clock.valid -and -not [string]::IsNullOrWhiteSpace([string]$snapshot.clock.dateTimeLocal)) {
      try {
        $t = [DateTime]::Parse([string]$snapshot.clock.dateTimeLocal)
        $nowMinutes = $t.Hour * 60 + $t.Minute
        $a = [DateTime]::ParseExact($StartTime, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
        $b = [DateTime]::ParseExact($EndTime, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
        $start = $a.Hour * 60 + $a.Minute
        $end = $b.Hour * 60 + $b.Minute
        Check ($start -ne $end) 'ABORT_INVALID_TEST_WINDOW'
        $inside = if ($start -lt $end) { $nowMinutes -ge $start -and $nowMinutes -lt $end } else { $nowMinutes -ge $start -or $nowMinutes -lt $end }
        Check (-not $inside) 'ABORT_TEST_WINDOW_ACTIVE_ON_CONTROLLER_CLOCK'
      } catch [System.FormatException] { throw 'ABORT_CANNOT_PARSE_RTC_TIME' }
    }
    Write-Host 'PREFLIGHT=PASS'
    Write-Host 'NEXT=Create one disposable Manual device on a free channel, then edit Schedule outside RTC window.'
  } elseif ($Stage -eq 'Schedule') {
    Check ($tempRules.Count -eq 1) 'FAIL_NO_SINGLE_SAVED_TEST_PROFILE'
    $rule = $tempRules[0]
    Check ($rule.controlMode -eq 'schedule') 'FAIL_CONTROL_MODE_NOT_SCHEDULE'
    Check ([bool]$rule.enabled) 'FAIL_RULE_NOT_ENABLED'
    $s = $rule.trigger.schedule
    Check ([bool]$s.enabled) 'FAIL_SCHEDULE_DISABLED'
    $expectedA = [DateTime]::ParseExact($StartTime, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
    $expectedB = [DateTime]::ParseExact($EndTime, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
    Check ([int]$s.hour -eq $expectedA.Hour -and [int]$s.minute -eq $expectedA.Minute) 'FAIL_START_TIME_MISMATCH'
    Check ([int]$s.endHour -eq $expectedB.Hour -and [int]$s.endMinute -eq $expectedB.Minute) 'FAIL_END_TIME_MISMATCH'
    $days = @($s.daysOfWeek | ForEach-Object { [int]$_ } | Sort-Object)
    Check (($days -join ',') -eq '1,2,3,4,5,6,7') 'FAIL_DAYS_OF_WEEK_MISMATCH'
    Write-Host ('SCHEDULE_DEVICE_ID=' + $rule.deviceId)
    Write-Host ('SCHEDULE_START=' + $StartTime)
    Write-Host ('SCHEDULE_END=' + $EndTime)
    Write-Host 'SCHEDULE_SNAPSHOT_PERSISTENCE=PASS'
    Write-Host 'APP_REOPEN_CONFIRMATION=USER_REQUIRED'
  } elseif ($Stage -eq 'Condition') {
    Check ($tempRules.Count -eq 1) 'FAIL_NO_SINGLE_SAVED_TEST_PROFILE'
    $rule = $tempRules[0]
    Check ($rule.controlMode -eq 'automatic') 'FAIL_CONTROL_MODE_NOT_AUTOMATIC'
    $conditions = @($rule.conditions | Where-Object { $null -ne $_ })
    Check ($conditions.Count -ge 1) 'FAIL_NO_SAVED_CONDITION'
    $c = $conditions[0]
    Check (-not [string]::IsNullOrWhiteSpace([string]$c.sensorId)) 'FAIL_SENSOR_ID_EMPTY'
    Check (@('soil_moisture','temperature','humidity') -contains [string]$c.metric) 'FAIL_UNSUPPORTED_METRIC'
    Check (@('<','<=','>','>=','between','outside') -contains [string]$c.operator) 'FAIL_UNSUPPORTED_OPERATOR'
    Write-Host ('CONDITION_DEVICE_ID=' + $rule.deviceId)
    Write-Host ('CONDITION_SENSOR_ID=' + $c.sensorId)
    Write-Host ('CONDITION_METRIC=' + $c.metric)
    Write-Host ('CONDITION_OPERATOR=' + $c.operator)
    Write-Host ('CONDITION_START_VALUE=' + $c.value)
    Write-Host ('CONDITION_STOP_VALUE=' + $c.valueHigh)
    Write-Host 'CONDITION_SNAPSHOT_PERSISTENCE=PASS'
    Write-Host 'APP_REOPEN_CONFIRMATION=USER_REQUIRED'
  } else {
    Check ($tempRules.Count -eq 0) 'FAIL_TEST_PROFILE_NOT_DELETED'
    Write-Host 'FINAL_TEST_PROFILE_ABSENT_BY_NAME=PASS'
    Write-Host 'FINAL_ALL_RELAYS_OFF=PASS'
    Write-Host 'POST_REBOOT_NVS_RETENTION=NOT_TESTED'
  }
  Write-Host 'RUNTIME_GATE=SNAPSHOT_ONLY_PHYSICAL_APP_CONFIRMATION_REQUIRED'
  exit 0
} catch {
  Write-Host ('RESULT=FAIL_OR_BLOCKED REASON=' + $_.Exception.Message)
  Write-Host 'SAFETY=DO_NOT_RETRY_UNCERTAIN_SAVES_OR_CONNECT_EXTERNAL_LOAD'
  exit 41
}
