@echo off
REM Headless project check: imports assets, then parses every GDScript file.
REM Set GODOT to your Godot 4.7 console executable if it isn't on PATH, e.g.
REM   set GODOT=C:\Tools\Godot\Godot_v4.7-stable_win64_console.exe
setlocal enabledelayedexpansion
if "%GODOT%"=="" set GODOT=godot
cd /d "%~dp0.."

if exist "%GODOT%\*" (echo GODOT points to a folder. Point it at the console .exe inside it. & exit /b 2)
"%GODOT%" --headless --version > "%TEMP%\ic_ver.log" 2>&1
findstr /B /C:"4." "%TEMP%\ic_ver.log" >nul || (echo Godot not found or not Godot 4. Set GODOT to your Godot 4.7 console .exe. & type "%TEMP%\ic_ver.log" & exit /b 2)
set /p GVER=<"%TEMP%\ic_ver.log"
echo == Godot %GVER%

set FAIL=0
echo == Importing project
"%GODOT%" --headless --path . --import > "%TEMP%\ic_import.log" 2>&1
findstr /R /C:"SCRIPT ERROR" /C:"Parse Error" /C:"ERROR:" "%TEMP%\ic_import.log" && set FAIL=1

echo == Checking scripts
for /R %%F in (*.gd) do (
  set "P=%%F"
  echo !P! | findstr /I /C:"\.godot\" /C:"\addons\" >nul
  if errorlevel 1 (
    set "R=!P:%CD%\=!"
    set "R=!R:\=/!"
    "%GODOT%" --headless --path . --check-only --script "res://!R!" > "%TEMP%\ic_check.log" 2>&1
    findstr /R /C:"SCRIPT ERROR" /C:"Parse Error" /C:"ERROR:" "%TEMP%\ic_check.log" >nul
    if not errorlevel 1 (
      echo FAIL !R!
      type "%TEMP%\ic_check.log"
      set FAIL=1
    )
  )
)

if %FAIL%==0 (echo == PASS) else (echo == FAIL)
exit /b %FAIL%
