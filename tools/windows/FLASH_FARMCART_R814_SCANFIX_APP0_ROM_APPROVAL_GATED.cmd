@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 SCAN-FIX - APP0 ONLY ROM FLASH ===
echo MODE=BUILD_AND_APP0_FLASH
echo SOURCE_WRITE=NO
echo MERGE_MAIN=NO
echo FLASH_BAUD=115200
echo STUB=DISABLED
echo WRITE_SCOPE=APP0_ONLY
echo NVS_WRITE=NO
echo OTADATA_WRITE=NO
echo PARTITION_TABLE_WRITE=NO
echo BOOTLOADER_WRITE=NO
echo ERASE_ALL=NO
echo.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "SCANFIX_SOURCE_SHA=30ab9bbadcc601b4978d416efb985af84ba9145e"
set "BASELINE_SOURCE_SHA=566cc4843a121dfefc9d7583f1398736b134c186"
set "EXPECTED_FW=0.8.0-5f-r8.14-stability-1"
set "FQBN=esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi"
set "APP0_OFFSET=0x10000"
set "APP0_SIZE_DEC=3145728"
set "EXPECTED_MAC=14:c1:9f:50:b9:64"
set "PORT=%~1"
set "TOKEN=%~2"
set "REPO=%~dp0\..\.."

if "%PORT%"=="" (
  echo ERROR=PORT_REQUIRED
  echo USAGE=call tools\windows\FLASH_FARMCART_R814_SCANFIX_APP0_ROM_APPROVAL_GATED.cmd COM7 FLASH_R814_SCANFIX_N16R8
  exit /b 210
)
if /I not "%TOKEN%"=="FLASH_R814_SCANFIX_N16R8" (
  echo ERROR=APPROVAL_TOKEN_MISSING
  exit /b 211
)

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 212
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo PORT=%PORT%
echo FQBN=%FQBN%

if /I not "!BRANCH!"=="%EXPECTED_BRANCH%" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 213
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 214
)

git cat-file -e %SCANFIX_SOURCE_SHA% 2>nul || (
  echo ERROR=SCANFIX_SOURCE_SHA_MISSING
  popd
  exit /b 215
)

git diff --quiet %SCANFIX_SOURCE_SHA% HEAD -- esp32
if errorlevel 1 (
  echo ERROR=ESP32_SOURCE_DRIFT_AFTER_SCANFIX_LOCK
  git diff --stat %SCANFIX_SOURCE_SHA% HEAD -- esp32
  popd
  exit /b 216
)
echo RUNTIME_SOURCE_LOCK=PASS

findstr /C:"%EXPECTED_FW%" "esp32\SmartFarm_ESP32_5F\Config.h" >nul || (
  echo ERROR=FW_VERSION_MISMATCH
  popd
  exit /b 217
)
echo FW_VERSION_LOCK=PASS

set "DIFFLIST=%TEMP%\farmcart_scanfix_esp32_diff.txt"
git diff --name-only %BASELINE_SOURCE_SHA% %SCANFIX_SOURCE_SHA% -- esp32 > "%DIFFLIST%"
type "%DIFFLIST%"
findstr /X /C:"esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp" "%DIFFLIST%" >nul || (
  echo ERROR=EXPECTED_SCANFIX_FILE_MISSING
  popd
  exit /b 218
)
for /f %%C in ('find /c /v "" ^< "%DIFFLIST%"') do set "DIFFCOUNT=%%C"
if not "!DIFFCOUNT!"=="1" (
  echo ERROR=SCANFIX_ESP32_DIFF_SCOPE_NOT_SINGLE_APP_FILE COUNT=!DIFFCOUNT!
  popd
  exit /b 219
)
echo SCANFIX_DIFF_SCOPE=PASS_ONLY_WIFI_TRANSPORT_CPP

echo.
echo --- CANONICAL N16R8 PROFILE ASSERTION ---
set "PROPS=%TEMP%\farmcart_r814_app0_properties.txt"
arduino-cli compile --fqbn "%FQBN%" --show-properties esp32\SmartFarm_ESP32_5F > "%PROPS%" 2>&1
if errorlevel 1 (
  type "%PROPS%"
  echo ERROR=BOARD_PROFILE_PROPERTIES_FAILED
  popd
  exit /b 220
)
findstr /C:"build.flash_size=16MB" "%PROPS%" >nul || (echo ERROR=FLASH_SIZE_PROFILE_MISMATCH & popd & exit /b 221)
findstr /C:"build.memory_type=qio_opi" "%PROPS%" >nul || (echo ERROR=MEMORY_TYPE_PROFILE_MISMATCH & popd & exit /b 222)
findstr /C:"build.partitions=app3M_fat9M_16MB" "%PROPS%" >nul || (echo ERROR=PARTITION_PROFILE_MISMATCH & popd & exit /b 223)
findstr /C:"build.psram_type=opi" "%PROPS%" >nul || (echo ERROR=PSRAM_PROFILE_MISMATCH & popd & exit /b 224)
findstr /C:"upload.maximum_size=3145728" "%PROPS%" >nul || (echo ERROR=APP_LIMIT_PROFILE_MISMATCH & popd & exit /b 225)
echo BOARD_PROFILE_LOCK=PASS
echo APP0_OFFSET=%APP0_OFFSET%
echo APP0_SIZE=0x300000

