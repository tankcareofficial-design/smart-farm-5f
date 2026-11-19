param(
  [Parameter(Mandatory=$true)][string]$Port,
  [int]$Seconds = 18,
  [Parameter(Mandatory=$true)][string]$LogPath
)

$ErrorActionPreference = "Stop"
$serial = New-Object System.IO.Ports.SerialPort $Port,115200,None,8,one
$serial.ReadTimeout = 250
$serial.WriteTimeout = 250
$serial.DtrEnable = $false
$serial.RtsEnable = $false

try {
  if (Test-Path -LiteralPath $LogPath) { Remove-Item -LiteralPath $LogPath -Force }
  $serial.Open()
  $deadline = (Get-Date).AddSeconds($Seconds)
  while ((Get-Date) -lt $deadline) {
    try {
      $chunk = $serial.ReadExisting()
      if ($chunk) {
        [Console]::Write($chunk)
        Add-Content -LiteralPath $LogPath -Value $chunk -NoNewline
      }
    } catch {
      Start-Sleep -Milliseconds 100
    }
    Start-Sleep -Milliseconds 100
  }
  Write-Host ""
  Write-Host "SERIAL_CAPTURE=COMPLETE"
  exit 0
}
catch {
  Write-Host "SERIAL_CAPTURE=UNAVAILABLE"
  Write-Host ("SERIAL_CAPTURE_ERROR=" + $_.Exception.Message)
  exit 2
}
finally {
  if ($serial -and $serial.IsOpen) { $serial.Close() }
  if ($serial) { $serial.Dispose() }
}
