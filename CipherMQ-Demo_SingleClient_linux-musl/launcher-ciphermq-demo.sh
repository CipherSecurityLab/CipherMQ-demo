#!/bin/bash

# File: launcher-ciphermq-demo.sh
# Description: Enhanced launcher script for CipherMQ demo
# Version: 2.0

set -e  # Exit on error

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="$ROOT_DIR/progress.state"
LOG_DIR="$ROOT_DIR/logs"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize state file if not exists
if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" << EOL
CERT=0
KEY=0
COPY=0
SERVER=0
EOL
fi

# Create logs directory
mkdir -p "$LOG_DIR"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_warning "Not running as root. Some operations may fail."
fi

# Function to load state
load_state() {
    CERT=0
    KEY=0
    COPY=0
    SERVER=0
    
    while IFS='=' read -r key value; do
        case $key in
            CERT) CERT=$value ;;
            KEY) KEY=$value ;;
            COPY) COPY=$value ;;
            SERVER) SERVER=$value ;;
        esac
    done < "$STATE_FILE"
}

# Function to save state
save_state() {
    cat > "$STATE_FILE" << EOL
CERT=$CERT
KEY=$KEY
COPY=$COPY
SERVER=$SERVER
EOL
}

# Function to check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=0
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 is required but not installed."
        missing_deps=1
    else
        log_success "Python3 found: $(python3 --version)"
    fi
    
    if ! command -v pg_isready &> /dev/null; then
        log_warning "PostgreSQL client (pg_isready) not found."
    else
        log_success "PostgreSQL client found"
    fi
    
    if ! command -v gnome-terminal &> /dev/null && \
       ! command -v xterm &> /dev/null && \
       ! command -v konsole &> /dev/null; then
        log_warning "No terminal emulator found. Will run in background."
    fi
    
    # Check required files
    if [ ! -f "$ROOT_DIR/bin/cert_generator" ]; then
        log_error "cert_generator not found in $ROOT_DIR/bin"
        missing_deps=1
    fi
    
    if [ ! -f "$ROOT_DIR/bin/key_generator" ]; then
        log_error "key_generator not found in $ROOT_DIR/bin"
        missing_deps=1
    fi
    
    if [ ! -f "$ROOT_DIR/bin/ciphermq" ]; then
        log_error "ciphermq binary not found in $ROOT_DIR/bin"
        missing_deps=1
    fi
    
    if [ $missing_deps -eq 1 ]; then
        log_error "Missing required dependencies. Please install them first."
        exit 1
    fi
    
    log_success "All dependencies checked"
}

# Function to generate certificates
generate_certificates() {
    log_info "Generating certificates..."
    
    if [ ! -f "$ROOT_DIR/scripts/generate-certs.sh" ]; then
        log_error "generate-certs.sh not found in $ROOT_DIR/scripts"
        exit 1
    fi
    
    bash "$ROOT_DIR/scripts/generate-certs.sh" > "$LOG_DIR/cert_gen.log" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "Certificates generated successfully"
        log_info "Certificate log: $LOG_DIR/cert_gen.log"
        
        # Verify certificates were created
        if [ -d "$ROOT_DIR/certs" ] && [ "$(ls -A $ROOT_DIR/certs 2>/dev/null)" ]; then
            log_success "Verified: certs directory contains files"
            CERT=1
            save_state
        else
            log_error "Certificates directory is empty"
            exit 1
        fi
    else
        log_error "Certificate generation failed. Check $LOG_DIR/cert_gen.log"
        cat "$LOG_DIR/cert_gen.log"
        exit 1
    fi
}

# Function to generate keys
generate_keys() {
    log_info "Generating encryption keys..."
    
    if [ ! -f "$ROOT_DIR/bin/key_generator" ]; then
        log_error "key_generator not found in $ROOT_DIR/bin"
        exit 1
    fi
    
    cd "$ROOT_DIR"
    "$ROOT_DIR/bin/key_generator" > "$LOG_DIR/key_gen.log" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "Keys generated successfully"
        log_info "Key generation log: $LOG_DIR/key_gen.log"
        KEY=1
        save_state
    else
        log_error "Key generation failed. Check $LOG_DIR/key_gen.log"
        cat "$LOG_DIR/key_gen.log"
        exit 1
    fi
}

