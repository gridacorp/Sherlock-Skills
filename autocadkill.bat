@echo off
setlocal enabledelayedexpansion

:: =====================================================
:: AUTODESK WIPE TOTAL - SIN PAUSAS, SIN ERRORES DETENIENDO
:: =====================================================

:: Crear carpeta de logs
set "LOG_DIR=%SystemDrive%\Autodesk_Wipe_Logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo Iniciado: %DATE% %TIME% > "%LOG_DIR%\wipe_log.txt"

:: [1] Desinstalar productos con WMIC
echo [1] Desinstalando productos Autodesk... >> "%LOG_DIR%\wipe_log.txt"
for /f "skip=1 tokens=2 delims={}" %%I in (
    'wmic product where "Name like '%%Autodesk%%' or Name like '%%AutoCAD%%'" get IdentifyingNumber ^| find "{"'
) do (
    set "GUID={%%I}"
    echo Desinstalando: !GUID! >> "%LOG_DIR%\wipe_log.txt"
    msiexec /x "!GUID!" /qn /norestart >> "%LOG_DIR%\wipe_log.txt" 2>&1
)

:: [2] Matar procesos relacionados
echo [2] Cerrando procesos... >> "%LOG_DIR%\wipe_log.txt"
for %%P in (
    acad.exe
    AdAppMgrSvc.exe
    AdskLicensingAgent.exe
    AutodeskDesktopApp.exe
    FlexNetLicensingService.exe
) do (
    taskkill /f /im %%P >> "%LOG_DIR%\wipe_log.txt" 2>&1
)

:: [3] Eliminar servicios
echo [3] Eliminando servicios... >> "%LOG_DIR%\wipe_log.txt"
for %%S in (
    AdAppMgrSvc
    AutodeskDesktopApp
    "FlexNet Licensing Service"
    "Autodesk Genuine Service"
    AdskLicensingService
) do (
    sc stop %%~S >> "%LOG_DIR%\wipe_log.txt" 2>&1
    sc delete %%~S >> "%LOG_DIR%\wipe_log.txt" 2>&1
)

:: [4] Borrar tareas programadas
echo [4] Eliminando tareas programadas... >> "%LOG_DIR%\wipe_log.txt"
schtasks /query /fo LIST | findstr /i "Autodesk" > "%TEMP%\autsched.txt"
for /f "tokens=2 delims: " %%T in ('findstr /i "TaskName" "%TEMP%\autsched.txt"') do (
    schtasks /delete /tn "%%T" /f >> "%LOG_DIR%\wipe_log.txt" 2>&1
)
del "%TEMP%\autsched.txt"

:: [5] Eliminar carpetas
echo [5] Eliminando carpetas residuales... >> "%LOG_DIR%\wipe_log.txt"
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
        echo Eliminando: %%~D >> "%LOG_DIR%\wipe_log.txt"
        rd /s /q "%%~D" >> "%LOG_DIR%\wipe_log.txt" 2>&1
    )
)

:: [6] Eliminar archivos temporales
echo [6] Eliminando archivos temporales... >> "%LOG_DIR%\wipe_log.txt"
del /f /s /q "%TEMP%\*" >> "%LOG_DIR%\wipe_log.txt" 2>&1
for /d %%T in ("%TEMP%\*") do (
    rd /s /q "%%T" >> "%LOG_DIR%\wipe_log.txt" 2>&1
)
del /f /s /q "%SystemRoot%\Temp\*" >> "%LOG_DIR%\wipe_log.txt" 2>&1
for /d %%T in ("%SystemRoot%\Temp\*") do (
    rd /s /q "%%T" >> "%LOG_DIR%\wipe_log.txt" 2>&1
)

:: [7] Eliminar entradas de registro
echo [7] Eliminando entradas de registro... >> "%LOG_DIR%\wipe_log.txt"
for %%R in (
    HKCU\Software\Autodesk
    HKCU\Software\Autodesk\AutoCAD
    HKLM\SOFTWARE\Autodesk
    HKLM\SOFTWARE\WOW6432Node\Autodesk
    HKLM\SOFTWARE\FLEXnet Publisher
    HKCU\Software\FLEXnet Publisher
) do (
    reg delete "%%R" /f >> "%LOG_DIR%\wipe_log.txt" 2>&1
)

:: [8] Limpiar variables de entorno
echo [8] Eliminando variables de entorno... >> "%LOG_DIR%\wipe_log.txt"
setx PATH "%PATH:;C:\Program Files\Autodesk;=%" >> "%LOG_DIR%\wipe_log.txt" 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v AUTODESK_ROOT /f >> "%LOG_DIR%\wipe_log.txt" 2>&1

:: [9] Final
echo. >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"
echo Proceso finalizado: %DATE% %TIME% >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"

endlocal
exit