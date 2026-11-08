@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART R8.14 - FLASH READ TRANSPORT PROBE READONLY ===
echo MODE=READ_ONLY
echo ESP_WRITE=NO
echo FLASH_WRITE=NO
echo FLASH_ERASE=NO
echo NVS_WRITE=NO
echo TARGET=COM7
echo RANGE=0x8000+0x1000
echo PURPOSE=Find stable read baud before any full backup retry.
echo.

set "PORT=%~1"
if "%PORT%"=="" set "PORT=COM7"
set "REPO=%~dp0\..\.."
set "OUT=%TEMP%\farmcart_flash_probe"

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 200
)

if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%OUT%" >nul 2>nul

for %%B in (115200 57600 38400 19200) do (
  echo.
  echo --- STUB READ 4KB BAUD=%%B ---
  del /q "%OUT%\stub_%%B.bin" >nul 2>nul
  python -m esptool --chip esp32s3 --port %PORT% -b %%B read-flash 0x8000 0x1000 "%OUT%\stub_%%B.bin"
  set "RC=!ERRORLEVEL!"
  set "BYTES=0"
  if exist "%OUT%\stub_%%B.bin" for %%F in ("%OUT%\stub_%%B.bin") do set "BYTES=%%~zF"
  if "!RC!"=="0" if "!BYTES!"=="4096" (
    echo PROBE_STUB_BAUD_%%B=PASS BYTES=!BYTES!
  ) else (
    echo PROBE_STUB_BAUD_%%B=FAIL RC=!RC! BYTES=!BYTES!
  )

  echo --- NO-STUB READ 4KB BAUD=%%B ---
  del /q "%OUT%\nostub_%%B.bin" >nul 2>nul
  python -m esptool --chip esp32s3 --port %PORT% -b %%B --no-stub read-flash --flash-size 16MB 0x8000 0x1000 "%OUT%\nostub_%%B.bin"
  set "RC=!ERRORLEVEL!"
  set "BYTES=0"
  if exist "%OUT%\nostub_%%B.bin" for %%F in ("%OUT%\nostub_%%B.bin") do set "BYTES=%%~zF"
  if "!RC!"=="0" if "!BYTES!"=="4096" (
    echo PROBE_NOSTUB_BAUD_%%B=PASS BYTES=!BYTES!
  ) else (
    echo PROBE_NOSTUB_BAUD_%%B=FAIL RC=!RC! BYTES=!BYTES!
  )
)

echo.
echo === PROBE COMPLETE ===
echo FLASH_WRITE=NO
echo NEXT=Return complete output. Use only a baud/path that shows PASS.
popd
exit /b 0
