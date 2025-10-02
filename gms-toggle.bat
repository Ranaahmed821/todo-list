@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem gms-toggle.bat - Disable/Enable Google Play (GMS) packages via ADB
rem Usage: gms-toggle.bat [disable|enable|status|diag] [SERIAL_OR_HOST:PORT]
rem If target is omitted, the script auto-detects the first connected device.

set "ACTION=%~1"
set "TARGET=%~2"

if /i "%ACTION%"=="" (
  echo Usage: %~nx0 [disable^|enable^|status^|diag] [SERIAL_OR_HOST:PORT]
  exit /b 1
)

where adb >nul 2>&1
if errorlevel 1 (
  echo Error: adb not found in PATH. Install Platform-Tools or run from its folder.
  exit /b 1
)

adb start-server >nul 2>&1

rem Auto-detect device if TARGET not provided
if "%TARGET%"=="" (
  for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" (
      set "TARGET=%%A"
      goto :got_target
    )
  )
  rem Try connecting to common emulator endpoints
  for %%H in (127.0.0.1:7555 127.0.0.1:5555 127.0.0.1:62001 127.0.0.1:21503 127.0.0.1:5557) do (
    adb connect %%H >nul 2>&1
  )
  for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" (
      set "TARGET=%%A"
      goto :got_target
    )
  )
  echo No ADB device found. Connect your emulator or pass [SERIAL_OR_HOST:PORT].
  exit /b 1
)

:got_target
adb -s "%TARGET%" shell echo ok >nul 2>&1
if errorlevel 1 (
  echo Unable to reach "%TARGET%" via ADB. Ensure ADB is enabled and the port is correct.
  exit /b 1
)

set "PACKAGES=com.google.android.gms com.google.android.gsf com.android.vending com.google.android.gsf.login com.google.android.syncadapters.calendar com.google.android.syncadapters.contacts com.google.android.onetimeinitializer com.google.android.backuptransport com.google.android.feedback com.google.android.configupdater com.google.android.partnersetup com.google.android.setupwizard com.google.android.apps.restore"

if /i "%ACTION%"=="disable" goto :do_disable
if /i "%ACTION%"=="enable" goto :do_enable
if /i "%ACTION%"=="status" goto :do_status
if /i "%ACTION%"=="diag" goto :do_diag

echo Unknown action: %ACTION%
echo Usage: %~nx0 [disable^|enable^|status^|diag] [SERIAL_OR_HOST:PORT]
exit /b 1

:do_disable
echo Disabling/uninstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do (
  echo ^>^> %%P
  rem Try modern uninstall command first
  adb -s "%TARGET%" shell cmd package uninstall -k --user 0 %%P >nul 2>&1
  if errorlevel 1 (
    rem Fallback to legacy pm uninstall for user
    adb -s "%TARGET%" shell pm uninstall -k --user 0 %%P >nul 2>&1
  )
  rem If uninstall not possible, attempt disabling
  adb -s "%TARGET%" shell pm disable-user --user 0 %%P >nul 2>&1
  rem As a last resort, try set-disabled using cmd package (older/newer APIs)
  adb -s "%TARGET%" shell cmd package set-enabled --user 0 false %%P >nul 2>&1
)
echo Done. Consider reboot: adb -s "%TARGET%" reboot
exit /b 0

:do_enable
echo Enabling/reinstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do (
  echo ^>^> %%P
  rem Re-install existing system apps for user 0 if hidden
  adb -s "%TARGET%" shell pm install-existing --user 0 %%P >nul 2>&1
  rem Enable via both pm and cmd package for wider compatibility
  adb -s "%TARGET%" shell pm enable --user 0 %%P >nul 2>&1
  adb -s "%TARGET%" shell cmd package set-enabled --user 0 true %%P >nul 2>&1
)
echo Done. You may reboot: adb -s "%TARGET%" reboot
exit /b 0

:do_status
echo Package ^| Installed ^| Enabled
echo ------------------------------
for %%P in (%PACKAGES%) do (
  set "INST=no"
  set "EN=n/a"
  for /f "usebackq delims=" %%A in (`adb -s "%TARGET%" shell pm list packages --user 0 ^| findstr /C:"package:%%P"`) do set "INST=yes"
  if "!INST!"=="yes" (
    set "EN=yes"
    for /f "usebackq delims=" %%B in (`adb -s "%TARGET%" shell pm list packages --user 0 -d ^| findstr /C:"package:%%P"`) do set "EN=no"
  )
  echo %%P ^| !INST! ^| !EN!
)
exit /b 0

:do_diag
echo === ADB Info ===
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
echo Tip: If no device, pass explicit HOST:PORT, e.g. 127.0.0.1:7555
exit /b 0
