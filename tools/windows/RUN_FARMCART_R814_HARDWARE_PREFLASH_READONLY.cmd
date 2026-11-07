@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - HARDWARE PREFLASH READONLY GATE ===
echo MODE=HARDWARE_PREFLASH_READONLY
echo SOURCE_WRITE=NO
echo FLASH_WRITE=NO
echo FLASH_ERASE=NO
echo NVS_READ=NO
echo NVS_WRITE=NO
echo RELAY_COMMAND=NO
echo MERGE_MAIN=NO
echo.
echo SAFETY=Keep relay load/pump power disconnected during this probe.
echo NOTE=esptool may reset the ESP32-S3 while identifying the chip.
echo.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "RUNTIME_SHA=566cc4843a121dfefc9d7583f1398736b134c186"
set "EXPECTED_FW=0.8.0-5f-r8.14-stability-1"
set "FQBN=esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi"
set "REPO=%~dp0\..\.."

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 50
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
for /f "delims=" %%M in ('git rev-parse origin/main 2^>nul') do set "MAIN=%%M"

echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo ORIGIN_MAIN=!MAIN!

if /I not "!BRANCH!"=="%EXPECTED_BRANCH%" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 51
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 52
)

git cat-file -e %RUNTIME_SHA% 2>nul
if errorlevel 1 (
  echo ERROR=RUNTIME_SHA_MISSING_LOCALLY
  echo ACTION=git fetch --prune origin
  popd
  exit /b 53
)

git diff --quiet %RUNTIME_SHA% HEAD -- esp32 flutter
if errorlevel 1 (
  echo ERROR=RUNTIME_SOURCE_DRIFT
  echo The current candidate changes esp32/ or flutter/ relative to the accepted CI runtime SHA.
  git diff --stat %RUNTIME_SHA% HEAD -- esp32 flutter
  popd
  exit /b 54
)
echo RUNTIME_SOURCE_LOCK=PASS
echo RUNTIME_SHA=%RUNTIME_SHA%

findstr /C:"%EXPECTED_FW%" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=FW_VERSION_MISMATCH
  popd
  exit /b 55
)
echo FW_VERSION_LOCK=PASS
echo EXPECTED_FW=%EXPECTED_FW%

findstr /C:"4, 5, 6, 7, 15, 16, 17, 18" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=RELAY_PIN_LOCK_MISMATCH
  popd
  exit /b 56
)
findstr /C:"RELAY_ACTIVE_LOW = false" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=RELAY_POLARITY_LOCK_MISMATCH
  popd
  exit /b 57
)
findstr /C:"I2C_SDA_PIN = 8" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=RTC_SDA_LOCK_MISMATCH
  popd
  exit /b 58
)
findstr /C:"I2C_SCL_PIN = 9" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=RTC_SCL_LOCK_MISMATCH
  popd
  exit /b 59
)
echo HARDWARE_MAPPING_LOCK=PASS
echo RELAY_GPIO=4,5,6,7,15,16,17,18
echo RELAY_POLARITY=ACTIVE_HIGH
echo RTC_SDA=GPIO8
echo RTC_SCL=GPIO9

echo.
echo --- TOOLCHAIN ---
arduino-cli version
python -m esptool version
if errorlevel 1 (
  echo ERROR=ESPTOOL_NOT_READY
  popd
  exit /b 60
)

echo.
echo --- BUILD EXACT CURRENT RUNTIME SOURCE: NO FLASH ---
set "BUILD=%TEMP%\farmcart_r814_preflash_build"
if exist "%BUILD%" rmdir /s /q "%BUILD%"
arduino-cli compile --fqbn esp32:esp32:esp32s3 --build-path "%BUILD%" esp32\SmartFarm_ESP32_5F
if errorlevel 1 (
  echo PREFLASH_BUILD=FAIL
  popd
  exit /b 61
)
echo PREFLASH_BUILD=PASS

