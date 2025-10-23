#!/bin/bash

# Enable debug mode if DEBUG=1
if [ "$DEBUG" == "1" ]; then
    set -x
fi

echo "========================================"
echo "Generating certificates for CipherMQ"
echo "Version 1.0"
echo "========================================"
echo ""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CERTS_DIR="$ROOT_DIR/certs"
CLIENTS_CERTS_DIR="$CERTS_DIR/clients"

# Create certs and clients directories
mkdir -p "$CLIENTS_CERTS_DIR/receiver_1" "$CLIENTS_CERTS_DIR/sender_1"

echo "Generating CA, receiver_1, sender_1 in $CERTS_DIR..."
"$ROOT_DIR/bin/cert_generator" receiver_1 sender_1

if [ $? -ne 0 ]; then
    echo "[ERROR] Certificate generation failed: $?"
    read -p "Press Enter to continue..."
    exit $?
fi

# Verify generated files
echo "Verifying generated files..."
EXPECTED_FILES=("$CERTS_DIR/ca.crt" "$CERTS_DIR/ca.key" "$CERTS_DIR/server.crt" "$CERTS_DIR/server.key")
ISSUES=0

for file in "${EXPECTED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "[ERROR] Missing expected file: $file"
        ISSUES=1
    fi
done

# Verify client directories
for client in receiver_1 sender_1; do
    if [ ! -d "$CLIENTS_CERTS_DIR/$client" ]; then
        echo "[ERROR] Missing client directory: $CLIENTS_CERTS_DIR/$client"
        ISSUES=1
    else
        FILE_COUNT=$(ls -1 "$CLIENTS_CERTS_DIR/$client"/*.crt "$CLIENTS_CERTS_DIR/$client"/*.key 2>/dev/null | wc -l)
        if [ "$FILE_COUNT" -eq 0 ]; then
            echo "[WARNING] No certificate or key files found in $CLIENTS_CERTS_DIR/$client"
            ISSUES=1
        else
            echo "Found $FILE_COUNT files in $CLIENTS_CERTS_DIR/$client"
            ls -la "$CLIENTS_CERTS_DIR/$client"
        fi
    fi
done

if [ $ISSUES -eq 0 ]; then
    echo "[SUCCESS] Certificate generation completed successfully!"
    exit 0
else
    echo "[WARNING] Certificate generation completed with issues. Check logs above."
    exit 1
fi