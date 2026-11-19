param(
  [string]$BaseUrl = "http://192.168.4.1",
  [int]$Samples = 5,
  [int]$IntervalSeconds = 2,
  [int]$TimeoutSec = 6,
  [double]$MaxDeltaSeconds = 5.0
)

$ErrorActionPreference = "Stop"

function Get-ClockSample([int]$Index) {
  $uri = $BaseUrl.TrimEnd("/") + "/api/v3/clock"
  $lastError = $null

  for ($attempt = 1; $attempt -le 3; $attempt++) {
    $start = [DateTime]::Now
    try {
      Write-Host ("RTC_GET_SAMPLE=" + $Index + " TRY=" + $attempt)
      $response = Invoke-RestMethod -Method Get -Uri $uri -TimeoutSec $TimeoutSec -DisableKeepAlive
      $end = [DateTime]::Now
      $mid = $start.AddTicks([int64](($end.Ticks - $start.Ticks) / 2))
      $rttMs = ($end - $start).TotalMilliseconds

      if ($null -eq $response.clock) { throw "Missing clock object" }
      $c = $response.clock

      $rtc = New-Object DateTime ([int]$c.year),([int]$c.month),([int]$c.day),([int]$c.hour),([int]$c.minute),([int]$c.second)
      $delta = ($rtc - $mid).TotalSeconds

      return [pscustomobject]@{
        Index = $Index
        Start = $start
        End = $end
        Mid = $mid
        RttMs = $rttMs
        Clock = $c
        Rtc = $rtc
        DeltaSeconds = $delta
      }
    } catch {
      $lastError = $_.Exception.Message
      Write-Host ("RTC_GET_RETRY=" + $Index + " TRY=" + $attempt + " ERROR=" + $lastError)
      Start-Sleep -Milliseconds 700
    }
  }

  throw ("RTC sample failed after retries: " + $lastError)
}

Write-Host "=== FARMCART SMARTGROW R8.14 - RTC VERIFY READONLY ==="
Write-Host "MODE=RTC_VERIFY_READONLY"
Write-Host "HTTP_METHOD=GET_ONLY"
Write-Host "RTC_WRITE=NO"
Write-Host "FLASH_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host ("BASE_URL=" + $BaseUrl)
Write-Host ("SAMPLES=" + $Samples)
Write-Host ("INTERVAL_SECONDS=" + $IntervalSeconds)
Write-Host ("MAX_DELTA_SECONDS=" + $MaxDeltaSeconds)
Write-Host ""

$offsetMinutes = [int]([DateTimeOffset]::Now.Offset.TotalMinutes)
Write-Host ("PC_UTC_OFFSET_MINUTES=" + $offsetMinutes)
if ($offsetMinutes -ne 420) {
  Write-Host "RTC_VERIFY=FAIL"
  Write-Host "ERROR=PC_TIMEZONE_NOT_UTC_PLUS_7"
  exit 41
}

$results = @()
for ($i = 1; $i -le $Samples; $i++) {
  try {
    $s = Get-ClockSample $i
  } catch {
    Write-Host ("RTC_VERIFY=FAIL ERROR=" + $_.Exception.Message)
    exit 42
  }

  $c = $s.Clock
  Write-Host ("SAMPLE_" + $i + "_RTC=" + $s.Rtc.ToString("yyyy-MM-ddTHH:mm:ss"))
  Write-Host ("SAMPLE_" + $i + "_PC_MID=" + $s.Mid.ToString("yyyy-MM-ddTHH:mm:ss.fff"))
  Write-Host ("SAMPLE_" + $i + "_RTT_MS=" + [Math]::Round($s.RttMs,1))
  Write-Host ("SAMPLE_" + $i + "_DELTA_SECONDS=" + [Math]::Round($s.DeltaSeconds,3))
  Write-Host ("SAMPLE_" + $i + "_AVAILABLE=" + $c.available)
  Write-Host ("SAMPLE_" + $i + "_VALID=" + $c.valid)
  Write-Host ("SAMPLE_" + $i + "_QUALITY=" + $c.quality)
  Write-Host ("SAMPLE_" + $i + "_LOST_POWER=" + $c.lostPower)
  Write-Host ("SAMPLE_" + $i + "_SYNCHRONIZED=" + $c.synchronized)
  Write-Host ("SAMPLE_" + $i + "_READ_FAILURES=" + $c.readFailures)
  Write-Host ("SAMPLE_" + $i + "_ERROR=" + $c.errorCode)
  Write-Host ""

  $results += $s
  if ($i -lt $Samples) { Start-Sleep -Seconds $IntervalSeconds }
}

$fail = $false
$maxAbsDelta = 0.0

foreach ($s in $results) {
  $c = $s.Clock
  if (-not [bool]$c.available) { $fail = $true }
  if (-not [bool]$c.valid) { $fail = $true }
  if ([string]$c.source -ne "ds3231") { $fail = $true }
  if ([bool]$c.lostPower) { $fail = $true }
  if ([int]$c.readFailures -ne 0) { $fail = $true }
  if ([string]$c.errorCode -ne "none") { $fail = $true }

  $abs = [Math]::Abs($s.DeltaSeconds)
  if ($abs -gt $maxAbsDelta) { $maxAbsDelta = $abs }
  if ($abs -gt $MaxDeltaSeconds) { $fail = $true }
}

$monotonic = $true
for ($i = 1; $i -lt $results.Count; $i++) {
  $rtcAdvance = ($results[$i].Rtc - $results[$i-1].Rtc).TotalSeconds
  $pcAdvance = ($results[$i].Mid - $results[$i-1].Mid).TotalSeconds
  Write-Host ("STEP_" + $i + "_RTC_ADVANCE_SECONDS=" + [Math]::Round($rtcAdvance,3))
  Write-Host ("STEP_" + $i + "_PC_ADVANCE_SECONDS=" + [Math]::Round($pcAdvance,3))

  if ($rtcAdvance -le 0) {
    $monotonic = $false
    $fail = $true
  }
}

Write-Host ("RTC_MAX_ABS_DELTA_SECONDS=" + [Math]::Round($maxAbsDelta,3))
Write-Host ("RTC_MONOTONIC=" + $monotonic)

Write-Host ""
Write-Host "=== RTC VERIFY RESULT ==="
if ($fail) {
  Write-Host "RTC_VERIFY=FAIL"
  Write-Host "RTC_WRITE=NO"
  Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
  Write-Host "RUNTIME_ACCEPTANCE=NOT_YET_PASS"
  Write-Host "NEXT=Return this complete output. Do not resync automatically."
  exit 43
}

Write-Host "RTC_VERIFY=PASS"
Write-Host "RTC_ACCURACY=PASS"
Write-Host "RTC_CONTINUITY=PASS"
Write-Host "RTC_WRITE=NO"
Write-Host "HARDWARE_ACCEPTANCE=NOT_YET_PASS"
Write-Host "RUNTIME_ACCEPTANCE=NOT_YET_PASS"
Write-Host "NEXT=Proceed to 10-minute RTC/controller stability observation."
exit 0