set "APPBIN="
for /r "%BUILD%" %%F in (*.ino.bin) do if not defined APPBIN set "APPBIN=%%~fF"
if not defined APPBIN (
  for /r "%BUILD%" %%F in (*.bin) do (
    echo BUILD_BIN=%%~fF
  )
  echo ERROR=APP_BINARY_NOT_FOUND
  popd
  exit /b 62
)
echo APP_BINARY=!APPBIN!
for %%F in ("!APPBIN!") do echo APP_BYTES=%%~zF
for /f "tokens=1" %%H in ('certutil -hashfile "!APPBIN!" SHA256 ^| findstr /R /V "hash CertUtil"') do if not defined APP_SHA256 set "APP_SHA256=%%H"
echo APP_SHA256=!APP_SHA256!

echo.
echo --- SERIAL DISCOVERY ---
arduino-cli board list
echo.
reg query HKLM\HARDWARE\DEVICEMAP\SERIALCOMM 2>nul

echo.
echo --- ESPTOOL READ-ONLY CHIP PROBE ---
set "ESP_PORT=%~1"
if defined ESP_PORT (
  echo PORT_SELECTION=ARGUMENT
  echo SELECTED_PORT=!ESP_PORT!
) else (
  echo PORT_SELECTION=INTERACTIVE
  echo Enter the ESP32-S3 COM port shown above, for example COM5.
  set /p "ESP_PORT=ESP32_S3_PORT: "
)

if not defined ESP_PORT (
  echo PREFLASH_PORT_GATE=FAIL_NO_PORT_SELECTED
  echo NEXT=Rerun with a port argument, for example:
  echo call tools\windows\RUN_FARMCART_R814_HARDWARE_PREFLASH_READONLY.cmd COM5
  popd
  exit /b 63
)

echo !ESP_PORT!| findstr /R /I "^COM[0-9][0-9]*$" >nul
if errorlevel 1 (
  echo PREFLASH_PORT_GATE=FAIL_INVALID_PORT
  echo SELECTED_PORT=!ESP_PORT!
  echo NEXT=Use a Windows COM port such as COM5.
  popd
  exit /b 64
)

echo.
echo PROBE_PORT=!ESP_PORT!
python -m esptool --port !ESP_PORT! chip-id > "%TEMP%\farmcart_esptool_selected.txt" 2>&1
if errorlevel 1 (
  python -m esptool --port !ESP_PORT! chip_id > "%TEMP%\farmcart_esptool_selected.txt" 2>&1
)
type "%TEMP%\farmcart_esptool_selected.txt"

findstr /I /C:"ESP32-S3" "%TEMP%\farmcart_esptool_selected.txt" >nul
if errorlevel 1 (
  echo PREFLASH_PORT_GATE=FAIL_NOT_ESP32_S3
  echo SELECTED_PORT=!ESP_PORT!
  echo NEXT=Choose the ESP32-S3 COM port shown by arduino-cli board list and rerun.
  popd
  exit /b 65
)

echo ESP32_S3_MATCH=YES PORT=!ESP_PORT!
echo PREFLASH_PORT_GATE=PASS
echo ESP32_S3_PORT=!ESP_PORT!

echo.
echo --- FLASH ID READ ONLY ---
python -m esptool --port !ESP_PORT! flash-id > "%TEMP%\farmcart_flashid.txt" 2>&1
if errorlevel 1 (
  python -m esptool --port !ESP_PORT! flash_id > "%TEMP%\farmcart_flashid.txt" 2>&1
)
type "%TEMP%\farmcart_flashid.txt"
if errorlevel 1 (
  echo FLASH_ID_READ=FAIL
  popd
  exit /b 65
)
echo FLASH_ID_READ=PASS

echo.
echo === PREFLASH RESULT ===
echo RUNTIME_SOURCE_LOCK=PASS
echo FW_VERSION_LOCK=PASS
echo HARDWARE_MAPPING_LOCK=PASS
echo PREFLASH_BUILD=PASS
echo PREFLASH_PORT_GATE=PASS
echo ESP32_S3_PORT=!ESP_PORT!
echo FLASH_ID_READ=PASS
echo SOURCE_WRITE=NO
echo FLASH_WRITE=NO
echo FLASH_ERASE=NO
echo NVS_READ=NO
echo NVS_WRITE=NO
echo HARDWARE_ACCEPTANCE=NOT_STARTED
echo NEXT=Return this complete output for review before any flash action.
echo.
echo Copy this entire output back to ChatGPT.
popd
endlocal