# Function to copy files
copy_files() {
    log_info "Copying certificates and keys..."
    
    if [ ! -f "$ROOT_DIR/scripts/copy-cert-key.sh" ]; then
        log_error "copy-cert-key.sh not found in $ROOT_DIR/scripts"
        exit 1
    fi
    
    bash "$ROOT_DIR/scripts/copy-cert-key.sh" > "$LOG_DIR/copy_files.log" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "Files copied successfully"
        log_info "Copy log: $LOG_DIR/copy_files.log"
        
        # Verify files were copied
        if [ -d "$ROOT_DIR/client/receiver_1/keys" ] && \
           [ "$(ls -A $ROOT_DIR/client/receiver_1/keys 2>/dev/null)" ]; then
            log_success "Verified: receiver_1 keys directory contains files"
        else
            log_warning "receiver_1 keys directory is empty"
        fi
        
        if [ -d "$ROOT_DIR/client/sender_1/keys" ] && \
           [ "$(ls -A $ROOT_DIR/client/sender_1/keys 2>/dev/null)" ]; then
            log_success "Verified: sender_1 keys directory contains files"
        else
            log_warning "sender_1 keys directory is empty"
        fi
        
        COPY=1
        save_state
    else
        log_error "File copying failed. Check $LOG_DIR/copy_files.log"
        cat "$LOG_DIR/copy_files.log"
        exit 1
    fi
}

# Function to start server
start_server() {
    log_info "Starting CipherMQ server..."
    
    if [ ! -f "$ROOT_DIR/scripts/start.sh" ]; then
        log_error "start.sh not found in $ROOT_DIR/scripts"
        exit 1
    fi
    
    # Make script executable
    chmod +x "$ROOT_DIR/scripts/start.sh"
    
    # Detect available terminal emulator and launch
    if command -v gnome-terminal &> /dev/null; then
        log_info "Using gnome-terminal..."
        gnome-terminal --title="CipherMQ Server" -- bash -c "cd '$ROOT_DIR' && bash scripts/start.sh 2>&1 | tee '$LOG_DIR/server.log'; echo ''; echo 'Press Enter to close...'; read" &
        SERVER_PID=$!
    elif command -v konsole &> /dev/null; then
        log_info "Using konsole..."
        konsole --new-tab --hold -e bash -c "cd '$ROOT_DIR' && bash scripts/start.sh 2>&1 | tee '$LOG_DIR/server.log'" &
        SERVER_PID=$!
    elif command -v xfce4-terminal &> /dev/null; then
        log_info "Using xfce4-terminal..."
        xfce4-terminal --title="CipherMQ Server" --hold -e "bash -c 'cd $ROOT_DIR && bash scripts/start.sh 2>&1 | tee $LOG_DIR/server.log'" &
        SERVER_PID=$!
    elif command -v xterm &> /dev/null; then
        log_info "Using xterm..."
        xterm -hold -T "CipherMQ Server" -e "cd $ROOT_DIR && bash scripts/start.sh 2>&1 | tee $LOG_DIR/server.log" &
        SERVER_PID=$!
    elif command -v mate-terminal &> /dev/null; then
        log_info "Using mate-terminal..."
        mate-terminal --title="CipherMQ Server" -e "bash -c 'cd $ROOT_DIR && bash scripts/start.sh 2>&1 | tee $LOG_DIR/server.log; read'" &
        SERVER_PID=$!
    elif command -v tilix &> /dev/null; then
        log_info "Using tilix..."
        tilix -e "bash -c 'cd $ROOT_DIR && bash scripts/start.sh 2>&1 | tee $LOG_DIR/server.log; read'" &
        SERVER_PID=$!
    elif command -v terminator &> /dev/null; then
        log_info "Using terminator..."
        terminator -T "CipherMQ Server" -e "bash -c 'cd $ROOT_DIR && bash scripts/start.sh 2>&1 | tee $LOG_DIR/server.log; read'" &
        SERVER_PID=$!
    elif command -v alacritty &> /dev/null; then
        log_info "Using alacritty..."
        alacritty -t "CipherMQ Server" -e bash -c "cd $ROOT_DIR && bash scripts/start.sh 2>&1 | tee $LOG_DIR/server.log; read" &
        SERVER_PID=$!
    elif command -v kitty &> /dev/null; then
        log_info "Using kitty..."
        kitty -T "CipherMQ Server" bash -c "cd $ROOT_DIR && bash scripts/start.sh 2>&1 | tee $LOG_DIR/server.log; read" &
        SERVER_PID=$!
    else
        log_warning "No terminal emulator found. Starting server in background..."
        cd "$ROOT_DIR" && nohup bash scripts/start.sh > "$LOG_DIR/server.log" 2>&1 &
        SERVER_PID=$!
        echo $SERVER_PID > "$ROOT_DIR/server.pid"
        log_info "Server PID saved to $ROOT_DIR/server.pid"
    fi
    
    log_success "Server started (PID: $SERVER_PID)"
    log_info "Server log: $LOG_DIR/server.log"
    
    SERVER=1
    save_state
    
    # Wait for server to initialize
    log_info "Waiting for server to initialize (5 seconds)..."
    sleep 5
    
    # Verify server is running
    if kill -0 $SERVER_PID 2>/dev/null; then
        log_success "Server is running"
    else
        log_warning "Server process may have stopped. Check logs."
    fi
}

