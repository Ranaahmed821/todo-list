@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem gms-toggle.bat - Disable/Enable Google Play (GMS) packages via ADB
rem Usage: gms-toggle.bat [disable|enable|status] [HOST:PORT]
rem Default HOST:PORT = 127.0.0.1:7555 (e.g., MuMu)

set "ACTION=%~1"
set "TARGET=%~2"
if "%TARGET%"=="" set "TARGET=127.0.0.1:7555"

if /i "%ACTION%"=="disable" goto have_action
if /i "%ACTION%"=="enable" goto have_action
if /i "%ACTION%"=="status" goto have_action

echo Usage: %~nx0 [disable^|enable^|status] [HOST:PORT]
exit /b 1

:have_action
where adb >nul 2>&1
if errorlevel 1 (
  echo Error: adb not found in PATH.
  exit /b 1
)

adb start-server >nul 2>&1
adb connect "%TARGET%" >nul 2>&1

adb -s "%TARGET%" shell exit >nul 2>&1
if errorlevel 1 (
  echo Unable to reach %TARGET% via ADB.
  exit /b 1
)

set "PACKAGES=com.google.android.gms com.google.android.gsf com.android.vending com.google.android.gsf.login com.google.android.syncadapters.calendar com.google.android.syncadapters.contacts com.google.android.onetimeinitializer com.google.android.backuptransport com.google.android.feedback com.google.android.configupdater com.google.android.partnersetup com.google.android.setupwizard com.google.android.apps.restore"

if /i "%ACTION%"=="disable" goto do_disable
if /i "%ACTION%"=="enable" goto do_enable
if /i "%ACTION%"=="status" goto do_status

goto :eof

:do_disable
echo Disabling/uninstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do (
  echo ^>^> %%P
  adb -s "%TARGET%" shell cmd package uninstall -k --user 0 %%P >nul 2>&1
  if errorlevel 1 (
    adb -s "%TARGET%" shell pm disable-user --user 0 %%P >nul 2>&1
  )
)
echo Done. Consider reboot: adb -s "%TARGET%" reboot
exit /b 0

:do_enable
echo Enabling/reinstalling Google packages for user 0 on %TARGET% ...
for %%P in (%PACKAGES%) do (
  echo ^>^> %%P
  adb -s "%TARGET%" shell pm install-existing --user 0 %%P >nul 2>&1
  adb -s "%TARGET%" shell pm enable --user 0 %%P >nul 2>&1
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
