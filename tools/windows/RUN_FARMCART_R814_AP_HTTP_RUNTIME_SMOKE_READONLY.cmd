@echo off
setlocal EnableExtensions

echo === FARMCART SMARTGROW R8.14 - AP HTTP RUNTIME SMOKE WRAPPER ===
echo MODE=READ_ONLY
echo SOURCE_WRITE=NO
echo ESP_WRITE=NO
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo HTTP_WRITE=NO
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo MERGE_MAIN=NO
echo.
echo REQUIREMENT=Windows must be connected to the ESP32 SmartFarm-* Wi-Fi AP.
echo AP_PASSWORD=smartfarm123
echo EXPECTED_AP_IP=192.168.4.1
echo SAFETY=Keep relay load/pump power disconnected.
echo.

set "REPO=%~dp0\..\.."
set "PS1=%~dp0RUN_FARMCART_R814_AP_HTTP_RUNTIME_SMOKE_READONLY.ps1"

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 120
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=%BRANCH%
echo HEAD=%HEAD%

if /I not "%BRANCH%"=="candidate/r8.14-stability-1" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 121
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 122
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -BaseUrl "http://192.168.4.1"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
  echo.
  echo If HTTP_GET_FAIL occurred, connect Windows Wi-Fi to the visible SmartFarm-* AP
  echo using password smartfarm123, then rerun this wrapper.
  echo Keep relay load/pump power disconnected.
)

popd
exit /b %RC%
