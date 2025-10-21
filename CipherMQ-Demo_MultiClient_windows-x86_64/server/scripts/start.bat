@echo off
setlocal enabledelayedexpansion

echo ========================================
echo CipherMQ Server - Starting
echo Demo Version 1.5
echo ========================================
echo.


set ROOT_DIR=%~dp0..
cd /d "%ROOT_DIR%"


if not exist "config.toml" (
    echo [ERROR] Configuration file not found!
    echo Please copy config\config.toml.example to root\config.toml and edit it.
    echo.
    pause
    exit /b 1
)


if not exist "certs\server.crt" (
    echo [ERROR] TLS certificates not found!
    echo Please generate certificates first:
    echo   cd certs
    echo   generate-certs.bat
    echo.
    pause
    exit /b 1
)


if not exist "logs" mkdir logs


echo Checking PostgreSQL connection...
pg_isready -h localhost -p 5432 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] PostgreSQL is not running!
    echo Please start PostgreSQL before continuing.
    echo.
    choice /C YN /M "Do you want to continue anyway"
    if !ERRORLEVEL! EQU 2 exit /b 1
)


echo.
echo Starting Message Broker Server...
echo Press Ctrl+C to stop
echo.
echo ========================================
echo.

"%ROOT_DIR%\bin\ciphermq.exe"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Server exited with error code: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)