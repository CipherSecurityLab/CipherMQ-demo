@echo off
setlocal EnableDelayedExpansion


set "ROOT_DIR=%~dp0.."


set "certsDir=%ROOT_DIR%\cert-and-key-maker\certs"
set "clientCertsDirReceiver=%ROOT_DIR%\cert-and-key-maker\src\client\certs\receiver_1"
set "clientCertsDestReceiver=%ROOT_DIR%\client\receiver_1\keys"
set "clientCertsDirSender=%ROOT_DIR%\cert-and-key-maker\src\client\certs\sender_1"
set "clientCertsDestSender=%ROOT_DIR%\client\sender_1\keys"
set "ClientKeysDir=%ROOT_DIR%\*.key"
set "ClientKeysDest=%ROOT_DIR%\client\receiver_1\keys"
set "serverDest=%ROOT_DIR%\server"
set "rootDest=%ROOT_DIR%"



if not exist "%clientCertsDestReceiver%" mkdir "%clientCertsDestReceiver%"
if not exist "%clientCertsDestSender%" mkdir "%clientCertsDestSender%"
if not exist "%ClientKeysDest%" mkdir "%ClientKeysDest%"
if not exist "%serverDest%" mkdir "%serverDest%"
if not exist "%rootDest%" mkdir "%rootDest%"


if exist "%certsDir%" (
    xcopy "%certsDir%" "%serverDest%\certs\" /E /I /Y
    if !ERRORLEVEL! equ 0 (
        echo Copied certs to %serverDest%\certs
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


if exist "%clientCertsDirReceiver%" (
    xcopy "%clientCertsDirReceiver%" "%clientCertsDestReceiver%\" /E /I /Y
    if !ERRORLEVEL! equ 0 (
        echo Copied src/client/certs/receiver_1 to %clientCertsDestReceiver%
    ) else (
        echo [ERROR] Failed to copy receiver_1 certs: !ERRORLEVEL!
        pause
        exit /b !ERRORLEVEL!
    )
) else (
    echo [ERROR] Directory %clientCertsDirReceiver% does not exist
    pause
    exit /b 1
)


if exist "%clientCertsDirSender%" (
    xcopy "%clientCertsDirSender%" "%clientCertsDestSender%\" /E /I /Y
    if !ERRORLEVEL! equ 0 (
        echo Copied src/client/certs/sender_1 to %clientCertsDestSender%
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


if exist "%ClientKeysDir%" (
    move "%ClientKeysDir%" "%ClientKeysDest%\" 
    if !ERRORLEVEL! equ 0 (
        echo Moved key to %ClientKeysDest%
    ) else (
        echo [ERROR] Failed to move client keys: !ERRORLEVEL!
        pause
        exit /b !ERRORLEVEL!
    )
) else (
    echo [ERROR] Directory %ClientKeysDir% does not exist
    pause
    exit /b 1
)

echo Directory copy completed.
pause