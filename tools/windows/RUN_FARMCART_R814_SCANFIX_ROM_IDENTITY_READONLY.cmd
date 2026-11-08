@echo off
setlocal EnableExtensions

echo === FARMCART R8.14 SCAN-FIX - ROM IDENTITY READONLY WRAPPER ===
echo MODE=READ_ONLY
echo ESP_WRITE=NO
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo MERGE_MAIN=NO
echo.

set "PORT=%~1"
if "%PORT%"=="" set "PORT=COM5"

set "REPO=%~dp0\..\.."
set "PS1=%~dp0RUN_FARMCART_R814_SCANFIX_ROM_IDENTITY_READONLY.ps1"

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 190
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
echo BRANCH=%BRANCH%
echo HEAD=%HEAD%

if /I not "%BRANCH%"=="candidate/r8.14-stability-1" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 194
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Port "%PORT%"
set "RC=%ERRORLEVEL%"

popd
exit /b %RC%
