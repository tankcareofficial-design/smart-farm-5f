@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART R8.14 SCAN-FIX POSTFLASH SMOKE - AUTO PORT ===
echo MODE=READ_ONLY
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo ESPTOOL_ACCESS=NO
echo PORT_SELECTION=USB_SERIAL_MATCH
echo EXPECTED_USB_SERIAL=14:C1:9F:50:B9:64
echo.

set "REPO=%~dp0\..\.."
set "TARGET_SERIAL=14:C1:9F:50:B9:64"

for /f "delims=" %%P in ('python -c "import serial.tools.list_ports as p; s='%TARGET_SERIAL%'.upper(); print(next((x.device for x in p.comports() if s in (x.hwid or '').upper()),''))"') do set "PORT=%%P"

if not defined PORT (
  echo ERROR=FARMCART_NATIVE_USB_NOT_FOUND
  echo CURRENT_PORTS:
  python -m serial.tools.list_ports -v
  exit /b 280
)

echo FARMART_NATIVE_PORT=!PORT!
python -m serial.tools.list_ports -v
echo.

call "%~dp0RUN_FARMCART_R814_SCANFIX_POSTFLASH_SMOKE_READONLY.cmd" !PORT!
exit /b !ERRORLEVEL!
