@echo off
setlocal enabledelayedexpansion

:: =======================
:: AUTODESK WIPE - LIMPIEZA TOTAL (Sin wmic)
:: Ejecutar como Administrador
:: =======================

set "LOG_DIR=%SystemDrive%\Autodesk_Wipe_Logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
echo Iniciado: %DATE% %TIME% > "%LOG_DIR%\wipe_log.txt"

:: [1] DESINSTALAR CON PowerShell (sin WMIC)
echo [1] Desinstalando productos con PowerShell... >> "%LOG_DIR%\wipe_log.txt"
powershell -Command "Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like '*Autodesk*' -or $_.Name -like '*AutoCAD*' } | ForEach-Object { Write-Output ('Desinstalando: ' + $_.Name); $_.Uninstall() }" >> "%LOG_DIR%\wipe_log.txt" 2>&1

:: [2] MATAR PROCESOS
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

:: [3] DETENER Y ELIMINAR SERVICIOS
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

:: [4] BORRAR TAREAS PROGRAMADAS
echo [4] Eliminando tareas programadas... >> "%LOG_DIR%\wipe_log.txt"
schtasks /query /fo LIST | findstr /i "Autodesk" > "%TEMP%\autsched.txt"
for /f "tokens=2 delims: " %%T in ('findstr /i "TaskName" "%TEMP%\autsched.txt"') do (
    schtasks /delete /tn "%%T" /f >> "%LOG_DIR%\wipe_log.txt" 2>&1
)
del "%TEMP%\autsched.txt"

:: [5] BORRAR CARPETAS
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

:: [6] BORRAR TEMPORALES
echo [6] Eliminando temporales... >> "%LOG_DIR%\wipe_log.txt"
del /f /s /q "%TEMP%\*" >> "%LOG_DIR%\wipe_log.txt" 2>&1
for /d %%T in ("%TEMP%\*") do (
    rd /s /q "%%T" >> "%LOG_DIR%\wipe_log.txt" 2>&1
)
del /f /s /q "%SystemRoot%\Temp\*" >> "%LOG_DIR%\wipe_log.txt" 2>&1
for /d %%T in ("%SystemRoot%\Temp\*") do (
    rd /s /q "%%T" >> "%LOG_DIR%\wipe_log.txt" 2>&1
)

:: [7] BORRAR REGISTRO
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

:: [8] VARIABLES DE ENTORNO
echo [8] Limpiando variables de entorno... >> "%LOG_DIR%\wipe_log.txt"
setx PATH "%PATH:;C:\Program Files\Autodesk;=%" >> "%LOG_DIR%\wipe_log.txt" 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v AUTODESK_ROOT /f >> "%LOG_DIR%\wipe_log.txt" 2>&1

:: [9] FINAL
echo. >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"
echo FINALIZADO: %DATE% %TIME% >> "%LOG_DIR%\wipe_log.txt"
echo ===================================================== >> "%LOG_DIR%\wipe_log.txt"

endlocal
exit