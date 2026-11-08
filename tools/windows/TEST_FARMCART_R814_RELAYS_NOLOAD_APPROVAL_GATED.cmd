@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - RELAY NO-LOAD APPROVAL GATE ===
echo MODE=RELAY_NOLOAD_APPROVED
echo RELAY_COMMAND=YES
echo FLASH_WRITE=NO
echo RTC_WRITE=NO
echo NVS_WRITE=YES_RELAY_STATE_PERSISTENCE
echo WIFI_CONFIG_WRITE=NO
echo MERGE_MAIN=NO
echo.
echo SAFETY=Relay board/control wiring only. Pump/valve/actuator/load power MUST be disconnected.
echo.

set "EXPECTED_BRANCH=candidate/r8.14-stability-1"
set "RUNTIME_SHA=566cc4843a121dfefc9d7583f1398736b134c186"
set "TOKEN=%~1"
set "REQUIRED_TOKEN=TEST_RELAYS_NOLOAD_R814"
set "REPO=%~dp0\..\.."
set "PS1=%~dp0TEST_FARMCART_R814_RELAYS_NOLOAD_APPROVAL_GATED.ps1"

if /I not "%TOKEN%"=="%REQUIRED_TOKEN%" (
  echo RELAY_TEST_APPROVAL=BLOCKED
  echo REQUIRED_TOKEN=%REQUIRED_TOKEN%
  echo No relay command was performed.
  exit /b 150
)

pushd "%REPO%" >nul 2>nul
if errorlevel 1 (
  echo ERROR=REPO_NOT_FOUND
  exit /b 151
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
  exit /b 152
)

for /f "delims=" %%S in ('git status --porcelain') do (
  echo ERROR=WORKTREE_NOT_CLEAN
  git status --short
  popd
  exit /b 153
)

git cat-file -e %RUNTIME_SHA% 2>nul
if errorlevel 1 (
  echo ERROR=RUNTIME_SHA_MISSING_LOCALLY
  popd
  exit /b 154
)

git diff --quiet %RUNTIME_SHA% HEAD -- esp32 flutter
if errorlevel 1 (
  echo ERROR=RUNTIME_SOURCE_DRIFT
  git diff --stat %RUNTIME_SHA% HEAD -- esp32 flutter
  popd
  exit /b 155
)

echo RUNTIME_SOURCE_LOCK=PASS
echo RELAY_TEST_APPROVAL=PASS

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -BaseUrl "http://192.168.4.1"
set "RC=!ERRORLEVEL!"

popd
exit /b !RC!
