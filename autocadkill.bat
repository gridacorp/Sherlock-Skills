@echo off
setlocal enabledelayedexpansion

echo =====================================================
echo    AUTODESK WIPE TOTAL (CERO RASTROS) - SIN ERRORES
echo =====================================================
echo ADVERTENCIA: NO HAY VUELTA ATRÁS. EJECUTAR COMO ADMINISTRADOR.
echo.

:: ============ LOG ============
set "LOG_DIR=%SystemDrive%\Autodesk_Wipe_Logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo Iniciado: %DATE% %TIME% > "%LOG_DIR%\wipe_log.txt"

:: ============ 1. DESINSTALAR MSI CON WMIC ============
echo [1] Desinstalando con WMIC...
for /f "skip=1 tokens=2 delims={}" %%I in ('
    wmic product where "Name like '%%Autodesk%%' or Name like '%%AutoCAD%%'" get IdentifyingNumber ^| find "{" 
') do (
    set "GUID={%%I}"
    echo Desinstalando producto MSI: !GUID! >> "%LOG_DIR%\wipe_log.txt"
    msiexec /x "!GUID!" /qn /norestart >> "%LOG_DIR%\wipe_log.txt" 2>&1
)

:: ============ 2. DETENER PROCESOS ============
echo [2] Matando procesos en memoria...
for %%P in (acad.exe AdAppMgrSvc.exe AdskLicensingAgent.exe AutodeskDesktopApp.exe FlexNetLicensingService.exe) do (
    taskkill /f /im %%P >nul 2>&1
)

:: ============ 3. ELIMINAR SERVICIOS ============
echo [3] Eliminando servicios...
for %%S in ("AdAppMgrSvc" "AutodeskDesktopApp" "FlexNet Licensing Service" "Autodesk Genuine Service" "AdskLicensingService") do (
    sc stop %%~S >nul 2>&1
    sc delete %%~S >nul 2>&1
    echo Servicio %%~S >> "%LOG_DIR%\wipe_log.txt"
)

:: ============ 4. BORRAR TAREAS PROGRAMADAS ============
echo [4] Borrando tareas programadas...
schtasks /query /fo LIST ^| findstr /i "Autodesk" > "%TEMP%\autsched.txt"
for /f "tokens=2 delims: " %%T in ('type "%TEMP%\autsched.txt" ^| findstr /i "TaskName"') do (
    schtasks /delete /tn "%%T" /f >nul 2>&1
    echo Tarea %%T >> "%LOG_DIR%\wipe_log.txt"
)
del "%TEMP%\autsched.txt"

:: ============ 5. ELIMINAR CARPETAS ============
echo [5] Borrando carpetas residuales...
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
)
for %%D in %FOLDERS% do (
    if exist %%~D (
        rmdir /s /q "%%~D"
        echo Eliminado: %%~D >> "%LOG_DIR%\wipe_log.txt"
    )
)

:: ============ 6. BORRAR TEMPORALES ============
echo [6] Limpiando temporales...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%T in ("%TEMP%\*") do rmdir /s /q "%%T"
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%T in ("%SystemRoot%\Temp\*") do rmdir /s /q "%%T"

:: ============ 7. LIMPIAR REGISTRO ============
echo [7] Limpiando registro...
for %%R in (
    "HKCU\Software\Autodesk"
    "HKCU\Software\Autodesk\AutoCAD"
    "HKLM\SOFTWARE\Autodesk"
    "HKLM\SOFTWARE\WOW6432Node\Autodesk"
    "HKLM\SOFTWARE\FLEXnet Publisher"
    "HKCU\Software\FLEXnet Publisher"
) do (
    reg delete %%~R /f >nul 2>&1
    echo Clave borrada: %%~R >> "%LOG_DIR%\wipe_log.txt"
)

:: ============ 8. VARIABLES DE ENTORNO ============
echo [8] Limpiando variables de entorno...
setx PATH "%PATH:;C:\Program Files\Autodesk;%=" >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v AUTODESK_ROOT /f >nul 2>&1

:: ============ 9. FINAL ============
echo. >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"
echo WIPE COMPLETO: %DATE% %TIME% >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"

echo.
echo ✅ Proceso completado. Revisa el log en %LOG_DIR%\wipe_log.txt
pause
exit