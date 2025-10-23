#!/bin/bash

# Enable debug mode if DEBUG=1
if [ "$DEBUG" == "1" ]; then
    set -x
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "========================================"
echo "Copying certificates and keys for CipherMQ"
echo "========================================"
echo "Root directory: $ROOT_DIR"
echo ""

# Define paths
CERTS_DIR="$ROOT_DIR/certs"
CLIENTS_CERTS_DIR="$CERTS_DIR/clients"
CLIENT_DIR="$ROOT_DIR/client"
RECEIVER_KEYS_DEST="$CLIENT_DIR/receiver_1/keys"
SENDER_KEYS_DEST="$CLIENT_DIR/sender_1/keys"

# Debug: Show directory structure
echo "=== Directory Structure Check ==="
echo "Checking ROOT: $ROOT_DIR"
ls -la "$ROOT_DIR"/*.key 2>/dev/null && echo "Found .key files in ROOT" || echo "No .key files in ROOT"
echo ""
echo "Checking CERTS_DIR: $CERTS_DIR"
ls -la "$CERTS_DIR"/*.key "$CERTS_DIR"/*.crt 2>/dev/null && echo "Found .key/.crt files in CERTS_DIR" || echo "No .key/.crt files in CERTS_DIR"
echo ""
echo "Checking CLIENTS_CERTS_DIR: $CLIENTS_CERTS_DIR"
[ -d "$CLIENTS_CERTS_DIR" ] && ls -la "$CLIENTS_CERTS_DIR" || echo "Directory does not exist"
echo ""
echo "================================="
echo ""

# Create destination directories
mkdir -p "$RECEIVER_KEYS_DEST"
mkdir -p "$SENDER_KEYS_DEST"

echo "Step 1: Copying certificates for receiver_1..."
if [ -d "$CLIENTS_CERTS_DIR/receiver_1" ]; then
    echo "Source: $CLIENTS_CERTS_DIR/receiver_1"
    echo "Destination: $RECEIVER_KEYS_DEST"
    
    # Copy ca.crt
    if [ -f "$CERTS_DIR/ca.crt" ]; then
        cp -fv "$CERTS_DIR/ca.crt" "$RECEIVER_KEYS_DEST/" 2>&1
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to copy ca.crt to $RECEIVER_KEYS_DEST"
            exit 1
        fi
    else
        echo "[ERROR] ca.crt not found in $CERTS_DIR"
        exit 1
    fi
    
    # Copy receiver_1 certificates and keys
    FILE_COUNT=$(ls -1 "$CLIENTS_CERTS_DIR/receiver_1"/*.crt "$CLIENTS_CERTS_DIR/receiver_1"/*.key 2>/dev/null | wc -l)
    echo "Files to copy: $FILE_COUNT"
    
    if [ $FILE_COUNT -gt 0 ]; then
        cp -fv "$CLIENTS_CERTS_DIR/receiver_1"/*.{crt,key} "$RECEIVER_KEYS_DEST/" 2>&1
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] Copied receiver_1 certs and keys to $RECEIVER_KEYS_DEST"
            echo "Files copied:"
            ls -la "$RECEIVER_KEYS_DEST"
        else
            echo "[ERROR] Failed to copy receiver_1 certificates and keys"
            exit 1
        fi
    else
        echo "[WARNING] No .crt or .key files found in $CLIENTS_CERTS_DIR/receiver_1"
    fi
else
    echo "[ERROR] Directory $CLIENTS_CERTS_DIR/receiver_1 does not exist"
    exit 1
fi

echo ""
echo "Step 2: Copying certificates for sender_1..."
if [ -d "$CLIENTS_CERTS_DIR/sender_1" ]; then
    echo "Source: $CLIENTS_CERTS_DIR/sender_1"
    echo "Destination: $SENDER_KEYS_DEST"
    
    # Copy ca.crt
    if [ -f "$CERTS_DIR/ca.crt" ]; then
        cp -fv "$CERTS_DIR/ca.crt" "$SENDER_KEYS_DEST/" 2>&1
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to copy ca.crt to $SENDER_KEYS_DEST"
            exit 1
        fi
    else
        echo "[ERROR] ca.crt not found in $CERTS_DIR"
        exit 1
    fi
    
    # Copy sender_1 certificates and keys
    FILE_COUNT=$(ls -1 "$CLIENTS_CERTS_DIR/sender_1"/*.crt "$CLIENTS_CERTS_DIR/sender_1"/*.key 2>/dev/null | wc -l)
    echo "Files to copy: $FILE_COUNT"
    
    if [ $FILE_COUNT -gt 0 ]; then
        cp -fv "$CLIENTS_CERTS_DIR/sender_1"/*.{crt,key} "$SENDER_KEYS_DEST/" 2>&1
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] Copied sender_1 certs and keys to $SENDER_KEYS_DEST"
            echo "Files copied:"
            ls -la "$SENDER_KEYS_DEST"
        else
            echo "[ERROR] Failed to copy sender_1 certificates and keys"
            exit 1
        fi
    else
        echo "[WARNING] No .crt or .key files found in $CLIENTS_CERTS_DIR/sender_1"
    fi
else
    echo "[ERROR] Directory $CLIENTS_CERTS_DIR/sender_1 does not exist"
    exit 1
fi

echo ""
echo "Step 3: Moving .key files from root to receiver_1/keys..."
echo "Searching in: $ROOT_DIR"

KEY_FILES_FOUND=0
# List all .key files in the root directory
KEY_FILES=("$ROOT_DIR"/*.key)

for keyfile in "${KEY_FILES[@]}"; do
    if [ -f "$keyfile" ]; then
        KEY_FILES_FOUND=1
        FILENAME=$(basename "$keyfile")
        echo "  Found: $FILENAME"
        
        # Check if file already exists in destination
        if [ -f "$RECEIVER_KEYS_DEST/$FILENAME" ]; then
            echo "  [WARNING] $FILENAME already exists in destination, replacing..."
            rm -f "$RECEIVER_KEYS_DEST/$FILENAME"
        fi
        
        # Move the file
        mv -v "$keyfile" "$RECEIVER_KEYS_DEST/" 2>&1
        if [ $? -eq 0 ]; then
            echo "  [SUCCESS] Moved $FILENAME to $RECEIVER_KEYS_DEST"
        else
            echo "  [ERROR] Failed to move $FILENAME"
            exit 1
        fi
    fi
done

if [ $KEY_FILES_FOUND -eq 0 ]; then
    echo ""
    echo "[WARNING] No .key files found in $ROOT_DIR"
    echo "If cert_generator created keys, they might be in an unexpected location."
    echo "Try running: find $ROOT_DIR -name '*.key' -type f"
fi

echo ""
echo "Step 4: Verification..."
echo "Checking receiver_1/keys directory:"
if [ -d "$RECEIVER_KEYS_DEST" ]; then
    FILE_COUNT=$(ls -1 "$RECEIVER_KEYS_DEST" 2>/dev/null | wc -l)
    echo "Total files in receiver_1/keys: $FILE_COUNT"
    ls -lah "$RECEIVER_KEYS_DEST"
    if [ "$FILE_COUNT" -lt 3 ]; then
        echo "[WARNING] Expected at least 3 files in $RECEIVER_KEYS_DEST, found $FILE_COUNT"
    fi
else
    echo "[ERROR] Destination directory $RECEIVER_KEYS_DEST was not created"
    exit 1
fi

echo ""
echo "Checking sender_1/keys directory:"
if [ -d "$SENDER_KEYS_DEST" ]; then
    FILE_COUNT=$(ls -1 "$SENDER_KEYS_DEST" 2>/dev/null | wc -l)
    echo "Total files in sender_1/keys: $FILE_COUNT"
    ls -lah "$SENDER_KEYS_DEST"
    if [ "$FILE_COUNT" -lt 3 ]; then
        echo "[WARNING] Expected at least 3 files in $SENDER_KEYS_DEST, found $FILE_COUNT"
    fi
else
    echo "[ERROR] Destination directory $SENDER_KEYS_DEST was not created"
    exit 1
fi

echo ""
echo "========================================"
echo "Copy and move operation completed!"
echo "========================================"
echo ""
echo "Summary:"
echo "- Certs source: $CLIENTS_CERTS_DIR"
echo "- Receiver keys: $RECEIVER_KEYS_DEST"
echo "- Sender keys: $SENDER_KEYS_DEST"
echo "- Key files found and moved from root: $KEY_FILES_FOUND"
echo ""

# Final check
ISSUES=0
if [ ! -d "$RECEIVER_KEYS_DEST" ] || [ ! "$(ls -A $RECEIVER_KEYS_DEST 2>/dev/null)" ]; then
    echo "[WARNING] receiver_1/keys is empty or missing"
    ISSUES=1
fi

if [ ! -d "$SENDER_KEYS_DEST" ] || [ ! "$(ls -A $SENDER_KEYS_DEST 2>/dev/null)" ]; then
    echo "[WARNING] sender_1/keys is empty or missing"
    ISSUES=1
fi

if [ $ISSUES -eq 0 ]; then
    echo "[SUCCESS] All files copied and moved successfully!"
    exit 0
else
    echo "[WARNING] Some files may be missing. Please check the logs above."
    exit 0
fi