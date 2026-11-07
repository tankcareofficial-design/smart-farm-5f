@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - BOARD CONFIG AUDIT READONLY ===
echo MODE=BOARD_CONFIG_AUDIT_READONLY
echo SOURCE_WRITE=NO
echo DEVICE_WRITE=NO
echo FLASH_WRITE=NO
echo FLASH_ERASE=NO
echo NVS_READ=NO
echo NVS_WRITE=NO
echo MERGE_MAIN=NO
echo.

set "REPO=%~dp0\..\.."
set "FQBN=esp32:esp32:esp32s3"
set "PORT=%~1"

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 70
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo FQBN=%FQBN%
if defined PORT echo SELECTED_PORT=%PORT%

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 71
)

echo.
echo --- BOARD DETAILS / CONFIGURATION OPTIONS ---
arduino-cli board details -b %FQBN% -f
if errorlevel 1 (
  echo BOARD_DETAILS=FAIL
  popd
  exit /b 72
)
echo BOARD_DETAILS=PASS

echo.
echo --- EFFECTIVE BUILD PROPERTIES ---
set "PROPS=%TEMP%\farmcart_r814_build_properties.txt"
arduino-cli compile --fqbn %FQBN% --show-properties esp32\SmartFarm_ESP32_5F > "%PROPS%" 2>&1
if errorlevel 1 (
  type "%PROPS%"
  echo BUILD_PROPERTIES=FAIL
  popd
  exit /b 73
)

findstr /I /C:"build.flash_size" /C:"build.flash_mode" /C:"build.flash_freq" /C:"build.partitions" /C:"build.psram" /C:"build.memory_type" /C:"upload.maximum_size" /C:"upload.maximum_data_size" /C:"upload.flash_size" /C:"build.board" "%PROPS%"
echo BUILD_PROPERTIES=PASS

echo.
echo --- COM / DEVICE DISCOVERY ---
arduino-cli board list
if defined PORT (
  echo.
  echo --- SELECTED DEVICE CHIP / FLASH READ ONLY ---
  python -m esptool --port %PORT% chip-id
  if errorlevel 1 (
    echo CHIP_ID_READ=FAIL
    popd
    exit /b 74
  )
  python -m esptool --port %PORT% flash-id
  if errorlevel 1 (
    echo FLASH_ID_READ=FAIL
    popd
    exit /b 75
  )
  echo CHIP_FLASH_ID_READ=PASS
)

echo.
echo === RESULT ===
echo BOARD_DETAILS=PASS
echo BUILD_PROPERTIES=PASS
echo SOURCE_WRITE=NO
echo DEVICE_WRITE=NO
echo FLASH_WRITE=NO
echo FLASH_ERASE=NO
echo NVS_READ=NO
echo NVS_WRITE=NO
echo NEXT=Review effective FlashSize/PartitionScheme/PSRAM options before preparing any flash command.
echo.
echo Copy this entire output back to ChatGPT.
popd
endlocal
