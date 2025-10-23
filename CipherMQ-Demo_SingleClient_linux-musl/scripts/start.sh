#!/bin/bash

echo "========================================"
echo "CipherMQ Server - Starting"
echo "Demo Version 1.0"
echo "========================================"
echo ""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Check configuration file
if [ ! -f "config.toml" ]; then
    echo "[ERROR] Configuration file not found!"
    echo "Please ensure config.toml exists in $ROOT_DIR"
    echo ""
    read -p "Press Enter to continue..."
    exit 1
fi

# Check TLS certificates
if [ ! -f "certs/server.crt" ] || [ ! -f "certs/server.key" ]; then
    echo "[ERROR] TLS certificates not found!"
    echo "Expected files:"
    echo "  - $ROOT_DIR/certs/server.crt"
    echo "  - $ROOT_DIR/certs/server.key"
    echo ""
    echo "Please generate certificates first using:"
    echo "  bash scripts/generate-certs.sh"
    echo ""
    read -p "Press Enter to continue..."
    exit 1
fi

# Check ca.crt
if [ ! -f "certs/ca.crt" ]; then
    echo "[WARNING] CA certificate not found at certs/ca.crt"
fi

# Create logs directory if it doesn't exist
mkdir -p "$ROOT_DIR/logs"

# Check PostgreSQL connection
echo "Checking PostgreSQL connection..."
if command -v pg_isready &> /dev/null; then
    pg_isready -h localhost -p 5432 > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "[WARNING] PostgreSQL is not running or not accessible!"
        echo "Server may fail to start without database connection."
        echo ""
        read -p "Do you want to continue anyway? (Y/N): " continue
        if [ "${continue^^}" != "Y" ]; then
            exit 1
        fi
    else
        echo "[SUCCESS] PostgreSQL is running"
    fi
else
    echo "[WARNING] pg_isready not found, skipping PostgreSQL check"
fi

# Check if ciphermq binary exists
if [ ! -f "$ROOT_DIR/bin/ciphermq" ]; then
    echo "[ERROR] ciphermq binary not found at $ROOT_DIR/bin/ciphermq"
    exit 1
fi

# Make binary executable
chmod +x "$ROOT_DIR/bin/ciphermq"

echo ""
echo "Starting CipherMQ Message Broker Server..."
echo "Server directory: $ROOT_DIR"
echo "Configuration: $ROOT_DIR/config.toml"
echo "Certificates: $ROOT_DIR/certs/"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "========================================"
echo ""

# Run the server
"$ROOT_DIR/bin/ciphermq"

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "[ERROR] Server exited with error code: $EXIT_CODE"
    echo ""
    echo "Common issues:"
    echo "  - Port already in use"
    echo "  - Database connection failed"
    echo "  - Invalid configuration"
    echo "  - Missing certificates"
    echo ""
    read -p "Press Enter to continue..."
    exit $EXIT_CODE
fi

echo ""
echo "Server stopped gracefully"