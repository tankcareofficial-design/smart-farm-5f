param(
  [string]$Target = "192.168.4.1",
  [int]$PingCount = 30,
  [int]$HttpCount = 20
)

$ErrorActionPreference = "Continue"

Write-Host "=== FARMCART SMARTGROW R8.14 - AP LINK VS HTTP DIAGNOSTIC READONLY ==="
Write-Host "MODE=READ_ONLY"
Write-Host "ESP_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "RTC_WRITE=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host "FLASH_WRITE=NO"
Write-Host ("TARGET=" + $Target)
Write-Host ""

Write-Host "=== WLAN INTERFACE ==="
netsh wlan show interfaces
Write-Host ""

Write-Host "=== ROUTE TO TARGET ==="
route print $Target
Write-Host ""

Write-Host "=== PING TEST ==="
$pingPass = 0
$pingFail = 0
$pingTimes = @()

for ($i=1; $i -le $PingCount; $i++) {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $ok = Test-Connection -ComputerName $Target -Count 1 -Quiet -ErrorAction SilentlyContinue
  $sw.Stop()

  if ($ok) {
    $pingPass++
    $pingTimes += $sw.Elapsed.TotalMilliseconds
    Write-Host ("PING=" + $i + " RESULT=PASS WALL_MS=" + [Math]::Round($sw.Elapsed.TotalMilliseconds,1))
  } else {
    $pingFail++
    Write-Host ("PING=" + $i + " RESULT=FAIL")
  }
  Start-Sleep -Milliseconds 150
}

$pingAvg = if ($pingTimes.Count -gt 0) { ($pingTimes | Measure-Object -Average).Average } else { 0 }
$pingMax = if ($pingTimes.Count -gt 0) { ($pingTimes | Measure-Object -Maximum).Maximum } else { 0 }

Write-Host ""
Write-Host "=== CURL ROOT TEST ==="
$httpPass = 0
$httpFail = 0
$httpTimes = @()

for ($i=1; $i -le $HttpCount; $i++) {
  $tmp = [System.IO.Path]::GetTempFileName()
  $fmt = "%{http_code} %{time_connect} %{time_starttransfer} %{time_total}"
  $out = & curl.exe --noproxy "*" --silent --show-error --output $tmp --connect-timeout 1 --max-time 3 --write-out $fmt ("http://" + $Target + "/") 2>&1
  $rc = $LASTEXITCODE
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue

  if ($rc -eq 0) {
    $parts = ([string]$out).Trim().Split(" ")
    $code = if ($parts.Count -ge 1) { $parts[0] } else { "?" }
    $connect = if ($parts.Count -ge 2) { $parts[1] } else { "?" }
    $ttfb = if ($parts.Count -ge 3) { $parts[2] } else { "?" }
    $total = if ($parts.Count -ge 4) { $parts[3] } else { "?" }
    if ($code -eq "200") {
      $httpPass++
      try { $httpTimes += [double]::Parse($total,[Globalization.CultureInfo]::InvariantCulture) * 1000.0 } catch {}
      Write-Host ("HTTP=" + $i + " RESULT=PASS CODE=" + $code + " CONNECT_S=" + $connect + " TTFB_S=" + $ttfb + " TOTAL_S=" + $total)
    } else {
      $httpFail++
      Write-Host ("HTTP=" + $i + " RESULT=FAIL CODE=" + $code + " RAW=" + $out)
    }
  } else {
    $httpFail++
    Write-Host ("HTTP=" + $i + " RESULT=FAIL CURL_RC=" + $rc + " RAW=" + $out)
  }

  Start-Sleep -Milliseconds 250
}

$httpAvg = if ($httpTimes.Count -gt 0) { ($httpTimes | Measure-Object -Average).Average } else { 0 }
$httpMax = if ($httpTimes.Count -gt 0) { ($httpTimes | Measure-Object -Maximum).Maximum } else { 0 }

Write-Host ""
Write-Host "=== DIAGNOSTIC SUMMARY ==="
Write-Host ("PING_TOTAL=" + $PingCount)
Write-Host ("PING_PASS=" + $pingPass)
Write-Host ("PING_FAIL=" + $pingFail)
Write-Host ("PING_AVG_WALL_MS=" + [Math]::Round($pingAvg,1))
Write-Host ("PING_MAX_WALL_MS=" + [Math]::Round($pingMax,1))
Write-Host ("HTTP_TOTAL=" + $HttpCount)
Write-Host ("HTTP_PASS=" + $httpPass)
Write-Host ("HTTP_FAIL=" + $httpFail)
Write-Host ("HTTP_AVG_TOTAL_MS=" + [Math]::Round($httpAvg,1))
Write-Host ("HTTP_MAX_TOTAL_MS=" + [Math]::Round($httpMax,1))

if ($pingFail -eq 0 -and $httpFail -gt 0) {
  Write-Host "CLASSIFICATION=LINK_STABLE_HTTP_UNSTABLE"
  Write-Host "NEXT=Investigate ESP32 WebServer/main-loop service cadence."
  exit 71
}

if ($pingFail -gt 0) {
  Write-Host "CLASSIFICATION=AP_OR_RF_LINK_UNSTABLE"
  Write-Host "NEXT=Investigate AP signal/channel/client link before firmware HTTP patch."
  exit 72
}

Write-Host "CLASSIFICATION=LINK_AND_ROOT_HTTP_STABLE"
Write-Host "NEXT=Compare PowerShell client behavior and endpoint-specific load."
exit 0
