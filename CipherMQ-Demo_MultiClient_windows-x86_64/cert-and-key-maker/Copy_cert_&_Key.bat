@echo off
setlocal EnableDelayedExpansion

set "ROOT_DIR=%~dp0.."

REM Certificate directories
set "certsDir=%ROOT_DIR%\cert-and-key-maker\certs"
set "clientCertsDirReceiver1=%ROOT_DIR%\cert-and-key-maker\src\client\certs\receiver_1"
set "clientCertsDestReceiver1=%ROOT_DIR%\client\receiver_1\keys"
set "clientCertsDirReceiver2=%ROOT_DIR%\cert-and-key-maker\src\client\certs\receiver_2"
set "clientCertsDestReceiver2=%ROOT_DIR%\client\receiver_2\keys"
set "clientCertsDirSender=%ROOT_DIR%\cert-and-key-maker\src\client\certs\sender_1"
set "clientCertsDestSender=%ROOT_DIR%\client\sender_1\keys"
set "ClientKeysDir=%ROOT_DIR%"
set "serverDest=%ROOT_DIR%\server"

REM Create destination directories
if not exist "%clientCertsDestReceiver1%" mkdir "%clientCertsDestReceiver1%"
if not exist "%clientCertsDestReceiver2%" mkdir "%clientCertsDestReceiver2%"
if not exist "%clientCertsDestSender%" mkdir "%clientCertsDestSender%"
if not exist "%serverDest%\certs" mkdir "%serverDest%\certs"

REM Copy server certificates
if exist "%certsDir%" (
    xcopy "%certsDir%" "%serverDest%\certs\" /E /I /Y
    if !ERRORLEVEL! equ 0 (
        echo [SUCCESS] Copied certs to %serverDest%\certs
    ) else (
        echo [ERROR] Failed to copy certs: !ERRORLEVEL!
        pause
        exit /b !ERRORLEVEL!
    )
) else (
    echo [ERROR] Directory %certsDir% does not exist
    pause
    exit /b 1
)

REM Copy receiver_1 certificates
if exist "%clientCertsDirReceiver1%" (
    xcopy "%clientCertsDirReceiver1%" "%clientCertsDestReceiver1%\" /E /I /Y
    if !ERRORLEVEL! equ 0 (
        echo [SUCCESS] Copied receiver_1 certs to %clientCertsDestReceiver1%
    ) else (
        echo [ERROR] Failed to copy receiver_1 certs: !ERRORLEVEL!
        pause
        exit /b !ERRORLEVEL!
    )
) else (
    echo [ERROR] Directory %clientCertsDirReceiver1% does not exist
    pause
    exit /b 1
)

REM Copy receiver_2 certificates
if exist "%clientCertsDirReceiver2%" (
    xcopy "%clientCertsDirReceiver2%" "%clientCertsDestReceiver2%\" /E /I /Y
    if !ERRORLEVEL! equ 0 (
        echo [SUCCESS] Copied receiver_2 certs to %clientCertsDestReceiver2%
    ) else (
        echo [ERROR] Failed to copy receiver_2 certs: !ERRORLEVEL!
        pause
        exit /b !ERRORLEVEL!
    )
) else (
    echo [ERROR] Directory %clientCertsDirReceiver2% does not exist
    pause
    exit /b 1
)

REM Copy sender_1 certificates
if exist "%clientCertsDirSender%" (
    xcopy "%clientCertsDirSender%" "%clientCertsDestSender%\" /E /I /Y
    if !ERRORLEVEL! equ 0 (
        echo [SUCCESS] Copied sender_1 certs to %clientCertsDestSender%
    ) else (
        echo [ERROR] Failed to copy sender_1 certs: !ERRORLEVEL!
        pause
        exit /b !ERRORLEVEL!
    )
) else (
    echo [ERROR] Directory %clientCertsDirSender% does not exist
    pause
    exit /b 1
)

REM Copy encryption keys to both receivers
echo.
echo Copying encryption keys...
set "keyFound=0"
for %%f in ("%ClientKeysDir%\*.key") do (
    set "keyFound=1"
    set "keyFile=%%f"
    
    REM Copy to receiver_1
    copy "%%f" "%clientCertsDestReceiver1%\" >nul
    if !ERRORLEVEL! equ 0 (
        echo [SUCCESS] Copied %%~nxf to receiver_1
    ) else (
        echo [ERROR] Failed to copy %%~nxf to receiver_1
    )
    
    REM Copy to receiver_2
    copy "%%f" "%clientCertsDestReceiver2%\" >nul
    if !ERRORLEVEL! equ 0 (
        echo [SUCCESS] Copied %%~nxf to receiver_2
    ) else (
        echo [ERROR] Failed to copy %%~nxf to receiver_2
    )
    
    REM Delete original key file after copying
    del "%%f" >nul
    if !ERRORLEVEL! equ 0 (
        echo [SUCCESS] Deleted original key file: %%~nxf
    ) else (
        echo [WARNING] Could not delete original key: %%~nxf
    )
)

if "!keyFound!"=="0" (
    echo [WARNING] No .key files found in %ClientKeysDir%
)

echo.
echo ========================================
echo File copy completed successfully!
echo ========================================
pause
exit /b 0