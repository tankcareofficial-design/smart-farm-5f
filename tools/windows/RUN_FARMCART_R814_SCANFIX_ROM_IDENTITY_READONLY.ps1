param(
  [string]$Port = "COM5"
)

$ErrorActionPreference = "Stop"

Write-Host "=== FARMCART R8.14 SCAN-FIX - ROM IDENTITY READONLY ==="
Write-Host "MODE=READ_ONLY"
Write-Host "ESP_WRITE=NO"
Write-Host "FLASH_WRITE=NO"
Write-Host "NVS_WRITE=NO"
Write-Host "PORT=$Port"
Write-Host ""

function Run-Esptool([string[]]$Args) {
  $out = & python -m esptool @Args 2>&1
  $rc = $LASTEXITCODE
  $out | ForEach-Object { Write-Host $_ }
  return [pscustomobject]@{ Rc=$rc; Text=($out -join [Environment]::NewLine) }
}

Write-Host "--- ROM CHIP ID (NO STUB) ---"
$chip = Run-Esptool @("--chip","esp32s3","--port",$Port,"--no-stub","chip-id")
if ($chip.Rc -ne 0 -or $chip.Text -notmatch "ESP32-S3") {
  Write-Host "ROM_CHIP_ID=FAIL"
  exit 191
}
Write-Host "ROM_CHIP_ID=PASS"

Write-Host ""
Write-Host "--- ROM FLASH ID (NO STUB) ---"
$flash = Run-Esptool @("--chip","esp32s3","--port",$Port,"--no-stub","flash-id")
if ($flash.Rc -ne 0) {
  Write-Host "ROM_FLASH_ID=FAIL"
  exit 192
}
if ($flash.Text -notmatch "Detected flash size:\s*16\s*MB") {
  Write-Host "ROM_FLASH_SIZE_16MB=FAIL"
  exit 193
}
Write-Host "ROM_FLASH_ID=PASS"
Write-Host "ROM_FLASH_SIZE_16MB=PASS"

Write-Host ""
Write-Host "=== ROM IDENTITY RESULT ==="
Write-Host "ROM_IDENTITY_GATE=PASS"
Write-Host "NEXT=Return complete output before retrying flash."
exit 0
