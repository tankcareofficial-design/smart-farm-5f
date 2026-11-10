param(
  [string]$BaseUrl = "http://192.168.4.1",
  [int]$Cycles = 12,
  [int]$TimeoutSec = 3,
  [int]$GapMs = 350
)

$ErrorActionPreference = "Stop"
$Endpoints = @(
  [pscustomobject]@{ Name="root";   Path="/" },
  [pscustomobject]@{ Name="device"; Path="/api/device" },
  [pscustomobject]@{ Name="state";  Path="/api/state" },
  [pscustomobject]@{ Name="relays"; Path="/api/relays" },
  [pscustomobject]@{ Name="clock";  Path="/api/v3/clock" }
)

Write-Host "=== FARMCART SMARTGROW R8.14 - AP HTTP TRANSPORT STABILITY READONLY ==="
Write-Host "MODE=READ_ONLY"
Write-Host "HTTP_METHOD=GET_ONLY"
Write-Host "SOURCE_WRITE=NO"
Write-Host "ESP_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "RELAY_COMMAND=NO"
Write-Host "RTC_WRITE=NO"
Write-Host "WIFI_CONFIG_WRITE=NO"
Write-Host "FLASH_WRITE=NO"
Write-Host ("BASE_URL=" + $BaseUrl)
Write-Host ("CYCLES=" + $Cycles)
Write-Host ("REQUESTS_TOTAL=" + ($Cycles * $Endpoints.Count))
Write-Host ("TIMEOUT_SEC=" + $TimeoutSec)
Write-Host ("GAP_MS=" + $GapMs)
Write-Host ""

$stats = @{}
foreach ($ep in $Endpoints) {
  $stats[$ep.Name] = [ordered]@{
    Attempts = 0
    Pass = 0
    Fail = 0
    TotalMs = 0.0
    MaxMs = 0.0
    MinMs = [double]::MaxValue
  }
}

$allFailures = 0
$allPass = 0

for ($cycle = 1; $cycle -le $Cycles; $cycle++) {
  Write-Host ("--- CYCLE " + $cycle + "/" + $Cycles + " ---")
  foreach ($ep in $Endpoints) {
    $uri = $BaseUrl.TrimEnd("/") + $ep.Path
    $st = $stats[$ep.Name]
    $st.Attempts++

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = $false
    $status = 0
    $err = ""

    try {
      $response = Invoke-WebRequest -UseBasicParsing -Method Get -Uri $uri -TimeoutSec $TimeoutSec -DisableKeepAlive
      $status = [int]$response.StatusCode
      $ok = ($status -eq 200)
    } catch {
      $err = $_.Exception.Message
    }

    $sw.Stop()
    $ms = $sw.Elapsed.TotalMilliseconds

    if ($ok) {
      $st.Pass++
      $allPass++
      $st.TotalMs += $ms
      if ($ms -gt $st.MaxMs) { $st.MaxMs = $ms }
      if ($ms -lt $st.MinMs) { $st.MinMs = $ms }
      Write-Host ("CYCLE=" + $cycle + " ENDPOINT=" + $ep.Name + " RESULT=PASS HTTP=" + $status + " RTT_MS=" + [Math]::Round($ms,1))
    } else {
      $st.Fail++
      $allFailures++
      Write-Host ("CYCLE=" + $cycle + " ENDPOINT=" + $ep.Name + " RESULT=FAIL HTTP=" + $status + " RTT_MS=" + [Math]::Round($ms,1) + " ERROR=" + $err)
    }

    Start-Sleep -Milliseconds $GapMs
  }
}

Write-Host ""
Write-Host "=== ENDPOINT SUMMARY ==="
foreach ($ep in $Endpoints) {
  $st = $stats[$ep.Name]
  $avg = if ($st.Pass -gt 0) { $st.TotalMs / $st.Pass } else { 0.0 }
  $min = if ($st.Pass -gt 0) { $st.MinMs } else { 0.0 }
  $passPct = if ($st.Attempts -gt 0) { 100.0 * $st.Pass / $st.Attempts } else { 0.0 }

  Write-Host ("ENDPOINT=" + $ep.Name +
    " ATTEMPTS=" + $st.Attempts +
    " PASS=" + $st.Pass +
    " FAIL=" + $st.Fail +
    " PASS_PCT=" + [Math]::Round($passPct,1) +
    " AVG_MS=" + [Math]::Round($avg,1) +
    " MIN_MS=" + [Math]::Round($min,1) +
    " MAX_MS=" + [Math]::Round($st.MaxMs,1))
}

$total = $Cycles * $Endpoints.Count
$overallPct = if ($total -gt 0) { 100.0 * $allPass / $total } else { 0.0 }

Write-Host ""
Write-Host "=== AP HTTP TRANSPORT STABILITY RESULT ==="
Write-Host ("TOTAL_REQUESTS=" + $total)
Write-Host ("TOTAL_PASS=" + $allPass)
Write-Host ("TOTAL_FAIL=" + $allFailures)
Write-Host ("OVERALL_PASS_PCT=" + [Math]::Round($overallPct,1))

if ($allFailures -eq 0) {
  Write-Host "AP_HTTP_TRANSPORT_STABILITY=PASS"
  Write-Host "NEXT=Proceed to rapid relay latest-state regression."
  exit 0
}

Write-Host "AP_HTTP_TRANSPORT_STABILITY=FAIL"
Write-Host "CLASSIFICATION=INTERMITTENT_HTTP_TRANSPORT_OR_HANDLER_LATENCY"
Write-Host "NEXT=Return complete output for endpoint-pattern analysis. Do not connect pump/load."
exit 61
