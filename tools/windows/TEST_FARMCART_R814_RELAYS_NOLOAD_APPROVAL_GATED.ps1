param(
  [string]$BaseUrl = "http://192.168.4.1",
  [int]$TimeoutSec = 6,
  [int]$OnHoldMilliseconds = 1500
)

$ErrorActionPreference = "Stop"
$ExpectedFirmware = "0.8.0-5f-r8.14-stability-1"
$ExpectedProfile = "smart_farm_8ch_v1"
$ExpectedGpio = @(4,5,6,7,15,16,17,18)

function Invoke-GetJson([string]$Path) {
  $uri = $BaseUrl.TrimEnd("/") + $Path
  $last = $null
  for ($attempt=1; $attempt -le 3; $attempt++) {
    try {
      Write-Host ("HTTP_GET=" + $Path + " TRY=" + $attempt)
      $r = Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec $TimeoutSec -DisableKeepAlive
      Write-Host ("HTTP_GET_PASS=" + $Path + " TRY=" + $attempt)
      return $r
    } catch {
      $last = $_.Exception.Message
      Write-Host ("HTTP_GET_RETRY=" + $Path + " TRY=" + $attempt + " ERROR=" + $last)
      Start-Sleep -Milliseconds 600
    }
  }
  throw ("GET failed " + $Path + ": " + $last)
}

function Invoke-PostOnce([string]$Path, [object]$Body) {
  $uri = $BaseUrl.TrimEnd("/") + $Path
  $json = $Body | ConvertTo-Json -Compress
  try {
    Write-Host ("HTTP_POST=" + $Path + " BODY=" + $json)
    $r = Invoke-RestMethod -Method Post -Uri $uri -Body $json -ContentType "application/json" -TimeoutSec $TimeoutSec -DisableKeepAlive
    Write-Host ("HTTP_POST_RESPONSE=RECEIVED PATH=" + $Path)
    return [pscustomobject]@{ ResponseReceived=$true; Response=$r; Error="" }
  } catch {
    $msg = $_.Exception.Message
    Write-Host ("HTTP_POST_RESPONSE=UNCERTAIN PATH=" + $Path + " ERROR=" + $msg)
    return [pscustomobject]@{ ResponseReceived=$false; Response=$null; Error=$msg }
  }
}

function Get-RelayState([int]$Channel) {
  $r = Invoke-GetJson "/api/relays"
  $arr = @($r.relays)
  if ($arr.Count -ne 8) { throw ("relay array count=" + $arr.Count) }
  return [pscustomobject]@{
    Root=$r
    Relay=$arr[$Channel]
    All=$arr
  }
}

function Invoke-EmergencyStop {
  Write-Host ""
  Write-Host "FAILSAFE=EMERGENCY_STOP_REQUEST"
  try {
    $null = Invoke-RestMethod -Method Post -Uri ($BaseUrl.TrimEnd("/") + "/api/emergency-stop") -Body "{}" -ContentType "application/json" -TimeoutSec $TimeoutSec -DisableKeepAlive
    Write-Host "FAILSAFE_POST=RESPONSE_RECEIVED"
  } catch {
    Write-Host ("FAILSAFE_POST=RESPONSE_UNCERTAIN ERROR=" + $_.Exception.Message)
  }

  Start-Sleep -Milliseconds 400
  try {
    $r = Invoke-GetJson "/api/relays"
    $arr = @($r.relays)
    $on = @($arr | Where-Object { [bool]$_.on })
    Write-Host ("FAILSAFE_EMERGENCY_LATCHED=" + $r.emergencyLatched)
    Write-Host ("FAILSAFE_ON_CHANNEL_COUNT=" + $on.Count)
    if ($on.Count -eq 0) {
      Write-Host "FAILSAFE_ALL_RELAYS_OFF=PASS"
    } else {
      Write-Host "FAILSAFE_ALL_RELAYS_OFF=FAIL"
    }
  } catch {
    Write-Host ("FAILSAFE_VERIFY=UNAVAILABLE ERROR=" + $_.Exception.Message)
  }
}

Write-Host "=== FARMCART SMARTGROW R8.14 - RELAY NO-LOAD HARDWARE TEST ==="
Write-Host "MODE=RELAY_NOLOAD_APPROVED"
Write-Host "RELAY_COMMAND=YES"
Write-Host "PUMP_LOAD_POWER=REQUIRED_DISCONNECTED"
Write-Host "FLASH_WRITE=NO"
Write-Host "RTC_WRITE=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host ("BASE_URL=" + $BaseUrl)
Write-Host ""

$failure = $false
$failureReason = ""

