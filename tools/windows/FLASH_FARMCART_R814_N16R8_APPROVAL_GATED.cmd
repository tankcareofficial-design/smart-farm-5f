@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - APPROVAL-GATED FLASH ===
echo MODE=BACKUP_BUILD_AND_FLASH
echo SOURCE_WRITE=NO
echo MERGE_MAIN=NO
echo.
echo WARNING=This runner writes bootloader, partition table, OTA data and application firmware.
echo SAFETY=Keep relay load/pump power disconnected during flashing.
echo.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "RUNTIME_SHA=566cc4843a121dfefc9d7583f1398736b134c186"
set "EXPECTED_FW=0.8.0-5f-r8.14-stability-1"
set "FQBN=esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi"
set "PORT=%~1"
set "APPROVAL=%~2"
set "APPROVAL_TOKEN=FLASH_R814_N16R8"
set "REPO=%~dp0\..\.."

if not defined PORT (
  echo ERROR=NO_PORT
  echo USAGE=call tools\windows\FLASH_FARMCART_R814_N16R8_APPROVAL_GATED.cmd COM5 FLASH_R814_N16R8
  exit /b 80
)

if /I not "%APPROVAL%"=="%APPROVAL_TOKEN%" (
  echo FLASH_APPROVAL=BLOCKED
  echo REQUIRED_TOKEN=%APPROVAL_TOKEN%
  echo No device write was performed.
  exit /b 81
)

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 82
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
for /f "delims=" %%M in ('git rev-parse origin/main 2^>nul') do set "MAIN=%%M"

echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo ORIGIN_MAIN=!MAIN!
echo PORT=%PORT%
echo FQBN=%FQBN%

if /I not "!BRANCH!"=="%EXPECTED_BRANCH%" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 83
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 84
)

git cat-file -e %RUNTIME_SHA% 2>nul
if errorlevel 1 (
  echo ERROR=RUNTIME_SHA_MISSING_LOCALLY
  popd
  exit /b 85
)

git diff --quiet %RUNTIME_SHA% HEAD -- esp32 flutter
if errorlevel 1 (
  echo ERROR=RUNTIME_SOURCE_DRIFT
  git diff --stat %RUNTIME_SHA% HEAD -- esp32 flutter
  popd
  exit /b 86
)
echo RUNTIME_SOURCE_LOCK=PASS

findstr /C:"%EXPECTED_FW%" "esp32\SmartFarm_ESP32_5F\Config.h" >nul
if errorlevel 1 (
  echo ERROR=FW_VERSION_MISMATCH
  popd
  exit /b 87
)
echo FW_VERSION_LOCK=PASS

echo.
echo --- CANONICAL N16R8 PROFILE ASSERTION ---
set "PROPS=%TEMP%\farmcart_r814_flash_properties.txt"
arduino-cli compile --fqbn "%FQBN%" --show-properties esp32\SmartFarm_ESP32_5F > "%PROPS%" 2>&1
if errorlevel 1 (
  type "%PROPS%"
  echo ERROR=BOARD_PROFILE_PROPERTIES_FAILED
  popd
  exit /b 88
)
findstr /C:"build.flash_size=16MB" "%PROPS%" >nul || (echo ERROR=FLASH_SIZE_PROFILE_MISMATCH & popd & exit /b 89)
findstr /C:"build.memory_type=qio_opi" "%PROPS%" >nul || (echo ERROR=MEMORY_TYPE_PROFILE_MISMATCH & popd & exit /b 90)
findstr /C:"build.partitions=app3M_fat9M_16MB" "%PROPS%" >nul || (echo ERROR=PARTITION_PROFILE_MISMATCH & popd & exit /b 91)
findstr /C:"build.psram_type=opi" "%PROPS%" >nul || (echo ERROR=PSRAM_PROFILE_MISMATCH & popd & exit /b 92)
findstr /C:"upload.maximum_size=3145728" "%PROPS%" >nul || (echo ERROR=APP_LIMIT_PROFILE_MISMATCH & popd & exit /b 93)
echo BOARD_PROFILE_LOCK=PASS

echo.
echo --- DEVICE IDENTITY GATE ---
python -m esptool --port %PORT% chip-id > "%TEMP%\farmcart_flash_chip.txt" 2>&1
type "%TEMP%\farmcart_flash_chip.txt"
findstr /I /C:"ESP32-S3" "%TEMP%\farmcart_flash_chip.txt" >nul
if errorlevel 1 (
  echo ERROR=NOT_ESP32_S3
  popd
  exit /b 94
)

