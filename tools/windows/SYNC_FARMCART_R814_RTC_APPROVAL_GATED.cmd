@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - RTC SYNC APPROVAL GATE ===
echo MODE=RTC_SYNC_APPROVED
echo RTC_WRITE=YES
echo FLASH_WRITE=NO
echo NVS_WRITE=NO
echo RELAY_COMMAND=NO
echo WIFI_CONFIG_WRITE=NO
echo MERGE_MAIN=NO
echo.
echo REQUIREMENT=Windows must be connected to the ESP32 SmartFarm-* Wi-Fi AP.
echo EXPECTED_AP_IP=192.168.4.1
echo TIME_SOURCE=WINDOWS_LOCAL_TIME
echo REQUIRED_UTC_OFFSET=+07:00
echo SAFETY=Keep pump/actuator load power disconnected.
echo.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "RUNTIME_SHA=566cc4843a121dfefc9d7583f1398736b134c186"
set "APPROVAL=%~1"
set "APPROVAL_TOKEN=SYNC_RTC_R814"
set "REPO=%~dp0\..\.."
set "PS1=%~dp0SYNC_FARMCART_R814_RTC_APPROVAL_GATED.ps1"

if /I not "%APPROVAL%"=="%APPROVAL_TOKEN%" (
  echo RTC_SYNC_APPROVAL=BLOCKED
  echo REQUIRED_TOKEN=%APPROVAL_TOKEN%
  echo No RTC write was performed.
  exit /b 130
)

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 131
)

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
for /f "delims=" %%H in ('git rev-parse HEAD 2^>nul') do set "HEAD=%%H"
for /f "delims=" %%M in ('git rev-parse origin/main 2^>nul') do set "MAIN=%%M"

echo BRANCH=!BRANCH!
echo HEAD=!HEAD!
echo ORIGIN_MAIN=!MAIN!

if /I not "!BRANCH!"=="%EXPECTED_BRANCH%" (
  echo ERROR=WRONG_BRANCH
  popd
  exit /b 132
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 133
)

git cat-file -e %RUNTIME_SHA% 2>nul
if errorlevel 1 (
  echo ERROR=RUNTIME_SHA_MISSING_LOCALLY
  popd
  exit /b 134
)

git diff --quiet %RUNTIME_SHA% HEAD -- esp32 flutter
if errorlevel 1 (
  echo ERROR=RUNTIME_SOURCE_DRIFT
  git diff --stat %RUNTIME_SHA% HEAD -- esp32 flutter
  popd
  exit /b 135
)
echo RUNTIME_SOURCE_LOCK=PASS

echo RTC_SYNC_APPROVAL=PASS
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -BaseUrl "http://192.168.4.1"
set "RC=!ERRORLEVEL!"

popd
exit /b !RC!
