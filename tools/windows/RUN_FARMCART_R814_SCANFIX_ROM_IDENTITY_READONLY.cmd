@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART R8.14 SCAN-FIX - ROM IDENTITY READONLY DIRECT ===
echo MODE=READ_ONLY
echo ESP_WRITE=NO
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo MERGE_MAIN=NO
echo.

set "PORT=%~1"
if "%PORT%"=="" set "PORT=COM5"

set "REPO=%~dp0\..\.."

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 190
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo PORT=%PORT%

if /I not "!BRANCH!"=="candidate/r8.14-stability-1" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 194
)

echo.
echo --- ROM CHIP ID NO-STUB 115200 ---
python -m esptool --chip esp32s3 --port %PORT% -b 115200 --no-stub chip-id > "%TEMP%\farmcart_scanfix_rom_chip.txt" 2>&1
set "CHIP_RC=!ERRORLEVEL!"
type "%TEMP%\farmcart_scanfix_rom_chip.txt"
findstr /I /C:"ESP32-S3" "%TEMP%\farmcart_scanfix_rom_chip.txt" >nul
if errorlevel 1 (
  echo ROM_CHIP_ID=FAIL RC=!CHIP_RC!
  popd
  exit /b 191
)
echo ROM_CHIP_ID=PASS

echo.
echo --- ROM FLASH ID NO-STUB 115200 ---
python -m esptool --chip esp32s3 --port %PORT% -b 115200 --no-stub flash-id > "%TEMP%\farmcart_scanfix_rom_flash.txt" 2>&1
set "FLASH_RC=!ERRORLEVEL!"
type "%TEMP%\farmcart_scanfix_rom_flash.txt"
if not "!FLASH_RC!"=="0" (
  echo ROM_FLASH_ID=FAIL RC=!FLASH_RC!
  popd
  exit /b 192
)
findstr /I /C:"Detected flash size: 16MB" "%TEMP%\farmcart_scanfix_rom_flash.txt" >nul
if errorlevel 1 (
  echo ROM_FLASH_SIZE_16MB=FAIL
  popd
  exit /b 193
)
echo ROM_FLASH_ID=PASS
echo ROM_FLASH_SIZE_16MB=PASS

echo.
echo === ROM IDENTITY RESULT ===
echo ROM_IDENTITY_GATE=PASS
echo NEXT=Approved scan-fix flash may continue with corrected runner.
popd
exit /b 0
