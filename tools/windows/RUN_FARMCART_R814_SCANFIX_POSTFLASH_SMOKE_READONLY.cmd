@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 SCAN-FIX - POSTFLASH SMOKE READONLY ===
echo MODE=POSTFLASH_SMOKE_READONLY
echo SOURCE_WRITE=NO
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo HTTP_WRITE=NO
echo ESPTOOL_ACCESS=NO
echo MERGE_MAIN=NO
echo.
echo SAFETY=Keep relay load/pump power disconnected during this gate.
echo REQUIREMENT=Press EN/RST exactly once before running this script so APP0 boots normally.
echo.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "RUNTIME_SHA=30ab9bbadcc601b4978d416efb985af84ba9145e"
set "EXPECTED_FW=0.8.0-5f-r8.14-stability-1"
set "PORT=%~1"
set "REPO=%~dp0\..\.."
set "PS1=%~dp0RUN_FARMCART_R814_POSTFLASH_SERIAL_CAPTURE_READONLY.ps1"

if not defined PORT (
  echo ERROR=NO_PORT
  echo USAGE=call tools\windows\RUN_FARMCART_R814_SCANFIX_POSTFLASH_SMOKE_READONLY.cmd COM5
  exit /b 270
)

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 271
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo PORT=%PORT%

if /I not "!BRANCH!"=="%EXPECTED_BRANCH%" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 272
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 273
)

git cat-file -e %RUNTIME_SHA% 2>nul
if errorlevel 1 (
  echo ERROR=RUNTIME_SHA_MISSING_LOCALLY
  popd
  exit /b 274
)

git diff --quiet %RUNTIME_SHA% HEAD -- esp32 flutter
if errorlevel 1 (
  echo ERROR=RUNTIME_SOURCE_DRIFT
  git diff --stat %RUNTIME_SHA% HEAD -- esp32 flutter
  popd
  exit /b 275
)
echo RUNTIME_SOURCE_LOCK=PASS

findstr /C:"%EXPECTED_FW%" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=FW_VERSION_MISMATCH
  popd
  exit /b 276
)
echo FW_VERSION_LOCK=PASS

echo.
echo --- SERIAL BOOT/RUNTIME CAPTURE ---
set "SERIAL_LOG=%TEMP%\farmcart_r814_scanfix_postflash_serial.log"
if exist "%SERIAL_LOG%" del /q "%SERIAL_LOG%" >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Port "%PORT%" -Seconds 20 -LogPath "%SERIAL_LOG%"
set "SERIAL_RC=!ERRORLEVEL!"

if exist "%SERIAL_LOG%" (
  type "%SERIAL_LOG%"
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
echo SERIAL_CAPTURE_RC=!SERIAL_RC!
echo FW_RUNTIME=!FW_RUNTIME!
echo AP_SERIAL=!AP_SERIAL!
echo DEVICE_ID_SERIAL=!DEVICE_ID_SERIAL!
echo RTC_SERIAL=!RTC_SERIAL!

echo.
echo --- WINDOWS WLAN PASSIVE SCAN ---
set "WLAN_LOG=%TEMP%\farmcart_r814_scanfix_wlan_scan.txt"
netsh wlan show networks mode=bssid > "%WLAN_LOG%" 2>&1
findstr /I /C:"SmartFarm-" "%WLAN_LOG%" >nul
if errorlevel 1 (
  set "SMARTFARM_AP_SCAN=NOT_SEEN"
) else (
  set "SMARTFARM_AP_SCAN=PASS"
)
echo SMARTFARM_AP_SCAN=!SMARTFARM_AP_SCAN!

echo.
echo === POSTFLASH SMOKE RESULT ===
echo FW_RUNTIME=!FW_RUNTIME!
echo AP_SERIAL=!AP_SERIAL!
echo SMARTFARM_AP_SCAN=!SMARTFARM_AP_SCAN!
echo DEVICE_ID_SERIAL=!DEVICE_ID_SERIAL!
echo RTC_SERIAL=!RTC_SERIAL!
echo ESPTOOL_ACCESS=NO
echo RELAY_LOAD_POWER=KEEP_DISCONNECTED
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo HTTP_WRITE=NO
echo HARDWARE_ACCEPTANCE=NOT_YET_PASS
echo WIFI_SCANFIX_ACCEPTANCE=NOT_YET_PASS
echo NEXT=Return this complete output. If firmware/AP is alive, next gate is /api/wifi/scan runtime behavior.
popd
exit /b 0
