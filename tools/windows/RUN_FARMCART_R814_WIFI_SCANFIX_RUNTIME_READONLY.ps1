param(
  [string]$BaseUrl = "http://192.168.4.1",
  [int]$MaxPolls = 30,
  [int]$PollDelayMs = 350,
  [int]$TimeoutSec = 3
)

$ErrorActionPreference = "Stop"

function Get-Json([string]$Path) {
  $uri = $BaseUrl.TrimEnd("/") + $Path
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Method Get -Uri $uri -TimeoutSec $TimeoutSec -DisableKeepAlive
    $sw.Stop()
    return [pscustomobject]@{
      Ok = ($r.StatusCode -eq 200)
      Status = [int]$r.StatusCode
      Ms = $sw.Elapsed.TotalMilliseconds
      Json = ($r.Content | ConvertFrom-Json)
      Error = ""
    }
  } catch {
    $sw.Stop()
    return [pscustomobject]@{
      Ok = $false
      Status = 0
      Ms = $sw.Elapsed.TotalMilliseconds
      Json = $null
      Error = $_.Exception.Message
    }
  }
}

Write-Host "=== FARMCART R8.14 WIFI SCAN-FIX RUNTIME READONLY ==="
Write-Host "MODE=READ_ONLY"
Write-Host "HTTP_METHOD=GET_ONLY"
Write-Host "ESP_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host "FLASH_WRITE=NO"
Write-Host ("BASE_URL=" + $BaseUrl)
Write-Host ("MAX_POLLS=" + $MaxPolls)
Write-Host ("POLL_DELAY_MS=" + $PollDelayMs)
Write-Host ""

$device = Get-Json "/api/device"
if (-not $device.Ok) {
  Write-Host ("DEVICE_HTTP=FAIL STATUS=" + $device.Status + " RTT_MS=" + [Math]::Round($device.Ms,1) + " ERROR=" + $device.Error)
  Write-Host "WIFI_SCANFIX_RUNTIME=BLOCKED_NOT_CONNECTED_TO_SMARTFARM_AP"
  exit 71
}
Write-Host ("DEVICE_HTTP=PASS STATUS=" + $device.Status + " RTT_MS=" + [Math]::Round($device.Ms,1))
Write-Host ("FIRMWARE=" + $device.Json.firmwareVersion)
Write-Host ("DEVICE_ID=" + $device.Json.deviceId)

$complete = $false
$httpResponsiveDuringScan = $true
$final = $null

for ($i = 1; $i -le $MaxPolls; $i++) {
  $scan = Get-Json "/api/wifi/scan"
  if (-not $scan.Ok) {
    Write-Host ("SCAN_POLL=" + $i + " RESULT=HTTP_FAIL STATUS=" + $scan.Status + " RTT_MS=" + [Math]::Round($scan.Ms,1) + " ERROR=" + $scan.Error)
    Write-Host "WIFI_SCANFIX_RUNTIME=FAIL_HTTP"
    exit 72
  }

  $state = [string]$scan.Json.scanState
  $scanning = [bool]$scan.Json.scanning
  $count = if ($null -ne $scan.Json.count) { [int]$scan.Json.count } else { -1 }
  Write-Host ("SCAN_POLL=" + $i + " RESULT=PASS STATE=" + $state + " SCANNING=" + $scanning + " COUNT=" + $count + " RTT_MS=" + [Math]::Round($scan.Ms,1))

  if ($state -eq "complete" -and -not $scanning) {
    $complete = $true
    $final = $scan.Json
    break
  }

  if ($state -ne "scanning" -or -not $scanning) {
    Write-Host "WIFI_SCANFIX_RUNTIME=FAIL_BAD_ASYNC_STATE"
    exit 73
  }

  $health = Get-Json "/api/device"
  if (-not $health.Ok) {
    $httpResponsiveDuringScan = $false
    Write-Host ("HTTP_DURING_SCAN=FAIL POLL=" + $i + " ERROR=" + $health.Error)
    break
  } else {
    Write-Host ("HTTP_DURING_SCAN=PASS POLL=" + $i + " RTT_MS=" + [Math]::Round($health.Ms,1))
  }

  Start-Sleep -Milliseconds $PollDelayMs
}

if (-not $httpResponsiveDuringScan) {
  Write-Host "WIFI_SCANFIX_RUNTIME=FAIL_HTTP_STALLED_DURING_SCAN"
  exit 74
}
if (-not $complete) {
  Write-Host "WIFI_SCANFIX_RUNTIME=FAIL_SCAN_TIMEOUT"
  exit 75
}

Write-Host ""
Write-Host "--- FINAL NETWORK LIST ---"
$nets = @($final.networks)
Write-Host ("FINAL_COUNT=" + $nets.Count)
foreach ($n in $nets) {
  Write-Host ("SSID=" + [string]$n.ssid + " RSSI=" + [string]$n.rssi + " CHANNEL=" + [string]$n.channel + " SECURE=" + [string]$n.secure)
}

$post = Get-Json "/api/device"
if (-not $post.Ok) {
  Write-Host ("POST_SCAN_HTTP=FAIL ERROR=" + $post.Error)
  Write-Host "WIFI_SCANFIX_RUNTIME=FAIL_POST_SCAN_HTTP"
  exit 76
}

Write-Host ("POST_SCAN_HTTP=PASS RTT_MS=" + [Math]::Round($post.Ms,1))
Write-Host "ASYNC_SCAN_STATE=PASS"
Write-Host "HTTP_RESPONSIVE_DURING_SCAN=PASS"
Write-Host "SCAN_COMPLETION=PASS"
Write-Host "WIFI_SCANFIX_RUNTIME=PASS"
Write-Host "RELAY_LOAD_POWER=KEEP_DISCONNECTED"
exit 0
