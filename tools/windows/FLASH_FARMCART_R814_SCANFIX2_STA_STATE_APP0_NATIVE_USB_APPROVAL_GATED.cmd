@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 SCAN-FIX2 STA-STATE - APP0 NATIVE USB APPROVAL GATE ===
echo MODE=BUILD_AND_APP0_APPROVAL_GATED_FLASH
echo TARGET_TRANSPORT=ESP32-S3_NATIVE_USB_SERIAL_JTAG
echo FLASH_BAUD=115200
echo RESET_MODE=usb-reset
echo STUB=DISABLED
echo COMPRESSION=DISABLED
echo WRITE_SCOPE=APP0_ONLY
echo NVS_WRITE=NO
echo OTADATA_WRITE=NO
echo PARTITION_TABLE_WRITE=NO
echo BOOTLOADER_WRITE=NO
echo ERASE_ALL=NO
echo.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "SCANFIX_SOURCE_SHA=ed7168c8b9b318c684412ad9e0baa6291ce1534d"
set "BASELINE_SOURCE_SHA=30ab9bbadcc601b4978d416efb985af84ba9145e"
set "EXPECTED_FW=0.8.0-5f-r8.14-stability-1"
set "EXPECTED_MAC=14:c1:9f:50:b9:64"
set "FQBN=esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi"
set "APP0_OFFSET=0x10000"
set "APP0_SIZE_DEC=3145728"
set "PORT=%~1"
set "TOKEN=%~2"
set "REPO=%~dp0\..\.."
set ESPTOOL_OPEN_PORT_ATTEMPTS=10

if "%PORT%"=="" (
  echo ERROR=PORT_REQUIRED
  echo USAGE=call tools\windows\FLASH_FARMCART_R814_SCANFIX2_STA_STATE_APP0_NATIVE_USB_APPROVAL_GATED.cmd COM5 FLASH_R814_SCANFIX2_STA_STATE
  exit /b 240
)
if /I not "%TOKEN%"=="FLASH_R814_SCANFIX2_STA_STATE" (
  echo ERROR=APPROVAL_TOKEN_MISSING
  exit /b 241
)

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 242
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo PORT=%PORT%

if /I not "!BRANCH!"=="%EXPECTED_BRANCH%" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 243
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 244
)

git cat-file -e %SCANFIX_SOURCE_SHA% 2>nul || (
  echo ERROR=SCANFIX_SOURCE_SHA_MISSING
  popd
  exit /b 245
)

git diff --quiet %SCANFIX_SOURCE_SHA% HEAD -- esp32
if errorlevel 1 (
  echo ERROR=ESP32_SOURCE_DRIFT_AFTER_SCANFIX_LOCK
  git diff --stat %SCANFIX_SOURCE_SHA% HEAD -- esp32
  popd
  exit /b 246
)
echo RUNTIME_SOURCE_LOCK=PASS

findstr /C:"%EXPECTED_FW%" "esp32\SmartFarm_ESP32_5F\Config.h" >nul || (
  echo ERROR=FW_VERSION_MISMATCH
  popd
  exit /b 247
)
echo FW_VERSION_LOCK=PASS

set "DIFFLIST=%TEMP%\farmcart_scanfix2_sta_state_diff.txt"
git diff --name-only %BASELINE_SOURCE_SHA% %SCANFIX_SOURCE_SHA% -- esp32 > "%DIFFLIST%"
set "DIFFCOUNT=0"
set "DIFFPATH="
for /f "usebackq delims=" %%L in ("%DIFFLIST%") do (
  set /a DIFFCOUNT+=1
  set "DIFFPATH=%%L"
)
if not "!DIFFCOUNT!"=="1" (
  echo ERROR=SCANFIX_ESP32_DIFF_SCOPE_NOT_SINGLE_FILE COUNT=!DIFFCOUNT!
  type "%DIFFLIST%"
  popd
  exit /b 248
)
if /I not "!DIFFPATH!"=="esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp" (
  echo ERROR=EXPECTED_SCANFIX_FILE_MISMATCH
  echo ACTUAL_DIFF_PATH=!DIFFPATH!
  popd
  exit /b 249
)
echo SCANFIX_DIFF_SCOPE=PASS_ONLY_WIFI_TRANSPORT_CPP

echo.
echo --- CANONICAL N16R8 PROFILE ASSERTION ---
set "PROPS=%TEMP%\farmcart_scanfix2_sta_state_properties.txt"
arduino-cli compile --fqbn "%FQBN%" --show-properties esp32\SmartFarm_ESP32_5F > "%PROPS%" 2>&1
if errorlevel 1 (
  type "%PROPS%"
  echo ERROR=BOARD_PROFILE_PROPERTIES_FAILED
  popd
  exit /b 250
)
findstr /C:"build.flash_size=16MB" "%PROPS%" >nul || (echo ERROR=FLASH_SIZE_PROFILE_MISMATCH & popd & exit /b 251)
findstr /C:"build.partitions=app3M_fat9M_16MB" "%PROPS%" >nul || (echo ERROR=PARTITION_PROFILE_MISMATCH & popd & exit /b 252)
findstr /C:"upload.maximum_size=3145728" "%PROPS%" >nul || (echo ERROR=APP_LIMIT_PROFILE_MISMATCH & popd & exit /b 253)
echo BOARD_PROFILE_LOCK=PASS

