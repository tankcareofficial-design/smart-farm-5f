@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - POSTFLASH SMOKE READONLY ===
echo MODE=POSTFLASH_SMOKE_READONLY
echo SOURCE_WRITE=NO
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo HTTP_WRITE=NO
echo MERGE_MAIN=NO
echo.
echo SAFETY=Keep relay load/pump power disconnected during this gate.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "RUNTIME_SHA=566cc4843a121dfefc9d7583f1398736b134c186"
set "EXPECTED_FW=0.8.0-5f-r8.14-stability-1"
set "PORT=%~1"
set "REPO=%~dp0\..\.."
set "PS1=%~dp0RUN_FARMCART_R814_POSTFLASH_SERIAL_CAPTURE_READONLY.ps1"

if not defined PORT (
  echo ERROR=NO_PORT
  echo USAGE=call tools\windows\RUN_FARMCART_R814_POSTFLASH_SMOKE_READONLY.cmd COM5
  exit /b 110
)

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 111
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
for /f "delims=" %%M in ('git rev-parse origin/main 2^>nul') do set "MAIN=%%M"

echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo ORIGIN_MAIN=!MAIN!
echo PORT=%PORT%

if /I not "!BRANCH!"=="%EXPECTED_BRANCH%" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 112
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 113
)

git cat-file -e %RUNTIME_SHA% 2>nul
if errorlevel 1 (
  echo ERROR=RUNTIME_SHA_MISSING_LOCALLY
  popd
  exit /b 114
)

git diff --quiet %RUNTIME_SHA% HEAD -- esp32 flutter
if errorlevel 1 (
  echo ERROR=RUNTIME_SOURCE_DRIFT
  git diff --stat %RUNTIME_SHA% HEAD -- esp32 flutter
  popd
  exit /b 115
)
echo RUNTIME_SOURCE_LOCK=PASS

findstr /C:"%EXPECTED_FW%" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=FW_VERSION_MISMATCH
  popd
  exit /b 116
)
echo FW_VERSION_LOCK=PASS

echo.
echo --- DEVICE PRESENCE / CONTROLLED RESET ---
python -m esptool --port %PORT% chip-id > "%TEMP%\farmcart_r814_postflash_chip.txt" 2>&1
type "%TEMP%\farmcart_r814_postflash_chip.txt"
findstr /I /C:"ESP32-S3" "%TEMP%\farmcart_r814_postflash_chip.txt" >nul
if errorlevel 1 (
  echo DEVICE_PRESENCE=FAIL
  popd
  exit /b 117
)
echo DEVICE_PRESENCE=PASS

echo.
echo --- SERIAL BOOT/RUNTIME CAPTURE ---
set "SERIAL_LOG=%TEMP%\farmcart_r814_postflash_serial.log"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Port "%PORT%" -Seconds 18 -LogPath "%SERIAL_LOG%"
set "SERIAL_RC=!ERRORLEVEL!"
if exist "%SERIAL_LOG%" (
  findstr /C:"Firmware: %EXPECTED_FW%" "%SERIAL_LOG%" >nul && (set "FW_RUNTIME=PASS") || (set "FW_RUNTIME=NOT_SEEN")
  findstr /C:"AP start: SUCCESS" "%SERIAL_LOG%" >nul && (set "AP_SERIAL=PASS") || (set "AP_SERIAL=NOT_SEEN")
  findstr /C:"Device ID:" "%SERIAL_LOG%" >nul && (set "DEVICE_ID_SERIAL=SEEN") || (set "DEVICE_ID_SERIAL=NOT_SEEN")
  findstr /C:"RTC:" "%SERIAL_LOG%" >nul && (set "RTC_SERIAL=SEEN") || (set "RTC_SERIAL=NOT_SEEN")
) else (
  set "FW_RUNTIME=NOT_SEEN"
  set "AP_SERIAL=NOT_SEEN"
  set "DEVICE_ID_SERIAL=NOT_SEEN"
  set "RTC_SERIAL=NOT_SEEN"
)
echo FW_RUNTIME=!FW_RUNTIME!
echo AP_SERIAL=!AP_SERIAL!
echo DEVICE_ID_SERIAL=!DEVICE_ID_SERIAL!
echo RTC_SERIAL=!RTC_SERIAL!

echo.
echo --- WINDOWS WLAN PASSIVE SCAN ---
set "WLAN_LOG=%TEMP%\farmcart_r814_wlan_scan.txt"
netsh wlan show networks mode=bssid > "%WLAN_LOG%" 2>&1
type "%WLAN_LOG%"
findstr /I /C:"SmartFarm-" "%WLAN_LOG%" >nul
if errorlevel 1 (
  echo SMARTFARM_AP_SCAN=NOT_SEEN
) else (
  echo SMARTFARM_AP_SCAN=PASS
)

echo.
echo === POSTFLASH SMOKE RESULT ===
echo DEVICE_PRESENCE=PASS
echo FW_RUNTIME=!FW_RUNTIME!
echo AP_SERIAL=!AP_SERIAL!
echo SMARTFARM_AP_SCAN=
findstr /I /C:"SmartFarm-" "%WLAN_LOG%" >nul && echo SMARTFARM_AP_SCAN=PASS || echo SMARTFARM_AP_SCAN=NOT_SEEN
echo RELAY_LOAD_POWER=KEEP_DISCONNECTED
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo HTTP_WRITE=NO
echo HARDWARE_ACCEPTANCE=NOT_YET_PASS
echo RUNTIME_ACCEPTANCE=NOT_YET_PASS
echo NEXT=Return this complete output for review before reconnecting relay load/pump power.
echo.
echo Copy this entire output back to ChatGPT.

popd
endlocal