python -m esptool --port %PORT% flash-id > "%TEMP%\farmcart_flash_id.txt" 2>&1
type "%TEMP%\farmcart_flash_id.txt"
findstr /I /C:"Detected flash size: 16MB" "%TEMP%\farmcart_flash_id.txt" >nul
if errorlevel 1 (
  echo ERROR=FLASH_SIZE_NOT_16MB
  popd
  exit /b 95
)
echo DEVICE_IDENTITY_GATE=PASS

echo.
echo --- FULL 16MB PRE-FLASH BACKUP ---
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
set "BACKUP_ROOT=%REPO%\..\backups"
set "BACKUP=!BACKUP_ROOT!\farmcart_r814_preflash_%PORT%_!TS!"
mkdir "!BACKUP!" >nul 2>nul
if errorlevel 1 (
  echo ERROR=BACKUP_DIR_CREATE_FAILED
  popd
  exit /b 96
)
echo BACKUP_DIR=!BACKUP!

python -m esptool --port %PORT% read-flash 0x0 0x1000000 "!BACKUP!\full_flash_16MB_before_r814.bin"
if errorlevel 1 (
  echo ERROR=FULL_FLASH_BACKUP_FAILED
  popd
  exit /b 97
)
for /f "tokens=1" %%H in ('certutil -hashfile "!BACKUP!\full_flash_16MB_before_r814.bin" SHA256 ^| findstr /R /V "hash CertUtil"') do if not defined BACKUP_SHA256 set "BACKUP_SHA256=%%H"
echo BACKUP_SHA256=!BACKUP_SHA256!

echo.
echo --- BUILD CANONICAL N16R8 IMAGE ---
set "BUILD=%TEMP%\farmcart_r814_flash_build"
if exist "%BUILD%" rmdir /s /q "%BUILD%"
arduino-cli compile --fqbn "%FQBN%" --build-path "%BUILD%" esp32\SmartFarm_ESP32_5F
if errorlevel 1 (
  echo ERROR=CANONICAL_BUILD_FAILED
  popd
  exit /b 98
)

set "APPBIN="
for /r "%BUILD%" %%F in (*.ino.bin) do if not defined APPBIN set "APPBIN=%%~fF"
if not defined APPBIN (
  echo ERROR=APP_BINARY_NOT_FOUND
  popd
  exit /b 99
)
for %%F in ("!APPBIN!") do echo APP_BYTES=%%~zF
for /f "tokens=1" %%H in ('certutil -hashfile "!APPBIN!" SHA256 ^| findstr /R /V "hash CertUtil"') do if not defined APP_SHA256 set "APP_SHA256=%%H"
echo APP_SHA256=!APP_SHA256!

mkdir "!BACKUP!\build" >nul 2>nul
for %%F in ("%BUILD%\*.bin") do copy /y "%%~fF" "!BACKUP!\build\" >nul
if exist "%BUILD%\partitions.csv" copy /y "%BUILD%\partitions.csv" "!BACKUP!\build\" >nul
if exist "%BUILD%\flash_args" copy /y "%BUILD%\flash_args" "!BACKUP!\build\" >nul

echo.
echo --- BUILD BINARY HASHES ---
powershell -NoProfile -Command "Get-ChildItem '%BUILD%\*.bin' | Get-FileHash -Algorithm SHA256 | Format-Table -AutoSize"

echo.
echo === FLASH WRITE START ===
echo APPROVAL_TOKEN=PASS
echo ERASE_ALL=NO
echo PRESERVE_NVS_EXPECTED=YES
echo WRITES=BOOTLOADER,PARTITION_TABLE,OTA_DATA,APP
arduino-cli upload --fqbn "%FQBN%" --port "%PORT%" --input-dir "%BUILD%" esp32\SmartFarm_ESP32_5F
if errorlevel 1 (
  echo FLASH_STATUS=FAIL
  echo BACKUP_DIR=!BACKUP!
  echo Do not run additional writes. Return this complete output for rollback review.
  popd
  exit /b 100
)

echo.
echo === FLASH RESULT ===
echo FLASH_STATUS=PASS
echo PORT=%PORT%
echo FQBN=%FQBN%
echo APP_SHA256=!APP_SHA256!
echo BACKUP_DIR=!BACKUP!
echo BACKUP_SHA256=!BACKUP_SHA256!
echo ERASE_ALL=NO
echo HARDWARE_ACCEPTANCE=NOT_YET_PASS
echo RUNTIME_ACCEPTANCE=NOT_YET_PASS
echo NEXT=Return this complete output before reconnecting relay load/pump power.
echo.
echo Copy this entire output back to ChatGPT.
popd
endlocal
