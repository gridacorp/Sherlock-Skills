@echo off
setlocal enabledelayedexpansion

:: =====================================================
:: AUTODESK WIPE TOTAL (CERO RASTROS) - DETECCIÓN DE ERRORES
:: =====================================================
:: ADVERTENCIA: NO HAY VUELTA ATRÁS. EJECUTAR COMO ADMINISTRADOR.

:: Función para verificar errores y pausar
:CheckError
if ERRORLEVEL 1 (
    echo.
    echo [ERROR] El comando anterior falló con código de error %ERRORLEVEL%.
    echo Por favor revisa el log antes de continuar.
    pause
)
exit /b 0

:: ============ LOG ============
set "LOG_DIR=%SystemDrive%\Autodesk_Wipe_Logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo Iniciado: %DATE% %TIME% > "%LOG_DIR%\wipe_log.txt"

:: ============ 1. DESINSTALAR MSI CON WMIC ============
echo [1] Desinstalando con WMIC... >> "%LOG_DIR%\wipe_log.txt"
for /f "skip=1 tokens=2 delims={}" %%I in (
    'wmic product where "Name like '%%Autodesk%%' or Name like '%%AutoCAD%%'" get IdentifyingNumber ^| find "{"'
) do (
    set "GUID={%%I}"
    echo Desinstalando producto MSI: !GUID! >> "%LOG_DIR%\wipe_log.txt"
    msiexec /x "!GUID!" /qn /norestart >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
)

:: ============ 2. DETENER PROCESOS ============
echo [2] Matando procesos en memoria... >> "%LOG_DIR%\wipe_log.txt"
for %%P in (acad.exe AdAppMgrSvc.exe AdskLicensingAgent.exe AutodeskDesktopApp.exe FlexNetLicensingService.exe) do (
    taskkill /f /im %%P >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
)

:: ============ 3. ELIMINAR SERVICIOS ============
echo [3] Eliminando servicios... >> "%LOG_DIR%\wipe_log.txt"
for %%S in (
    "AdAppMgrSvc"
    "AutodeskDesktopApp"
    "FlexNet Licensing Service"
    "Autodesk Genuine Service"
    "AdskLicensingService"
) do (
    sc stop %%~S >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
    sc delete %%~S >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
)

:: ============ 4. BORRAR TAREAS PROGRAMADAS ============
echo [4] Borrando tareas programadas... >> "%LOG_DIR%\wipe_log.txt"
schtasks /query /fo LIST ^| findstr /i "Autodesk" > "%TEMP%\autsched.txt"
call :CheckError
for /f "tokens=2 delims: " %%T in ('type "%TEMP%\autsched.txt" ^| findstr /i "TaskName"') do (
    schtasks /delete /tn "%%T" /f >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
)
del "%TEMP%\autsched.txt"

:: ============ 5. ELIMINAR CARPETAS ============
echo [5] Borrando carpetas residuales... >> "%LOG_DIR%\wipe_log.txt"
for %%D in (
    "C:\Program Files\Autodesk"
    "C:\Program Files (x86)\Autodesk"
    "C:\ProgramData\Autodesk"
    "C:\Autodesk"
    "%APPDATA%\Autodesk"
    "%LOCALAPPDATA%\Autodesk"
    "%USERPROFILE%\Documents\Autodesk"
    "%USERPROFILE%\Documents\AutoCAD"
    "C:\ProgramData\FLEXnet"
) do (
    if exist %%~D (
        rmdir /s /q "%%~D" >> "%LOG_DIR%\wipe_log.txt" 2>&1
        call :CheckError
    )
)

:: ============ 6. BORRAR TEMPORALES ============
echo [6] Limpiando temporales... >> "%LOG_DIR%\wipe_log.txt"
del /f /s /q "%TEMP%\*" >> "%LOG_DIR%\wipe_log.txt" 2>&1
call :CheckError
for /d %%T in ("%TEMP%\*") do (
    rmdir /s /q "%%T" >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
)
del /f /s /q "%SystemRoot%\Temp\*" >> "%LOG_DIR%\wipe_log.txt" 2>&1
call :CheckError
for /d %%T in ("%SystemRoot%\Temp\*") do (
    rmdir /s /q "%%T" >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
)

:: ============ 7. LIMPIAR REGISTRO ============
echo [7] Limpiando registro... >> "%LOG_DIR%\wipe_log.txt"
for %%R in (
    "HKCU\Software\Autodesk"
    "HKCU\Software\Autodesk\AutoCAD"
    "HKLM\SOFTWARE\Autodesk"
    "HKLM\SOFTWARE\WOW6432Node\Autodesk"
    "HKLM\SOFTWARE\FLEXnet Publisher"
    "HKCU\Software\FLEXnet Publisher"
) do (
    reg delete %%~R /f >> "%LOG_DIR%\wipe_log.txt" 2>&1
    call :CheckError
)

:: ============ 8. VARIABLES DE ENTORNO ============
echo [8] Limpiando variables de entorno... >> "%LOG_DIR%\wipe_log.txt"
setx PATH "%PATH:;C:\Program Files\Autodesk;%=" >> "%LOG_DIR%\wipe_log.txt" 2>&1
call :CheckError
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v AUTODESK_ROOT /f >> "%LOG_DIR%\wipe_log.txt" 2>&1
call :CheckError

:: ============ 9. FINAL ============
echo. >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"
echo WIPE COMPLETO: %DATE% %TIME% >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"

echo.
echo ✅ Proceso completado. Revisa log en %LOG_DIR%\wipe_log.txt
echo.
echo Presiona cualquier tecla para salir...
pause >nul
exit