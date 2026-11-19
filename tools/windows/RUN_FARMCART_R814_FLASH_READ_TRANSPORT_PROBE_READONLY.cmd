@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART R8.14 - FLASH READ TRANSPORT PROBE READONLY ===
echo MODE=READ_ONLY
echo ESP_WRITE=NO
echo FLASH_WRITE=NO
echo FLASH_ERASE=NO
echo NVS_WRITE=NO
echo TARGET=COM7
echo BAUD_LOCK=115200_ONLY
echo RANGE=0x8000+0x1000
echo PURPOSE=Verify stable 4KB read at the project-locked transport rate.
echo.

set "PORT=%~1"
if "%PORT%"=="" set "PORT=COM7"
set "REPO=%~dp0\..\.."
set "OUT=%TEMP%\farmcart_flash_probe_115200"

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 200
)

if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%OUT%" >nul 2>nul

echo --- STUB READ 4KB BAUD=115200 ---
python -m esptool --chip esp32s3 --port %PORT% -b 115200 read-flash 0x8000 0x1000 "%OUT%\stub_115200.bin"
set "STUB_RC=!ERRORLEVEL!"
set "STUB_BYTES=0"
if exist "%OUT%\stub_115200.bin" for %%F in ("%OUT%\stub_115200.bin") do set "STUB_BYTES=%%~zF"
if "!STUB_RC!"=="0" if "!STUB_BYTES!"=="4096" (
  echo PROBE_STUB_115200=PASS BYTES=!STUB_BYTES!
) else (
  echo PROBE_STUB_115200=FAIL RC=!STUB_RC! BYTES=!STUB_BYTES!
)

echo.
echo --- NO-STUB READ 4KB BAUD=115200 ---
python -m esptool --chip esp32s3 --port %PORT% -b 115200 --no-stub read-flash --flash-size 16MB 0x8000 0x1000 "%OUT%\nostub_115200.bin"
set "NOSTUB_RC=!ERRORLEVEL!"
set "NOSTUB_BYTES=0"
if exist "%OUT%\nostub_115200.bin" for %%F in ("%OUT%\nostub_115200.bin") do set "NOSTUB_BYTES=%%~zF"
if "!NOSTUB_RC!"=="0" if "!NOSTUB_BYTES!"=="4096" (
  echo PROBE_NOSTUB_115200=PASS BYTES=!NOSTUB_BYTES!
) else (
  echo PROBE_NOSTUB_115200=FAIL RC=!NOSTUB_RC! BYTES=!NOSTUB_BYTES!
)

echo.
echo === PROBE COMPLETE ===
echo BAUD_LOCK=115200_ONLY
echo FLASH_WRITE=NO
echo NEXT=Return complete output. Do not change baud.
popd
exit /b 0
