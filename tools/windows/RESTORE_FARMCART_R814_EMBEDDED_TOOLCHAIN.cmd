@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - EMBEDDED TOOLCHAIN RESTORE ===
echo MODE=TOOLCHAIN_INSTALL_AND_BUILD_VERIFY
echo SOURCE_WRITE=NO
echo DEVICE_ACCESS=NO
echo FLASH=NO
echo NVS_WRITE=NO
echo MERGE_MAIN=NO
echo.

set "REPO=%~dp0\..\.."\nset "FQBN=esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi"
pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 30
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"

echo BRANCH=!BRANCH!
echo HEAD=!HEAD!

if /I not "!BRANCH!"=="candidate/r8.14-stability-1" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 31
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 32
)

echo.
echo --- INSTALL ARDUINO CLI 1.5.1 ---
where arduino-cli >nul 2>nul
if errorlevel 1 (
  winget install --id ArduinoSA.CLI -e --version 1.5.1 --silent --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    echo ERROR=ARDUINO_CLI_INSTALL_FAILED
    popd
    exit /b 33
  )
)

set "PATH=%PATH%;C:\Program Files\Arduino CLI;C:\Program Files (x86)\Arduino CLI"
where arduino-cli >nul 2>nul
if errorlevel 1 (
  echo ERROR=ARDUINO_CLI_NOT_ON_PATH
  echo ACTION=Close CMD, open a new CMD, cd /d D:\FarmCart\smart-farm-5f, then run this script again.
  popd
  exit /b 34
)

arduino-cli version
if errorlevel 1 (
  echo ERROR=ARDUINO_CLI_VERSION_FAILED
  popd
  exit /b 35
)

echo.
echo --- PIN ESP32 CORE TO CI VERSION ---
arduino-cli config init >nul 2>nul
arduino-cli core update-index
if errorlevel 1 (
  echo ERROR=CORE_INDEX_FAILED
  popd
  exit /b 36
)

arduino-cli core install esp32:esp32@3.3.12
if errorlevel 1 (
  echo ERROR=ESP32_CORE_INSTALL_FAILED
  popd
  exit /b 37
)

arduino-cli lib install ArduinoJson@7.4.3
if errorlevel 1 (
  echo ERROR=ARDUINOJSON_INSTALL_FAILED
  popd
  exit /b 38
)

echo.
echo --- INSTALL ESPTOOL 5.3.1 FOR READBACK / PREFLIGHT ---
python -m pip install --user --upgrade "esptool==5.3.1"
if errorlevel 1 (
  echo ERROR=ESPTOOL_INSTALL_FAILED
  popd
  exit /b 39
)

echo.
echo --- VERSION LOCK EVIDENCE ---
arduino-cli core list
arduino-cli lib list | findstr /I "ArduinoJson"
python -m esptool version

echo.
echo --- BUILD VERIFY ONLY: NO FLASH ---
if exist "%TEMP%\farmcart_r814_build" rmdir /s /q "%TEMP%\farmcart_r814_build"
arduino-cli compile --fqbn "%FQBN%" --build-path "%TEMP%\farmcart_r814_build" esp32\SmartFarm_ESP32_5F
if errorlevel 1 (
  echo EMBEDDED_BUILD=FAIL
  popd
  exit /b 40
)
echo EMBEDDED_BUILD=PASS

echo.
echo --- BOARD / SERIAL DISCOVERY: READ ONLY ---
arduino-cli board list
echo.
echo Windows COM registry:
reg query HKLM\HARDWARE\DEVICEMAP\SERIALCOMM 2>nul
if errorlevel 1 echo SERIAL_REGISTRY=NO_PORTS_OR_UNAVAILABLE

echo.
echo === RESULT ===
echo ARDUINO_CLI=READY
echo ESP32_CORE=3.3.12_EXPECTED
echo ARDUINOJSON=7.4.3_EXPECTED
echo ESPTOOL=5.3.1_EXPECTED
echo EMBEDDED_BUILD=PASS
echo SOURCE_WRITE=NO
echo DEVICE_ACCESS=READ_ONLY_DISCOVERY_ONLY
echo FLASH=NO
echo NEXT=Connect ESP32-S3 by USB and run hardware preflash read-only gate.
echo.
echo Copy this entire output back to ChatGPT.
popd
endlocal
