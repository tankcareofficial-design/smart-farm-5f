@echo off
setlocal EnableExtensions

echo === FARMCART R8.14 WIFI SCAN-FIX RUNTIME WRAPPER ===
echo MODE=READ_ONLY
echo HTTP_METHOD=GET_ONLY
echo ESP_WRITE=NO
echo NVS_WRITE=NO
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo FLASH_WRITE=NO
echo.
echo REQUIREMENT=Windows must be connected to the visible SmartFarm-* Wi-Fi AP.
echo AP_PASSWORD=smartfarm123
echo EXPECTED_AP_IP=192.168.4.1
echo SAFETY=Keep relay load/pump power disconnected.
echo.

set "REPO=%~dp0\..\.."
set "PS1=%~dp0RUN_FARMCART_R814_WIFI_SCANFIX_RUNTIME_READONLY.ps1"

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 170
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=%BRANCH%
echo HEAD=%HEAD%

if /I not "%BRANCH%"=="candidate/r8.14-stability-1" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 171
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 172
)

git diff --quiet 30ab9bbadcc601b4978d416efb985af84ba9145e HEAD -- esp32 flutter
if errorlevel 1 (
  echo ERROR=SCANFIX_RUNTIME_SOURCE_DRIFT
  git diff --stat 30ab9bbadcc601b4978d416efb985af84ba9145e HEAD -- esp32 flutter
  popd
  exit /b 173
)
echo SCANFIX_RUNTIME_SOURCE_LOCK=PASS

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -BaseUrl "http://192.168.4.1" -MaxPolls 30 -PollDelayMs 350
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
