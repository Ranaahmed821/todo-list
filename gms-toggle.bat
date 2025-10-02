@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem GMS Toggle Menu - Disable/Enable Google Play services (GMS) via ADB
rem Run by double-click or from CMD in the same folder as adb.exe

title GMS Toggle Menu

set "PACKAGES=com.google.android.gms com.google.android.gsf com.android.vending com.google.android.gsf.login com.google.android.syncadapters.calendar com.google.android.syncadapters.contacts com.google.android.onetimeinitializer com.google.android.backuptransport com.google.android.feedback com.google.android.configupdater com.google.android.partnersetup com.google.android.setupwizard com.google.android.apps.restore"
set "TARGET="

where adb >nul 2>&1
if errorlevel 1 (
  echo [ERROR] adb not found in PATH. Put this .bat next to adb.exe (platform-tools).
  echo Press any key to exit...
  pause >nul
  exit /b 1
)

adb start-server >nul 2>&1

:menu
cls
echo ======================================================
echo   GMS Toggle Menu - Google Play Services Controller
echo ======================================================
echo Target: %TARGET%
echo.
echo   1 ^) Disable Google Play services
echo   2 ^) Enable Google Play services
echo   3 ^) Show status
echo   4 ^) Diagnose ADB and device info
echo   5 ^) Change target (enter SERIAL or HOST:PORT)
echo   0 ^) Exit
echo.
set "CHOICE="
set /p "CHOICE=Choose an option [0-5]: "

if "%CHOICE%"=="1" goto do_disable
if "%CHOICE%"=="2" goto do_enable
if "%CHOICE%"=="3" goto do_status
if "%CHOICE%"=="4" goto do_diag
if "%CHOICE%"=="5" goto change_target
if "%CHOICE%"=="0" goto end

echo Invalid choice.
echo Press any key to return to menu...
pause >nul
goto menu

:ensure_connected
rem Ensure there is a reachable ADB target; try auto-detect if empty.
set "CONNECTED_OK=no"
if "%TARGET%"=="" (
  for /f "skip=1 tokens=1,2" %%A in ('adb devices') do if "%%B"=="device" (
    set "TARGET=%%A"
    goto ec_try
  )
  for %%H in (127.0.0.1:7555 127.0.0.1:5555 127.0.0.1:62001 127.0.0.1:21503 127.0.0.1:5557) do adb connect %%H >nul 2>&1
  for /f "skip=1 tokens=1,2" %%C in ('adb devices') do if "%%D"=="device" (
    set "TARGET=%%C"
    goto ec_try
  )
  goto ec_no_device
) else (
  goto ec_try
)

:ec_try
rem If TARGET contains a colon, try to connect to ensure binding.
for /f "tokens=1,2 delims=:" %%X in ("%TARGET%") do set "_TMP_PORT=%%Y"
if defined _TMP_PORT adb connect "%TARGET%" >nul 2>&1
adb -s "%TARGET%" shell echo ok >nul 2>&1
if errorlevel 1 goto ec_unreachable
set "CONNECTED_OK=yes"
goto :eof

:ec_no_device
echo [ERROR] No ADB device found. Start your emulator or connect a device.
echo Tip: Use option 5 to enter HOST:PORT (for example, 127.0.0.1:7555)
echo Press any key to return to menu...
pause >nul
goto menu

:ec_unreachable
echo [ERROR] Unable to reach "%TARGET%" via ADB. Check ADB settings and port.
echo Press any key to return to menu...
pause >nul
goto menu

:do_disable
call :ensure_connected
if /i not "%CONNECTED_OK%"=="yes" goto menu
cls
echo Disabling/uninstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do call :disableOne %%P
echo.
echo Done. Recommended reboot: adb -s "%TARGET%" reboot
echo.
echo Press any key to return to menu...
pause >nul
goto menu

:disableOne
echo ^>^> %~1
adb -s "%TARGET%" shell cmd package uninstall -k --user 0 %~1 >nul 2>&1
if errorlevel 1 adb -s "%TARGET%" shell pm uninstall -k --user 0 %~1 >nul 2>&1
adb -s "%TARGET%" shell pm disable-user --user 0 %~1 >nul 2>&1
exit /b 0

:do_enable
call :ensure_connected
if /i not "%CONNECTED_OK%"=="yes" goto menu
cls
echo Enabling/reinstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do call :enableOne %%P
echo.
echo Done. You may reboot: adb -s "%TARGET%" reboot
echo.
echo Press any key to return to menu...
pause >nul
goto menu

:enableOne
echo ^>^> %~1
adb -s "%TARGET%" shell pm install-existing --user 0 %~1 >nul 2>&1
adb -s "%TARGET%" shell pm enable --user 0 %~1 >nul 2>&1
exit /b 0

:do_status
call :ensure_connected
if /i not "%CONNECTED_OK%"=="yes" goto menu
cls
echo Package ^| Installed ^| Enabled
echo --------------------------------
for %%P in (%PACKAGES%) do call :statusOne %%P
echo.
echo Press any key to return to menu...
pause >nul
goto menu

:statusOne
set "INST=no"
set "EN=n/a"
for /f "usebackq delims=" %%A in (`adb -s "%TARGET%" shell pm list packages --user 0 ^| findstr /C:"package:%~1"`) do set "INST=yes"
if /i "!INST!"=="yes" set "EN=yes"
for /f "usebackq delims=" %%B in (`adb -s "%TARGET%" shell pm list packages --user 0 -d ^| findstr /C:"package:%~1"`) do set "EN=no"
echo %~1 ^| !INST! ^| !EN!
exit /b 0

:do_diag
call :ensure_connected
if /i not "%CONNECTED_OK%"=="yes" goto menu
cls
echo === ADB Version ===
adb version
echo.
echo === Devices ===
adb devices
echo.
echo === Target: %TARGET% ===
adb -s "%TARGET%" shell getprop ro.product.manufacturer
adb -s "%TARGET%" shell getprop ro.product.model
adb -s "%TARGET%" shell getprop ro.build.version.release
adb -s "%TARGET%" shell getprop ro.build.version.sdk
echo.
echo === GMS Presence ===
adb -s "%TARGET%" shell pm path com.google.android.gms
adb -s "%TARGET%" shell pm path com.google.android.gsf
adb -s "%TARGET%" shell pm path com.android.vending
echo.
echo Press any key to return to menu...
pause >nul
goto menu

:change_target
cls
echo Current target: %TARGET%
set /p "TARGET=Enter SERIAL or HOST:PORT (example, 127.0.0.1:7555): "
echo.
echo Press any key to return to menu...
pause >nul
goto menu

:end
echo Exiting...
timeout /t 1 >nul
exit /b 0