try {
  $device = Invoke-GetJson "/api/device"
  $pre = Invoke-GetJson "/api/relays"

  if ($device.firmwareVersion -ne $ExpectedFirmware) { throw "firmware mismatch" }
  if ($device.hardwareProfile -ne $ExpectedProfile) { throw "hardware profile mismatch" }
  if ([int]$device.relayCount -ne 8) { throw "relay count mismatch" }
  if ([bool]$pre.emergencyLatched) {
    Write-Host "PREFLIGHT_EMERGENCY_LATCHED=True"
    Write-Host "PREFLIGHT_ACTION=RELEASE_EMERGENCY_FOR_APPROVED_NOLOAD_RETEST"
    $release = Invoke-PostOnce "/api/emergency-release" ([ordered]@{})
    Start-Sleep -Milliseconds 400
    $pre = Invoke-GetJson "/api/relays"
    if ([bool]$pre.emergencyLatched) { throw "emergency stop release did not clear latch" }
    Write-Host "PREFLIGHT_EMERGENCY_RELEASE=PASS"
  } else {
    Write-Host "PREFLIGHT_EMERGENCY_LATCHED=False"
  }

  $preRelays = @($pre.relays)
  if ($preRelays.Count -ne 8) { throw "preflight relay array count mismatch" }

  for ($i=0; $i -lt 8; $i++) {
    if ([bool]$preRelays[$i].on) { throw ("preflight relay CH" + ($i+1) + " is ON") }
    if ([int]$preRelays[$i].gpio -ne $ExpectedGpio[$i]) { throw ("GPIO mismatch CH" + ($i+1)) }
  }

  Write-Host "PREFLIGHT_ALL_RELAYS_OFF=PASS"
  Write-Host "PREFLIGHT_GPIO_MAP=PASS"
  Write-Host ""

  for ($ch=0; $ch -lt 8; $ch++) {
    $human = $ch + 1
    $gpio = $ExpectedGpio[$ch]

    Write-Host ("=== TEST CH" + $human + " GPIO" + $gpio + " ===")
    Write-Host ("OBSERVE=Relay CH" + $human + " LED/click should turn ON, then OFF")

    $null = Invoke-PostOnce "/api/relay" ([ordered]@{channel=$ch;on=$true;overrideSeconds=45})
    Start-Sleep -Milliseconds 250
    $onState = Get-RelayState $ch

    if (-not [bool]$onState.Relay.on) {
      throw ("CH" + $human + " failed to verify ON")
    }
    Write-Host ("CH" + $human + "_ON_API=PASS")
    Write-Host ("CH" + $human + "_ON_OVERRIDE_SECONDS=45")
    Write-Host ("CH" + $human + "_GPIO=" + $onState.Relay.gpio)

    Start-Sleep -Milliseconds $OnHoldMilliseconds

    $null = Invoke-PostOnce "/api/relay" ([ordered]@{channel=$ch;on=$false;overrideSeconds=2})
    Start-Sleep -Milliseconds 250
    $offState = Get-RelayState $ch

    if ([bool]$offState.Relay.on) {
      throw ("CH" + $human + " failed to verify OFF")
    }
    Write-Host ("CH" + $human + "_OFF_API=PASS")
    Write-Host ("CH" + $human + "_TEST=PASS")
    Write-Host ""
    Start-Sleep -Milliseconds 500
  }

  Start-Sleep -Seconds 3
  $final = Invoke-GetJson "/api/relays"
  $finalRelays = @($final.relays)
  $onFinal = @($finalRelays | Where-Object { [bool]$_.on })
  $activeOverrides = @($final.manualOverrides | Where-Object { [bool]$_.active })

  Write-Host ("FINAL_ON_CHANNEL_COUNT=" + $onFinal.Count)
  Write-Host ("FINAL_ACTIVE_OVERRIDE_COUNT=" + $activeOverrides.Count)
  Write-Host ("FINAL_EMERGENCY_LATCHED=" + $final.emergencyLatched)

  if ($onFinal.Count -ne 0) { throw "one or more relays remain ON" }
  if ($activeOverrides.Count -ne 0) { throw "one or more manual overrides remain active" }

  Write-Host ""
  Write-Host "=== RELAY NO-LOAD RESULT ==="
  Write-Host "RELAY_NOLOAD_API_SEQUENCE=PASS"
  Write-Host "ALL_RELAYS_OFF_FINAL=PASS"
  Write-Host "ALL_OVERRIDES_CLEARED_FINAL=PASS"
  Write-Host "PHYSICAL_LED_CLICK_CONFIRMATION=USER_OBSERVATION_REQUIRED"
  Write-Host "PUMP_LOAD_POWER=KEEP_DISCONNECTED"
  Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
  Write-Host "NEXT=Return complete output and report whether CH1-CH8 physically clicked/lit in order."
  exit 0
}
catch {
  $failure = $true
  $failureReason = $_.Exception.Message
  Write-Host ""
  Write-Host ("RELAY_TEST_ERROR=" + $failureReason)
  Invoke-EmergencyStop
  Write-Host ""
  Write-Host "=== RELAY NO-LOAD RESULT ==="
  Write-Host "RELAY_NOLOAD_API_SEQUENCE=FAIL"
  Write-Host "FAILSAFE=EMERGENCY_STOP_ATTEMPTED"
  Write-Host "PUMP_LOAD_POWER=KEEP_DISCONNECTED"
  Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
  Write-Host "NEXT=Return complete output. Do not release emergency stop or connect load."
  exit 51
}
