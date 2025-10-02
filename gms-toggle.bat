@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem GMS Toggle Menu - Disable/Enable Google Play services (GMS) via ADB
rem Run by double-click or from CMD; place next to adb.exe or add adb to PATH

title GMS Toggle Menu (Stable)

set "SCRIPT_DIR=%~dp0"
set "ADB_BIN=adb"
if exist "%SCRIPT_DIR%adb.exe" set "ADB_BIN=%SCRIPT_DIR%adb.exe"

%ADB_BIN% start-server >nul 2>&1

set "TARGET="
call :print_header

:menu
echo.
echo [Target: %TARGET%]
echo.
echo  1) Disable Google Play services
echo  2) Enable Google Play services
echo  3) Show status
echo  4) Diagnose
echo  5) Change target (SERIAL or HOST:PORT)
echo  0) Exit
echo.
choice /c 123450 /n /m "Select: "
set "OPT=%errorlevel%"
if "%OPT%"=="6" goto end
if "%OPT%"=="5" goto change_target
if "%OPT%"=="4" goto do_diag
if "%OPT%"=="3" goto do_status
if "%OPT%"=="2" goto do_enable
if "%OPT%"=="1" goto do_disable
goto menu

:ensure_adb
rem Ensure adb exists either via explicit path or PATH
if exist "%ADB_BIN%" goto :eof
where adb >nul 2>&1 && goto :eof
echo [ERROR] adb not found. Put this .bat next to adb.exe (platform-tools) or add to PATH.
pause
goto menu

:ensure_connected
call :ensure_adb
set "CONNECTED_OK=no"
if "%TARGET%"=="" (
  for /f "skip=1 tokens=1,2" %%A in ('%ADB_BIN% devices') do (
    if "%%B"=="device" (
      set "TARGET=%%A"
      goto ec_try
    )
  )
  for %%H in (127.0.0.1:7555 127.0.0.1:5555 127.0.0.1:62001 127.0.0.1:21503 127.0.0.1:5557) do %ADB_BIN% connect %%H >nul 2>&1
  for /f "skip=1 tokens=1,2" %%C in ('%ADB_BIN% devices') do (
    if "%%D"=="device" (
      set "TARGET=%%C"
      goto ec_try
    )
  )
  echo [ERROR] No ADB device found.
  pause
  goto menu
) else (
  goto ec_try
)

:ec_try
set "_has_port="
for /f "tokens=1,2 delims=:" %%X in ("%TARGET%") do set "_has_port=%%Y"
if defined _has_port %ADB_BIN% connect "%TARGET%" >nul 2>&1
%ADB_BIN% -s "%TARGET%" shell echo ok >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Cannot reach "%TARGET%".
  pause
  goto menu
)
set "CONNECTED_OK=yes"
goto :eof

:packages_init
set "PACKAGES=com.google.android.gms com.google.android.gsf com.android.vending com.google.android.gsf.login com.google.android.syncadapters.calendar com.google.android.syncadapters.contacts com.google.android.onetimeinitializer com.google.android.backuptransport com.google.android.feedback com.google.android.configupdater com.google.android.partnersetup com.google.android.setupwizard com.google.android.apps.restore"
goto :eof

:do_disable
call :ensure_connected
if /i not "%CONNECTED_OK%"=="yes" goto menu
call :packages_init
cls
echo Disabling/uninstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do (
  echo [*] %%P
  %ADB_BIN% -s "%TARGET%" shell cmd package uninstall -k --user 0 %%P >nul 2>&1
  if errorlevel 1 %ADB_BIN% -s "%TARGET%" shell pm uninstall -k --user 0 %%P >nul 2>&1
  %ADB_BIN% -s "%TARGET%" shell pm disable-user --user 0 %%P >nul 2>&1
)
echo.
echo Done. Recommended reboot: %ADB_BIN% -s "%TARGET%" reboot
pause
goto menu

:do_enable
call :ensure_connected
if /i not "%CONNECTED_OK%"=="yes" goto menu
call :packages_init
cls
echo Enabling/reinstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do (
  echo [*] %%P
  %ADB_BIN% -s "%TARGET%" shell pm install-existing --user 0 %%P >nul 2>&1
  %ADB_BIN% -s "%TARGET%" shell pm enable --user 0 %%P >nul 2>&1
)
echo.
echo Done.
pause
goto menu

:do_status
call :ensure_connected
if /i not "%CONNECTED_OK%"=="yes" goto menu
call :packages_init
cls
echo Package ^| Installed ^| Enabled
echo --------------------------------
for %%P in (%PACKAGES%) do (
  set "INST=no"
  set "EN=n/a"
  for /f "usebackq delims=" %%A in (`%ADB_BIN% -s "%TARGET%" shell pm list packages --user 0 ^| findstr /C:"package:%%P"`) do set "INST=yes"
  if /i "!INST!"=="yes" (
    set "EN=yes"
    for /f "usebackq delims=" %%B in (`%ADB_BIN% -s "%TARGET%" shell pm list packages --user 0 -d ^| findstr /C:"package:%%P"`) do set "EN=no"
  )
  echo %%P ^| !INST! ^| !EN!
)
pause
goto menu

:do_diag
call :ensure_adb
cls
echo === ADB Version ===
%ADB_BIN% version
echo.
echo === Devices ===
%ADB_BIN% devices
echo.
if not "%TARGET%"=="" (
  echo === Target: %TARGET% ===
  %ADB_BIN% -s "%TARGET%" shell getprop ro.product.manufacturer
  %ADB_BIN% -s "%TARGET%" shell getprop ro.product.model
  %ADB_BIN% -s "%TARGET%" shell getprop ro.build.version.release
  %ADB_BIN% -s "%TARGET%" shell getprop ro.build.version.sdk
)
pause
goto menu

:change_target
set /p "TARGET=Enter SERIAL or HOST:PORT (e.g., 127.0.0.1:7555): "
goto menu

:print_header
cls
echo ======================================================
echo   GMS Toggle Menu - Google Play Services Controller
echo ======================================================
echo Put this .bat next to adb.exe or add adb to PATH.
echo.
goto :eof

:end
echo Exiting...
timeout /t 1 >nul
exit /b 0