echo.
echo --- BUILD EXACT SCAN-FIX APPLICATION ---
set "BUILD=%TEMP%\farmcart_r814_scanfix_app0_build"
if exist "%BUILD%" rmdir /s /q "%BUILD%"
arduino-cli compile --fqbn "%FQBN%" --build-path "%BUILD%" esp32\SmartFarm_ESP32_5F
if errorlevel 1 (
  echo ERROR=CANONICAL_BUILD_FAILED
  popd
  exit /b 226
)

set "APPBIN="
for /r "%BUILD%" %%F in (*.ino.bin) do if not defined APPBIN set "APPBIN=%%~fF"
if not defined APPBIN (
  echo ERROR=APP_BINARY_NOT_FOUND
  popd
  exit /b 227
)
for %%F in ("!APPBIN!") do set "APP_BYTES=%%~zF"
echo APP_BINARY=!APPBIN!
echo APP_BYTES=!APP_BYTES!
if !APP_BYTES! GEQ %APP0_SIZE_DEC% (
  echo ERROR=APP_BINARY_EXCEEDS_APP0
  popd
  exit /b 228
)
for /f "tokens=1" %%H in ('certutil -hashfile "!APPBIN!" SHA256 ^| findstr /R /V "hash CertUtil"') do if not defined APP_SHA256 set "APP_SHA256=%%H"
echo APP_SHA256=!APP_SHA256!
echo APP_BUILD=PASS

for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
set "EVIDENCE=%REPO%\..\backups\farmcart_r814_scanfix_app0_%PORT%_!TS!"
mkdir "!EVIDENCE!" >nul 2>nul
copy /y "!APPBIN!" "!EVIDENCE!\scanfix_app0.bin" >nul
> "!EVIDENCE!\APP_SHA256.txt" echo !APP_SHA256!  scanfix_app0.bin
echo EVIDENCE_DIR=!EVIDENCE!

echo.
echo --- MANUAL ROM IDENTITY GATE: NO RESET, NO STUB, 115200 ---
echo REQUIREMENT=Board must already be in BOOT-held power-on ROM download mode.
python -m esptool --chip esp32s3 --port %PORT% -b 115200 --before no-reset --after no-reset --no-stub chip-id > "%TEMP%\farmcart_app0_chip.txt" 2>&1
type "%TEMP%\farmcart_app0_chip.txt"
if errorlevel 1 (
  echo ERROR=ROM_CHIP_ID_FAILED
  popd
  exit /b 229
)
findstr /I /C:"ESP32-S3" "%TEMP%\farmcart_app0_chip.txt" >nul || (
  echo ERROR=NOT_ESP32_S3
  popd
  exit /b 230
)
findstr /I /C:"%EXPECTED_MAC%" "%TEMP%\farmcart_app0_chip.txt" >nul || (
  echo ERROR=MAC_MISMATCH
  popd
  exit /b 231
)
echo ROM_CHIP_ID=PASS
echo MAC_LOCK=PASS

python -m esptool --chip esp32s3 --port %PORT% -b 115200 --before no-reset --after no-reset --no-stub flash-id > "%TEMP%\farmcart_app0_flashid.txt" 2>&1
type "%TEMP%\farmcart_app0_flashid.txt"
if errorlevel 1 (
  echo ERROR=ROM_FLASH_ID_FAILED
  popd
  exit /b 232
)
findstr /I /C:"Detected flash size: 16MB" "%TEMP%\farmcart_app0_flashid.txt" >nul || (
  echo ERROR=FLASH_SIZE_NOT_16MB
  popd
  exit /b 233
)
echo ROM_FLASH_ID=PASS
echo FLASH_SIZE_16MB=PASS

echo.
echo === APP0 FLASH WRITE START ===
echo APPROVAL_TOKEN=PASS
echo FLASH_BAUD=115200
echo STUB=DISABLED
echo COMPRESSION=DISABLED
echo OFFSET=%APP0_OFFSET%
echo WRITE_SCOPE=APP0_ONLY
echo NVS_WRITE=NO
echo OTADATA_WRITE=NO
echo PARTITION_TABLE_WRITE=NO
echo BOOTLOADER_WRITE=NO
echo ERASE_ALL=NO

python -m esptool --chip esp32s3 --port %PORT% -b 115200 --before no-reset --after no-reset --no-stub write-flash --no-compress %APP0_OFFSET% "!APPBIN!"
if errorlevel 1 (
  echo APP0_FLASH_STATUS=FAIL
  echo DEVICE_LEFT_IN_BOOTLOADER=EXPECTED
  echo ACTION=Do not reset yet. Return this complete output.
  popd
  exit /b 234
)

echo.
echo === APP0 FLASH RESULT ===
echo APP0_FLASH_STATUS=PASS
echo ESPTOOL_VERIFY=PASS_IF_WRITE_COMMAND_RETURNED_ZERO
echo PORT=%PORT%
echo APP0_OFFSET=%APP0_OFFSET%
echo APP_SHA256=!APP_SHA256!
echo EVIDENCE_DIR=!EVIDENCE!
echo NVS_PRESERVED=YES
echo OTADATA_PRESERVED=YES
echo PARTITION_TABLE_PRESERVED=YES
echo BOOTLOADER_PRESERVED=YES
echo ERASE_ALL=NO
echo DEVICE_LEFT_IN_BOOTLOADER=YES
echo NEXT=Press EN/RST once, then run runtime scan-fix verification.
popd
exit /b 0
