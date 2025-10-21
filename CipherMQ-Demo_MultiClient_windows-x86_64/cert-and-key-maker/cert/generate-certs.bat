@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Generating certificates for CipherMQ
echo Version 1.0
echo ========================================
echo.

set ROOT_DIR=%~dp0..
cd /d "%ROOT_DIR%"

echo Generating CA, receiver_1, receiver_2 and sender_1...
"%ROOT_DIR%.\cert_generator.exe" receiver_1 receiver_2 sender_1
if !ERRORLEVEL! NEQ 0 (
    echo [ERROR] run cert_generator.exe Failed: !ERRORLEVEL!
    pause
    exit /b !ERRORLEVEL!
)

echo [SUCCESS] Certificates generated successfully for all clients.
exit /b 0