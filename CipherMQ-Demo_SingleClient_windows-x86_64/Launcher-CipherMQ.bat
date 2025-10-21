@echo off
setlocal EnableDelayedExpansion
set "ROOT_DIR=%~dp0"
set "STATE_FILE=%ROOT_DIR%progress.state"

REM Initialize state file if not exists
if not exist "%STATE_FILE%" (
    (
        echo CERT=0
        echo KEY=0
        echo COPY=0
        echo SERVER=0
    ) > "%STATE_FILE%"
)

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Not running as administrator. Some operations may fail.
    echo.
)

:menu
cls
REM Load progress state
set "CERT=0"
set "KEY=0"
set "COPY=0"
set "SERVER=0"

for /f "usebackq tokens=1,2 delims==" %%a in ("%STATE_FILE%") do (
    set "%%a=%%b"
)

echo.
echo ========================================
echo CipherMQ Launcher - Demo Version 1.5
echo ========================================
echo.
echo Progress Status:
echo ----------------

REM Show status with visual indicators
if "!CERT!"=="1" (
    echo [X] Step 1: Generate Certificates    ^(COMPLETED^)
) else (
    echo [ ] Step 1: Generate Certificates    ^(PENDING^)
)

if "!KEY!"=="1" (
    echo [X] Step 2: Generate Keys            ^(COMPLETED^)
) else (
    echo [ ] Step 2: Generate Keys            ^(PENDING^)
)

if "!COPY!"=="1" (
    echo [X] Step 3: Copy Files               ^(COMPLETED^)
) else (
    echo [ ] Step 3: Copy Files               ^(PENDING^)
)

if "!SERVER!"=="1" (
    echo [X] Step 4: Server Started           ^(COMPLETED^)
) else (
    echo [ ] Step 4: Run Server               ^(PENDING^)
)

echo.
echo ========================================
echo Menu:
echo ========================================
echo 1. Generate Certificates
echo 2. Generate Keys
echo 3. Copy Files to Destinations
echo 4. Run Server
echo 5. Run Receiver
echo 6. Run Sender
echo 7. Reset Progress
echo.
echo Select (1-7) or Enter to exit:
set /p choice=

if "!choice!"=="" goto end
if "!choice!"=="1" goto generateCert
if "!choice!"=="2" goto generateKey
if "!choice!"=="3" goto copy
if "!choice!"=="4" goto server
if "!choice!"=="5" goto receiver
if "!choice!"=="6" goto sender
if "!choice!"=="7" goto reset
echo [ERROR] Invalid choice. Please select 1-7.
pause
goto menu

:generateCert
echo.
echo ========================================
echo Generating Certificates...
echo ========================================
if not exist "%ROOT_DIR%cert-and-key-maker\cert\generate-certs.bat" (
    echo [ERROR] File generate-certs.bat not found in %ROOT_DIR%cert-and-key-maker\cert
    echo Please ensure the cert-and-key-maker directory structure is correct.
    pause
    goto menu
)
call "%ROOT_DIR%cert-and-key-maker\cert\generate-certs.bat"
if !ERRORLEVEL! equ 0 (
    echo.
    echo [SUCCESS] Certificates generated successfully.
    REM Update state
    (
        echo CERT=1
        echo KEY=!KEY!
        echo COPY=!COPY!
        echo SERVER=!SERVER!
    ) > "%STATE_FILE%"
) else (
    echo.
    echo [ERROR] Certificate generation failed with code: !ERRORLEVEL!
)
pause
goto menu

:generateKey
echo.
echo ========================================
echo Generating Encryption Keys...
echo ========================================
if "!CERT!" neq "1" (
    echo [WARNING] You should generate certificates first ^(Step 1^)
    echo Do you want to continue anyway? ^(Y/N^)
    set /p continue=
    if /i "!continue!" neq "Y" goto menu
)
if not exist "%ROOT_DIR%cert-and-key-maker\key\key_generator.exe" (
    echo [ERROR] key_generator.exe not found in %ROOT_DIR%cert-and-key-maker\key
    pause
    goto menu
)
call "%ROOT_DIR%cert-and-key-maker\key\key_generator.exe"
if !ERRORLEVEL! equ 0 (
    echo.
    echo [SUCCESS] Keys generated successfully.
    (
        echo CERT=!CERT!
        echo KEY=1
        echo COPY=!COPY!
        echo SERVER=!SERVER!
    ) > "%STATE_FILE%"
) else (
    echo.
    echo [ERROR] Key generation failed with code: !ERRORLEVEL!
)
pause
goto menu