# Function to start receiver
start_receiver() {
    log_info "Starting receiver client..."
    
    if [ ! -f "$ROOT_DIR/client/receiver_1/Receiver.py" ]; then
        log_error "Receiver.py not found in $ROOT_DIR/client/receiver_1"
        exit 1
    fi
    
    if [ ! -f "$ROOT_DIR/client/receiver_1/config.json" ]; then
        log_error "config.json not found in $ROOT_DIR/client/receiver_1"
        exit 1
    fi
    
    # Detect available terminal emulator and launch
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal --title="CipherMQ Receiver" -- bash -c "cd '$ROOT_DIR/client/receiver_1' && python3 Receiver.py 2>&1 | tee '$LOG_DIR/receiver.log'; echo ''; echo 'Press Enter to close...'; read" &
        RECEIVER_PID=$!
    elif command -v konsole &> /dev/null; then
        konsole --new-tab --hold -e bash -c "cd '$ROOT_DIR/client/receiver_1' && python3 Receiver.py 2>&1 | tee '$LOG_DIR/receiver.log'" &
        RECEIVER_PID=$!
    elif command -v xfce4-terminal &> /dev/null; then
        xfce4-terminal --title="CipherMQ Receiver" --hold -e "bash -c 'cd $ROOT_DIR/client/receiver_1 && python3 Receiver.py 2>&1 | tee $LOG_DIR/receiver.log'" &
        RECEIVER_PID=$!
    elif command -v xterm &> /dev/null; then
        xterm -hold -T "CipherMQ Receiver" -e "cd $ROOT_DIR/client/receiver_1 && python3 Receiver.py 2>&1 | tee $LOG_DIR/receiver.log" &
        RECEIVER_PID=$!
    elif command -v mate-terminal &> /dev/null; then
        mate-terminal --title="CipherMQ Receiver" -e "bash -c 'cd $ROOT_DIR/client/receiver_1 && python3 Receiver.py 2>&1 | tee $LOG_DIR/receiver.log; read'" &
        RECEIVER_PID=$!
    elif command -v tilix &> /dev/null; then
        tilix -e "bash -c 'cd $ROOT_DIR/client/receiver_1 && python3 Receiver.py 2>&1 | tee $LOG_DIR/receiver.log; read'" &
        RECEIVER_PID=$!
    elif command -v terminator &> /dev/null; then
        terminator -T "CipherMQ Receiver" -e "bash -c 'cd $ROOT_DIR/client/receiver_1 && python3 Receiver.py 2>&1 | tee $LOG_DIR/receiver.log; read'" &
        RECEIVER_PID=$!
    elif command -v alacritty &> /dev/null; then
        alacritty -t "CipherMQ Receiver" -e bash -c "cd $ROOT_DIR/client/receiver_1 && python3 Receiver.py 2>&1 | tee $LOG_DIR/receiver.log; read" &
        RECEIVER_PID=$!
    elif command -v kitty &> /dev/null; then
        kitty -T "CipherMQ Receiver" bash -c "cd $ROOT_DIR/client/receiver_1 && python3 Receiver.py 2>&1 | tee $LOG_DIR/receiver.log; read" &
        RECEIVER_PID=$!
    else
        log_warning "No terminal emulator found. Starting receiver in background..."
        cd "$ROOT_DIR/client/receiver_1" && nohup python3 Receiver.py > "$LOG_DIR/receiver.log" 2>&1 &
        RECEIVER_PID=$!
        echo $RECEIVER_PID > "$ROOT_DIR/receiver.pid"
    fi
    
    log_success "Receiver started (PID: $RECEIVER_PID)"
    log_info "Receiver log: $LOG_DIR/receiver.log"
    
    sleep 2
}