echo.
echo --- BUILD EXACT SCAN-FIX APPLICATION ---
set "BUILD=%TEMP%\farmcart_r814_scanfix2_sta_state_native_build"
if exist "%BUILD%" rmdir /s /q "%BUILD%"
arduino-cli compile --fqbn "%FQBN%" --build-path "%BUILD%" esp32\SmartFarm_ESP32_5F
if errorlevel 1 (
  echo ERROR=CANONICAL_BUILD_FAILED
  popd
  exit /b 254
)

set "APPBIN="
for /r "%BUILD%" %%F in (*.ino.bin) do if not defined APPBIN set "APPBIN=%%~fF"
if not defined APPBIN (
  echo ERROR=APP_BINARY_NOT_FOUND
  popd
  exit /b 255
)
for %%F in ("!APPBIN!") do set "APP_BYTES=%%~zF"
echo APP_BINARY=!APPBIN!
echo APP_BYTES=!APP_BYTES!
if !APP_BYTES! GEQ %APP0_SIZE_DEC% (
  echo ERROR=APP_BINARY_EXCEEDS_APP0
  popd
  exit /b 256
)
for /f "tokens=1" %%H in ('certutil -hashfile "!APPBIN!" SHA256 ^| findstr /R /V "hash CertUtil"') do if not defined APP_SHA256 set "APP_SHA256=%%H"
echo APP_SHA256=!APP_SHA256!
echo APP_BUILD=PASS

echo.
echo --- NATIVE USB ROM PREFLIGHT: SINGLE FLASH-ID ---
set "IDLOG=%TEMP%\farmcart_scanfix2_sta_state_flashid.txt"
python -m esptool --chip esp32s3 --port %PORT% -b 115200 --before usb-reset --after no-reset --no-stub flash-id > "%IDLOG%" 2>&1
set "IDRC=!ERRORLEVEL!"
type "%IDLOG%"
if not "!IDRC!"=="0" (
  echo ERROR=NATIVE_USB_ROM_FLASH_ID_FAILED
  popd
  exit /b 257
)
findstr /I /C:"USB mode:           USB-Serial/JTAG" "%IDLOG%" >nul || (
  echo ERROR=NOT_NATIVE_USB_SERIAL_JTAG
  popd
  exit /b 258
)
findstr /I /C:"%EXPECTED_MAC%" "%IDLOG%" >nul || (
  echo ERROR=MAC_MISMATCH
  popd
  exit /b 259
)
findstr /I /C:"Detected flash size: 16MB" "%IDLOG%" >nul || (
  echo ERROR=FLASH_SIZE_NOT_16MB
  popd
  exit /b 260
)
echo NATIVE_USB_ROM_PREFLIGHT=PASS
echo MAC_LOCK=PASS
echo FLASH_SIZE_16MB=PASS

for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
set "EVIDENCE=%REPO%\..\backups\farmcart_r814_scanfix2_sta_state_%PORT%_!TS!"
mkdir "!EVIDENCE!" >nul 2>nul
copy /y "!APPBIN!" "!EVIDENCE!\scanfix2_sta_state_app0.bin" >nul
copy /y "%IDLOG%" "!EVIDENCE!\flash_id_prewrite.txt" >nul
> "!EVIDENCE!\APP_SHA256.txt" echo !APP_SHA256!  scanfix2_sta_state_app0.bin
echo EVIDENCE_DIR=!EVIDENCE!

echo.
echo === APP0 SCANFIX2 NATIVE USB ROM WRITE START ===
echo APPROVAL_TOKEN=PASS
echo TARGET=%PORT%
echo FLASH_BAUD=115200
echo RESET_MODE=usb-reset
echo STUB=DISABLED
echo COMPRESSION=DISABLED
echo OFFSET=%APP0_OFFSET%
echo WRITE_SCOPE=APP0_ONLY
echo NVS_WRITE=NO
echo OTADATA_WRITE=NO
echo PARTITION_TABLE_WRITE=NO
echo BOOTLOADER_WRITE=NO
echo ERASE_ALL=NO

set "WRITELOG=!EVIDENCE!\app0_write.txt"
python -m esptool --chip esp32s3 --port %PORT% -b 115200 --before usb-reset --after no-reset --no-stub write-flash --flash-size 16MB --no-compress %APP0_OFFSET% "!APPBIN!" > "!WRITELOG!" 2>&1
set "WRITERC=!ERRORLEVEL!"
type "!WRITELOG!"

if not "!WRITERC!"=="0" (
  echo APP0_RECOVERY_WRITE=FAIL
  echo DEVICE_STATE=BOOTLOADER_OR_REENUMERATION_UNKNOWN
  echo ACTION=Do not run another flash. Return this complete output.
  popd
  exit /b 261
)

echo.
echo === APP0 SCANFIX2 NATIVE USB ROM RESULT ===
echo APP0_RECOVERY_WRITE=PASS
echo APP_SHA256=!APP_SHA256!
echo APP_BYTES=!APP_BYTES!
echo PORT=%PORT%
echo EVIDENCE_DIR=!EVIDENCE!
echo NVS_PRESERVED=YES
echo OTADATA_PRESERVED=YES
echo PARTITION_TABLE_PRESERVED=YES
echo BOOTLOADER_PRESERVED=YES
echo ERASE_ALL=NO
echo POSTWRITE_RUNTIME=NOT_YET_TESTED
echo NEXT=Return this complete output before reset/runtime testing.
popd
exit /b 0