:copy
echo.
echo ========================================
echo Copying Files to Directories...
echo ========================================
if "!CERT!" neq "1" (
    echo [WARNING] Certificates not generated yet ^(Step 1^)
)
if "!KEY!" neq "1" (
    echo [WARNING] Keys not generated yet ^(Step 2^)
)
if "!CERT!" neq "1" (
    echo Do you want to continue anyway? ^(Y/N^)
    set /p continue=
    if /i "!continue!" neq "Y" goto menu
)
if not exist "%ROOT_DIR%cert-and-key-maker\Copy_cert_&_Key.bat" (
    echo [ERROR] Copy_cert_&_Key.bat not found
    pause
    goto menu
)
call "%ROOT_DIR%cert-and-key-maker\Copy_cert_&_Key.bat"
if !ERRORLEVEL! equ 0 (
    echo.
    echo [SUCCESS] Files copied successfully.
    (
        echo CERT=!CERT!
        echo KEY=!KEY!
        echo COPY=1
        echo SERVER=!SERVER!
    ) > "%STATE_FILE%"
) else (
    echo.
    echo [ERROR] File copy failed with code: !ERRORLEVEL!
)
pause
goto menu

:server
echo.
echo ========================================
echo Starting Message Broker Server...
echo ========================================
if "!COPY!" neq "1" (
    echo [WARNING] Files not copied yet ^(Step 3^). Server may not work properly.
    echo Do you want to continue anyway? ^(Y/N^)
    set /p continue=
    if /i "!continue!" neq "Y" goto menu
)
if not exist "%ROOT_DIR%server\scripts\start.bat" (
    echo [ERROR] start.bat not found in %ROOT_DIR%server\scripts
    pause
    goto menu
)
start "CipherMQ Server" cmd /k "%ROOT_DIR%server\scripts\start.bat"
if !ERRORLEVEL! equ 0 (
    echo [SUCCESS] Server started in a new terminal.
    echo Wait a few seconds for the server to initialize before starting clients.
    (
        echo CERT=!CERT!
        echo KEY=!KEY!
        echo COPY=!COPY!
        echo SERVER=1
    ) > "%STATE_FILE%"
) else (
    echo [ERROR] Failed to start server.
)
pause
goto menu

:receiver
echo.
echo ========================================
echo Starting Receiver...
echo ========================================
if "!SERVER!" neq "1" (
    echo [WARNING] Server not started yet ^(Step 4^). Receiver needs server running.
    echo Do you want to continue anyway? ^(Y/N^)
    set /p continue=
    if /i "!continue!" neq "Y" goto menu
)
cd /d "%ROOT_DIR%client\receiver_1"
if not exist "Receiver.py" (
    echo [ERROR] Receiver.py not found in %ROOT_DIR%client\receiver_1
    cd /d "%ROOT_DIR%"
    pause
    goto menu
)
if not exist "config.json" (
    echo [ERROR] config.json not found in %ROOT_DIR%client\receiver_1
    cd /d "%ROOT_DIR%"
    pause
    goto menu
)
start "CipherMQ Receiver" cmd /k python Receiver.py
if !ERRORLEVEL! equ 0 (
    echo [SUCCESS] Receiver started in a new terminal.
) else (
    echo [ERROR] Receiver failed to start. Check if Python is installed.
)
cd /d "%ROOT_DIR%"
pause
goto menu

:sender
echo.
echo ========================================
echo Starting Sender...
echo ========================================
if "!SERVER!" neq "1" (
    echo [WARNING] Server not started yet ^(Step 4^). Sender needs server running.
    echo Do you want to continue anyway? ^(Y/N^)
    set /p continue=
    if /i "!continue!" neq "Y" goto menu
)
cd /d "%ROOT_DIR%client\sender_1"
if not exist "Sender.py" (
    echo [ERROR] Sender.py not found in %ROOT_DIR%client\sender_1
    cd /d "%ROOT_DIR%"
    pause
    goto menu
)
if not exist "config.json" (
    echo [ERROR] config.json not found in %ROOT_DIR%client\sender_1
    cd /d "%ROOT_DIR%"
    pause
    goto menu
)
start "CipherMQ Sender" cmd /k python Sender.py
if !ERRORLEVEL! equ 0 (
    echo [SUCCESS] Sender started in a new terminal.
) else (
    echo [ERROR] Sender failed to start. Check if Python is installed.
)
cd /d "%ROOT_DIR%"
pause
goto menu

:reset
echo.
echo ========================================
echo Reset Progress
echo ========================================
echo This will reset all progress indicators.
echo The terminal will close after reset.
echo Are you sure? ^(Y/N^)
set /p confirm=
if /i "!confirm!"=="Y" (
    (
        echo CERT=0
        echo KEY=0
        echo COPY=0
        echo SERVER=0
    ) > "%STATE_FILE%"
    echo [SUCCESS] Progress reset successfully.
    echo Terminal will close in 3 seconds...
    timeout /t 3 >nul
    exit
) else (
    echo [INFO] Reset cancelled.
)
pause
goto menu

:end
echo.
echo ========================================
echo Thank you for using CipherMQ!
echo ========================================
timeout /t 2 >nul
exit /b 0