# Function to start sender
start_sender() {
    log_info "Starting sender client..."
    
    if [ ! -f "$ROOT_DIR/client/sender_1/Sender.py" ]; then
        log_error "Sender.py not found in $ROOT_DIR/client/sender_1"
        exit 1
    fi
    
    if [ ! -f "$ROOT_DIR/client/sender_1/config.json" ]; then
        log_error "config.json not found in $ROOT_DIR/client/sender_1"
        exit 1
    fi
    
    # Detect available terminal emulator and launch
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal --title="CipherMQ Sender" -- bash -c "cd '$ROOT_DIR/client/sender_1' && python3 Sender.py 2>&1 | tee '$LOG_DIR/sender.log'; echo ''; echo 'Press Enter to close...'; read" &
        SENDER_PID=$!
    elif command -v konsole &> /dev/null; then
        konsole --new-tab --hold -e bash -c "cd '$ROOT_DIR/client/sender_1' && python3 Sender.py 2>&1 | tee '$LOG_DIR/sender.log'" &
        SENDER_PID=$!
    elif command -v xfce4-terminal &> /dev/null; then
        xfce4-terminal --title="CipherMQ Sender" --hold -e "bash -c 'cd $ROOT_DIR/client/sender_1 && python3 Sender.py 2>&1 | tee $LOG_DIR/sender.log'" &
        SENDER_PID=$!
    elif command -v xterm &> /dev/null; then
        xterm -hold -T "CipherMQ Sender" -e "cd $ROOT_DIR/client/sender_1 && python3 Sender.py 2>&1 | tee $LOG_DIR/sender.log" &
        SENDER_PID=$!
    elif command -v mate-terminal &> /dev/null; then
        mate-terminal --title="CipherMQ Sender" -e "bash -c 'cd $ROOT_DIR/client/sender_1 && python3 Sender.py 2>&1 | tee $LOG_DIR/sender.log; read'" &
        SENDER_PID=$!
    elif command -v tilix &> /dev/null; then
        tilix -e "bash -c 'cd $ROOT_DIR/client/sender_1 && python3 Sender.py 2>&1 | tee $LOG_DIR/sender.log; read'" &
        SENDER_PID=$!
    elif command -v terminator &> /dev/null; then
        terminator -T "CipherMQ Sender" -e "bash -c 'cd $ROOT_DIR/client/sender_1 && python3 Sender.py 2>&1 | tee $LOG_DIR/sender.log; read'" &
        SENDER_PID=$!
    elif command -v alacritty &> /dev/null; then
        alacritty -t "CipherMQ Sender" -e bash -c "cd $ROOT_DIR/client/sender_1 && python3 Sender.py 2>&1 | tee $LOG_DIR/sender.log; read" &
        SENDER_PID=$!
    elif command -v kitty &> /dev/null; then
        kitty -T "CipherMQ Sender" bash -c "cd $ROOT_DIR/client/sender_1 && python3 Sender.py 2>&1 | tee $LOG_DIR/sender.log; read" &
        SENDER_PID=$!
    else
        log_warning "No terminal emulator found. Starting sender in background..."
        cd "$ROOT_DIR/client/sender_1" && nohup python3 Sender.py > "$LOG_DIR/sender.log" 2>&1 &
        SENDER_PID=$!
        echo $SENDER_PID > "$ROOT_DIR/sender.pid"
    fi
    
    log_success "Sender started (PID: $SENDER_PID)"
    log_info "Sender log: $LOG_DIR/sender.log"
}

