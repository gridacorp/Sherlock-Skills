@echo off
setlocal enabledelayedexpansion

:: ============================
:: AUTODESK TOTAL WIPE SCRIPT
:: ============================
:: Ejecutar como Administrador
echo =====================================================
echo     ELIMINADOR COMPLETO DE AUTODESK (100% RASTROS)
echo =====================================================
echo Este script eliminará TODO lo relacionado con Autodesk.
echo.
echo 🔴 ADVERTENCIA: Esta acción NO SE PUEDE DESHACER.
echo.

:: ============ CREAR LOG ============
set "LOG_DIR=%SystemDrive%\Autodesk_Wipe_Logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo Iniciado: %DATE% %TIME% > "%LOG_DIR%\wipe_log.txt"

:: ============ 1. DETENER PROCESOS ============
echo [1] Deteniendo procesos...
for %%P in (
  acad.exe
  AdAppMgrSvc.exe
  AdskLicensingAgent.exe
  AdskIdentityManager.exe
  AutodeskDesktopApp.exe
  FlexNetLicensingService.exe
) do (
  taskkill /f /im %%P >nul 2>&1
)

:: ============ 2. DESINSTALAR TODOS LOS PRODUCTOS ============
echo [2] Desinstalando productos Autodesk...
for %%K in (
  "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
  "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
) do (
  for /f "tokens=*" %%G in ('reg query %%K /s /f "Autodesk" /k 2^>nul') do (
    for /f "tokens=3,*" %%A in ('reg query "%%G" /v "UninstallString" 2^>nul') do (
      set "UNINSTALL=%%A %%B"
      set "UNINSTALL=!UNINSTALL:"=!"
      echo Desinstalando: !UNINSTALL! >> "%LOG_DIR%\wipe_log.txt"
      echo Ejecutando: !UNINSTALL!
      echo.
      echo !UNINSTALL! | find /i "msiexec" >nul && (
        call !UNINSTALL! /qn /norestart >> "%LOG_DIR%\wipe_log.txt" 2>&1
      ) || (
        call !UNINSTALL! /quiet /norestart >> "%LOG_DIR%\wipe_log.txt" 2>&1
      )
    )
  )
)

:: ============ 3. ELIMINAR SERVICIOS ============
echo [3] Eliminando servicios Autodesk...
for %%S in (
  AdAppMgrSvc
  AutodeskDesktopApp
  FlexNet Licensing Service
  Autodesk Genuine Service
  AdskLicensingService
) do (
  sc stop "%%S" >nul 2>&1
  sc delete "%%S" >nul 2>&1
)

:: ============ 4. ELIMINAR TAREAS PROGRAMADAS ============
echo [4] Eliminando tareas programadas...
for /f "tokens=*" %%T in ('schtasks /query /fo LIST ^| findstr /i Autodesk') do (
  for /f "tokens=2 delims=:" %%U in ("%%T") do (
    schtasks /delete /tn "%%U" /f >nul 2>&1
  )
)

:: ============ 5. ELIMINAR CARPETAS ============
echo [5] Eliminando carpetas...
set FOLDERS=(
  "C:\Program Files\Autodesk"
  "C:\Program Files (x86)\Autodesk"
  "C:\ProgramData\Autodesk"
  "C:\Autodesk"
  "%APPDATA%\Autodesk"
  "%LOCALAPPDATA%\Autodesk"
  "%USERPROFILE%\Documents\Autodesk"
  "%USERPROFILE%\Documents\AutoCAD"
  "C:\ProgramData\FLEXnet"
  "%APPDATA%\FLEXnet"
  "%ProgramData%\Autodesk\AdskLicensingService"
)

for %%F in %FOLDERS% do (
  rmdir /s /q %%~F >nul 2>&1
)

:: ============ 6. BORRAR TEMPORALES ============
echo [6] Limpiando temporales...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%T in ("%TEMP%\*") do rmdir /s /q "%%T"
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%T in ("%SystemRoot%\Temp\*") do rmdir /s /q "%%T"

:: ============ 7. ELIMINAR REGISTRO ============
echo [7] Borrando claves de registro...

for %%R in (
  "HKCU\Software\Autodesk"
  "HKLM\SOFTWARE\Autodesk"
  "HKLM\SOFTWARE\WOW6432Node\Autodesk"
  "HKCU\Software\FLEXnet Publisher"
  "HKLM\SOFTWARE\FLEXnet Publisher"
  "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
) do (
  reg delete "%%R" /f >nul 2>&1
)

:: ============ 8. VARIABLES DE ENTORNO ============
echo [8] Limpiando variables de entorno...
setx PATH "%PATH:;C:\Program Files\Autodesk;%=" >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v AUTODESK_ROOT /f >nul 2>&1

:: ============ 9. LIMPIAR LOGS ============
echo [9] Limpiando eventos...
for /f "tokens=*" %%E in ('wevtutil el ^| findstr /i "Autodesk"') do (
  wevtutil cl "%%E" >nul 2>&1
)

:: ============ 10. FINAL ============
echo.
echo ✅ Autodesk ha sido completamente eliminado del sistema.
echo 📄 Revisa el log en: %LOG_DIR%\wipe_log.txt
echo.
pause
exit