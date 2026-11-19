@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo === FARMCART SMARTGROW R8.14 - RESET MACHINE RESTORE / PREFLIGHT ===
echo MODE=RESTORE_AND_READONLY_PREFLIGHT
echo FLASH=NO
echo DEVICE_WRITE=NO
echo NVS_WRITE=NO
echo MERGE_MAIN=NO
echo.

set "REPO_URL=https://github.com/tankcareofficial-design/smart-farm-5f.git"
set "BRANCH=candidate/r8.14-stability-1"

if exist D:\ (
  set "ROOT=D:\FarmCart"
) else (
  set "ROOT=%USERPROFILE%\FarmCart"
)
set "REPO=%ROOT%\smart-farm-5f"

where git >nul 2>nul
if errorlevel 1 (
  echo GIT=NOT_FOUND
  echo ACTION=Install Git first. If winget is available:
  echo winget install --id Git.Git -e --source winget
  exit /b 20
)

echo GIT=
git --version

if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>nul

if exist "%REPO%\.git" (
  echo REPO=EXISTS
  for /f "delims=" %%R in ('git -C "%REPO%" remote get-url origin 2^>nul') do set "ORIGIN=%%R"
  if /I not "!ORIGIN!"=="%REPO_URL%" (
    echo ERROR=ORIGIN_MISMATCH
    echo EXPECTED=%REPO_URL%
    echo ACTUAL=!ORIGIN!
    exit /b 21
  )
  for /f "delims=" %%S in ('git -C "%REPO%" status --porcelain') do (
    echo ERROR=WORKTREE_NOT_CLEAN
    echo Refusing to reset/switch because local changes exist.
    git -C "%REPO%" status --short
    exit /b 22
  )
) else (
  echo REPO=CLONE
  git clone "%REPO_URL%" "%REPO%"
  if errorlevel 1 exit /b 23
)

echo.
echo --- FETCH / CHECKOUT LATEST CANDIDATE ---
git -C "%REPO%" fetch --prune origin
if errorlevel 1 exit /b 24

git -C "%REPO%" checkout -B "%BRANCH%" "origin/%BRANCH%"
if errorlevel 1 exit /b 25

for /f "delims=" %%H in ('git -C "%REPO%" rev-parse HEAD') do set "HEAD=%%H"
for /f "delims=" %%M in ('git -C "%REPO%" log -1 --pretty^=%%s') do set "HEAD_MSG=%%M"
for /f "delims=" %%B in ('git -C "%REPO%" rev-parse origin/main') do set "MAIN=%%B"

echo REPO=%REPO%
echo BRANCH=%BRANCH%
echo HEAD=!HEAD!
echo HEAD_MSG=!HEAD_MSG!
echo ORIGIN_MAIN=!MAIN!
echo.
git -C "%REPO%" status --short --branch

echo.
echo --- TOOLCHAIN INVENTORY ---
where flutter >nul 2>nul
if errorlevel 1 (
  echo FLUTTER=NOT_FOUND
) else (
  echo FLUTTER=FOUND
  flutter --version
)

where dart >nul 2>nul
if errorlevel 1 (
  echo DART=NOT_FOUND
) else (
  echo DART=FOUND
  dart --version
)

where arduino-cli >nul 2>nul
if errorlevel 1 (
  echo ARDUINO_CLI=NOT_FOUND
) else (
  echo ARDUINO_CLI=FOUND
  arduino-cli version
)

where java >nul 2>nul
if errorlevel 1 (
  echo JAVA=NOT_FOUND
) else (
  echo JAVA=FOUND
  java -version
)

where adb >nul 2>nul
if errorlevel 1 (
  echo ADB=NOT_FOUND
) else (
  echo ADB=FOUND
  adb version
)

where python >nul 2>nul
if errorlevel 1 (
  echo PYTHON=NOT_FOUND
) else (
  echo PYTHON=FOUND
  python --version
)

echo ANDROID_HOME=%ANDROID_HOME%
echo ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%

echo.
echo --- SERIAL PORTS (READ ONLY) ---
powershell -NoProfile -Command "Get-CimInstance Win32_SerialPort ^| Select-Object DeviceID,Name,Description ^| Format-Table -AutoSize" 2>nul
if errorlevel 1 echo SERIAL_PORT_QUERY=UNAVAILABLE

echo.
echo --- HANDOFF / CHECKLIST PRESENCE ---
if exist "%REPO%\docs\handoff\FARMCART_SMARTGROW_CONTINUATION_HANDOFF_R8_14_20261107.md" (
  echo HANDOFF=FOUND
) else (
  echo HANDOFF=MISSING
)
if exist "%REPO%\docs\TEST_CHECKLIST_R8_14_STABILITY.md" (
  echo R814_CHECKLIST=FOUND
) else (
  echo R814_CHECKLIST=MISSING
)

echo.
echo === RESULT ===
echo SOURCE_RESTORED=YES
echo SOURCE_WRITE=NO
echo FLASH=NO
echo HARDWARE_TEST=NOT_STARTED
echo NEXT=Install/verify missing toolchain, then R8.14 hardware acceptance preflash gate.
echo.
echo Copy this entire output back to ChatGPT.
endlocal