# Main function to run all steps sequentially
run_all() {
    echo "========================================"
    echo "CipherMQ Demo Launcher v1.0"
    echo "========================================"
    echo ""
    
    load_state
    check_dependencies
    
    echo ""
    
    if [ "$CERT" -ne 1 ]; then
        generate_certificates
    else
        log_info "Certificates already generated (skipping)"
    fi
    
    echo ""
    
    if [ "$KEY" -ne 1 ]; then
        generate_keys
    else
        log_info "Keys already generated (skipping)"
    fi
    
    echo ""
    
    if [ "$COPY" -ne 1 ]; then
        copy_files
    else
        log_info "Files already copied (skipping)"
    fi
    
    echo ""
    
    if [ "$SERVER" -ne 1 ]; then
        start_server
    else
        log_info "Server already started (skipping)"
    fi
    
    echo ""
    
    start_receiver
    
    echo ""
    
    start_sender
    
    echo ""
    echo "========================================"
    log_success "CipherMQ demo is now running!"
    echo "========================================"
    echo ""
    echo "Components started:"
    echo "  - Server: $LOG_DIR/server.log"
    echo "  - Receiver: $LOG_DIR/receiver.log"
    echo "  - Sender: $LOG_DIR/sender.log"
    echo ""
    log_info "Press Ctrl+C to exit (components will continue running)"
    echo ""
    
    # Keep script running
    wait
}

# Menu for manual control
menu() {
    while true; do
        clear
        load_state
        echo "========================================"
        echo "CipherMQ Launcher - Demo Version 1.0"
        echo "========================================"
        echo ""
        echo "Progress Status:"
        echo "  [Certificates: $([ $CERT -eq 1 ] && echo '✓' || echo '✗')] [Keys: $([ $KEY -eq 1 ] && echo '✓' || echo '✗')] [Copy: $([ $COPY -eq 1 ] && echo '✓' || echo '✗')] [Server: $([ $SERVER -eq 1 ] && echo '✓' || echo '✗')]"
        echo ""
        echo "Options:"
        echo "  1. Generate Certificates"
        echo "  2. Generate Keys"
        echo "  3. Copy Files"
        echo "  4. Start Server"
        echo "  5. Start Receiver"
        echo "  6. Start Sender"
        echo "  7. View Logs"
        echo "  8. Reset Progress"
        echo "  9. Stop All & Exit"
        echo ""
        echo -n "Select option (1-9): "
        read -r choice
        
        echo ""
        
        case $choice in
            1) generate_certificates ;;
            2) generate_keys ;;
            3) copy_files ;;
            4) start_server ;;
            5) start_receiver ;;
            6) start_sender ;;
            7) view_logs ;;
            8) reset_progress ;;
            9) stop_all_and_exit ;;
            *) log_error "Invalid choice. Please select 1-9." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Function to view logs
