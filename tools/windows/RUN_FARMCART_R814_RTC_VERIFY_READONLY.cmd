@echo off
setlocal EnableExtensions

echo === FARMCART SMARTGROW R8.14 - RTC VERIFY READONLY WRAPPER ===
echo MODE=READ_ONLY
echo RTC_WRITE=NO
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo MERGE_MAIN=NO
echo.
echo REQUIREMENT=Windows connected to SmartFarm-* AP.
echo SAFETY=Keep pump/actuator load power disconnected.
echo.

set "REPO=%~dp0\..\.."
set "PS1=%~dp0RUN_FARMCART_R814_RTC_VERIFY_READONLY.ps1"

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 140
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=%BRANCH%
echo HEAD=%HEAD%

if /I not "%BRANCH%"=="candidate/r8.14-stability-1" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 141
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 142
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -BaseUrl "http://192.168.4.1"
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
