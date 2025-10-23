#!/bin/bash

# Script to stop all CipherMQ components

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "Stopping CipherMQ Components"
echo "========================================"
echo ""

# Function to stop process
stop_process() {
    local name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        PID=$(cat "$pid_file")
        if kill -0 $PID 2>/dev/null; then
            echo -e "${YELLOW}[STOPPING]${NC} $name (PID: $PID)..."
            kill $PID 2>/dev/null || true
            sleep 2
            
            # Check if process is still running
            if kill -0 $PID 2>/dev/null; then
                echo -e "${YELLOW}[FORCE KILL]${NC} $name (PID: $PID)..."
                kill -9 $PID 2>/dev/null || true
            fi
            
            echo -e "${GREEN}[SUCCESS]${NC} $name stopped"
        else
            echo -e "${BLUE}[INFO]${NC} $name is not running (PID: $PID)"
        fi
        rm -f "$pid_file"
    else
        echo -e "${BLUE}[INFO]${NC} No PID file found for $name"
    fi
}

# Stop components by PID files
stop_process "Server" "$ROOT_DIR/server.pid"
stop_process "Receiver" "$ROOT_DIR/receiver.pid"
stop_process "Sender" "$ROOT_DIR/sender.pid"

echo ""
echo "Checking for remaining CipherMQ processes..."

# Find and kill any remaining processes
CIPHERMQ_PIDS=$(pgrep -f "bin/ciphermq" 2>/dev/null || true)
RECEIVER_PIDS=$(pgrep -f "Receiver.py" 2>/dev/null || true)
SENDER_PIDS=$(pgrep -f "Sender.py" 2>/dev/null || true)

ALL_PIDS="$CIPHERMQ_PIDS $RECEIVER_PIDS $SENDER_PIDS"
ALL_PIDS=$(echo $ALL_PIDS | tr ' ' '\n' | sort -u | tr '\n' ' ')

if [ ! -z "$ALL_PIDS" ]; then
    echo -e "${YELLOW}[WARNING]${NC} Found running processes:"
    echo ""
    ps aux | grep -E "bin/ciphermq|Receiver.py|Sender.py" | grep -v grep || true
    echo ""
    echo -n "Kill these processes? (Y/N): "
    read -r response
    
    if [ "${response^^}" == "Y" ]; then
        for pid in $ALL_PIDS; do
            if [ ! -z "$pid" ]; then
                echo "Killing PID: $pid"
                kill -9 $pid 2>/dev/null || true
            fi
        done
        echo -e "${GREEN}[SUCCESS]${NC} All processes killed"
    else
        echo -e "${BLUE}[INFO]${NC} Processes left running"
    fi
else
    echo -e "${GREEN}[SUCCESS]${NC} No CipherMQ processes found"
fi

echo ""
echo "========================================"
echo -e "${GREEN}[SUCCESS]${NC} Cleanup complete"
echo "========================================"
echo ""

exit 0