view_logs() {
    echo "Available logs:"
    echo "  1. Server log"
    echo "  2. Receiver log"
    echo "  3. Sender log"
    echo "  4. Certificate generation log"
    echo "  5. Key generation log"
    echo "  6. Copy files log"
    echo "  0. Back"
    echo ""
    echo -n "Select log to view (0-6): "
    read -r log_choice
    
    case $log_choice in
        1) [ -f "$LOG_DIR/server.log" ] && tail -50 "$LOG_DIR/server.log" || log_error "Log not found" ;;
        2) [ -f "$LOG_DIR/receiver.log" ] && tail -50 "$LOG_DIR/receiver.log" || log_error "Log not found" ;;
        3) [ -f "$LOG_DIR/sender.log" ] && tail -50 "$LOG_DIR/sender.log" || log_error "Log not found" ;;
        4) [ -f "$LOG_DIR/cert_gen.log" ] && cat "$LOG_DIR/cert_gen.log" || log_error "Log not found" ;;
        5) [ -f "$LOG_DIR/key_gen.log" ] && cat "$LOG_DIR/key_gen.log" || log_error "Log not found" ;;
        6) [ -f "$LOG_DIR/copy_files.log" ] && cat "$LOG_DIR/copy_files.log" || log_error "Log not found" ;;
        0) return ;;
        *) log_error "Invalid choice" ;;
    esac
}

# Function to reset progress
reset_progress() {
    log_warning "Resetting progress will clear all state markers"
    echo -n "Are you sure? (Y/N): "
    read -r confirm
    
    if [ "${confirm^^}" == "Y" ]; then
        cat > "$STATE_FILE" << EOL
CERT=0
KEY=0
COPY=0
SERVER=0
EOL
        log_success "Progress reset successfully"
    else
        log_info "Reset cancelled"
    fi
}

# Function to stop all processes and exit
stop_all_and_exit() {
    echo ""
    echo "========================================"
    log_warning "Stopping all CipherMQ components..."
    echo "========================================"
    echo ""
    
    # Function to stop process by PID file
    stop_process_by_pid() {
        local name=$1
        local pid_file=$2
        
        if [ -f "$pid_file" ]; then
            PID=$(cat "$pid_file")
            if kill -0 $PID 2>/dev/null; then
                log_info "Stopping $name (PID: $PID)..."
                kill $PID 2>/dev/null || true
                sleep 1
                
                # Force kill if still running
                if kill -0 $PID 2>/dev/null; then
                    log_warning "Force killing $name (PID: $PID)..."
                    kill -9 $PID 2>/dev/null || true
                fi
                
                log_success "$name stopped"
            else
                log_info "$name is not running"
            fi
            rm -f "$pid_file"
        fi
    }
    
    # Stop processes by PID files
    stop_process_by_pid "Server" "$ROOT_DIR/server.pid"
    stop_process_by_pid "Receiver" "$ROOT_DIR/receiver.pid"
    stop_process_by_pid "Sender" "$ROOT_DIR/sender.pid"
    
    echo ""
    log_info "Searching for remaining CipherMQ processes..."
    
    # Find and kill any remaining processes
    CIPHERMQ_PIDS=$(pgrep -f "bin/ciphermq" 2>/dev/null || true)
    RECEIVER_PIDS=$(pgrep -f "Receiver.py" 2>/dev/null || true)
    SENDER_PIDS=$(pgrep -f "Sender.py" 2>/dev/null || true)
    
    ALL_PIDS="$CIPHERMQ_PIDS $RECEIVER_PIDS $SENDER_PIDS"
    ALL_PIDS=$(echo $ALL_PIDS | tr ' ' '\n' | sort -u | tr '\n' ' ')
    
    if [ ! -z "$ALL_PIDS" ]; then
        log_warning "Found running processes: $ALL_PIDS"
        echo ""
        ps aux | grep -E "bin/ciphermq|Receiver.py|Sender.py" | grep -v grep || true
        echo ""
        echo -n "Kill these processes? (Y/N): "
        read -r response
        
        if [ "${response^^}" == "Y" ]; then
            for pid in $ALL_PIDS; do
                if [ ! -z "$pid" ]; then
                    log_info "Killing PID: $pid"
                    kill -9 $pid 2>/dev/null || true
                fi
            done
            log_success "All processes killed"
        else
            log_info "Processes left running"
        fi
    else
        log_success "No CipherMQ processes found"
    fi
    
    echo ""
    echo "========================================"
    log_success "Cleanup complete. Exiting..."
    echo "========================================"
    echo ""
    
    exit 0
}

# Disable exit on error for menu mode
set +e

# Check for command-line argument
if [ "$1" == "--stop" ]; then
    stop_all_and_exit
else
    menu
fi