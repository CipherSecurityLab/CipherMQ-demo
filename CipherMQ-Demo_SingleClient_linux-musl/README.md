# CipherMQ Demo Setup Guide (Linux)

## About the Demo

This demo version of CipherMQ provides a simplified setup to experience secure message passing using Mutual TLS (mTLS) and hybrid encryption. It includes a pre-configured server, sender, and receiver, with a bash script (`launcher-ciphermq-demo.sh`) to automate setup and execution. This demo is ideal for users who want to quickly test CipherMQ's core functionality without the complexity of the full project setup.

---

## System Overview

- **Server**: Manages message queues and relays encrypted messages to subscribed clients.
- **Sender**: Encrypts and sends messages to the server for distribution.
- **Receiver**: Receives and decrypts messages from the server.

This guide walks you through running the demo using the provided launcher script. For a comprehensive understanding of CipherMQ, refer to the [main project](https://github.com/CipherSecurityLab/CipherMQ).

---

## Architecture Overview

### Security Layers

1. **Transport Security (mTLS)**:
   - All connections use Mutual TLS authentication.
   - Both client and server verify each other's certificates.
   - Protects against man-in-the-middle attacks.

2. **Message Encryption (Hybrid Cryptography)**:
   - X25519 key exchange for secure key agreement.
   - ChaCha20-Poly1305 for fast authenticated encryption.
   - End-to-end encryption ensures the server cannot read messages.

3. **Key Distribution**:
   - Receiver client has its own key pair.
   - Public keys are exchanged securely.
   - Private keys never leave the client machine.

---

## Prerequisites

To run the CipherMQ demo, ensure the following are installed:

- **Python 3.8 or Higher**
  - Verify: `python3 --version`
  
  - Python Libraries Install: `pip3 install cryptography PyNaCl`
  
- **PostgreSQL 10 or Higher**
  - Create the `ciphermq` database (see Database Setup).

- **OpenSSL**
  - Verify: `openssl version`

- **Terminal Emulator**
  - Required for launching server and client processes in separate terminal windows.
  - Supported emulators: `gnome-terminal`, `konsole`, `xfce4-terminal`, `xterm`, `mate-terminal`, `tilix`, `terminator`, `alacritty`, `kitty`.
> **Note**: The `gnome-terminal` is recommended for installation.

### Database Setup

1. Start PostgreSQL:
   ```bash
   sudo systemctl start postgresql
   sudo -u postgres psql
   ```

2. Execute the following commands:
   ```sql
   CREATE USER mq_user WITH PASSWORD 'mq_pass';
   CREATE DATABASE ciphermq;
   GRANT ALL PRIVILEGES ON DATABASE ciphermq TO mq_user;
   \c ciphermq
   GRANT ALL PRIVILEGES ON SCHEMA public TO mq_user;
   ```

### Verify Installation

1. **Verify Python and libraries:**

   ```bash
   python3 -c "import cryptography; import nacl; print('Python libraries OK')"
   ```

   If you do not have these libraries install them:

   ```
   pip install cryptography nacl
   ```

2. **Verify PostgreSQL:**

   ```bash
   pg_isready -h localhost -p 5432
   ```

   

---

## Clone the Repository

Clone the project repository from GitHub:
```bash
git clone https://github.com/CipherSecurityLab/CipherMQ-demo
cd CipherMQ-Demo_SingleClient_linux-musl
```

---

## Configuration

### Server Configuration (`server/config.toml`)

Update the server configuration file at `server/config.toml`:

```toml
[server]
address = "127.0.0.1:5672"
connection_type = "tls"

[tls]
cert_path = "certs/server.crt"
key_path = "certs/server.key"
ca_cert_path = "certs/ca.crt"

[logging]
level = "info"
info_file_path = "logs/server_info.log"
debug_file_path = "logs/server_debug.log"
error_file_path = "logs/server_error.log"
rotation = "daily"
max_size_mb = 100

[database]
host = "localhost"
port = 5432
user = "mq_user"
password = "mq_pass"
dbname = "ciphermq"

[encryption]
algorithm = "x25519_chacha20_poly1305"
aes_key = "YOUR_BASE64_ENCODED_32_BYTE_AES_KEY"
```

> **Note**: Replace `YOUR_BASE64_ENCODED_32_BYTE_AES_KEY` with a 32-byte key encoded in base64. Generate it using:
> ```bash
> openssl rand -base64 32
> ```

> **Note**: Ensure the `[database]` section matches the PostgreSQL database setup (`mq_user`, `mq_pass`, `ciphermq`). Update these values if you used different credentials or database name during the Database Setup step.

---

## Setup Steps

### Grant Execute Permissions

Before running the launcher, ensure the necessary scripts and binaries have execute permissions:
```bash
chmod +x launcher-ciphermq-demo.sh
chmod +x scripts/*.sh
chmod +x bin/*
```

### Quick Start with Launcher

Run the launcher script from the project root directory:
```bash
./launcher-ciphermq-demo.sh
```

Then follow these steps in order:

### Step 1: Generate Certificates

1. In the launcher menu, select option `1`: **Generate Certificates**.
2. The system will generate certificates for server and clients.
3. Files are stored in the `certs/` directory.

**What happens**: Creates TLS certificates (CA, server, and client certificates) for mutual authentication between server and clients.

### Step 2: Generate Keys

1. Select option `2`: **Generate Keys**.
2. Wait for the encryption keys to be generated.
3. Files (`.key`) are created in the project root directory.

**What happens**: Creates X25519 public/private key pairs for end-to-end encryption.

### Step 3: Copy Files

1. Select option `3`: **Copy Files**.
2. This operation:
   - Copies TLS certificates to the appropriate client directories.
   - Copies encryption keys to `client/receiver_1/keys/` and `client/sender_1/keys/`.

**What happens**: Distributes all certificates and keys to their proper locations.

### Step 4: Start the Server

1. Select option `4`: **Run Server**.
2. A new terminal window will open running the server.
3. **Wait 5-10 seconds** for the server to fully initialize before starting clients.

**What happens**: Starts the message broker that relays messages between sender and receiver.

### Step 5: Start the Receiver

1. Select option `5`: **Run Receiver**.
2. A new terminal window will open for the receiver.
3. Data are stored in `client/Receiver_1/data`.

**What happens**: The receiver connects to the server with mTLS and waits for encrypted messages.

### Step 6: Start the Sender

1. Select option `6`: **Run Sender**.
2. A new terminal window will open for the sender.

**What happens**:
- Sender encrypts the message.
- Sends it to the server for relay to the receiver.

### Step 7: View Logs

1. Select option `7`: **View Logs**.
2. Choose from:
   - Server log (`logs/server.log`)
   - Receiver log (`logs/receiver.log`)
   - Sender log (`logs/sender.log`)
   - Certificate generation log (`logs/cert_gen.log`)
   - Key generation log (`logs/key_gen.log`)
   - Copy files log (`logs/copy_files.log`)

**What happens**: Displays the selected log file for debugging or monitoring.

### Step 8: Reset Progress

1. Select option `8`: **Reset Progress**.
2. Confirm (Y/N).
3. Run the launcher again to start fresh

**What happens**: Clears progress markers to allow restarting the setup process from scratch.

### Step 9: Stop All & Exit

1. Select option `9`: **Stop All & Exit**.
2. Confirm (Y/N).
3. Stops all running processes and deletes PID files.

**What happens**: Terminates all CipherMQ components and exits the launcher.

---

## Important Notes & Troubleshooting

### Root Privileges

- **Run with Sufficient Permissions**: Some operations (e.g., certificate generation, file copying) may require elevated permissions. If you encounter permission errors, try running the launcher with `sudo`:
  ```bash
  sudo ./launcher-ciphermq-demo.sh
  ```

### Step Dependencies

- **Follow the order**: Steps must be performed sequentially (1 → 2 → 3 → 4 → 5 → 6).
- Each step depends on the previous one completing successfully.
- The launcher will warn you if you skip steps, but it's best to follow the order.

### Monitoring Running Processes

To check for running CipherMQ processes:
```bash
ps aux | grep -E "ciphermq|Receiver.py|Sender.py"
```



### Common Issues and Solutions

#### Issue: "Not running as root"
**Solution**:
- Close the launcher and run it with `sudo`:
  ```bash
  sudo ./launcher-ciphermq-demo.sh
  ```



#### Issue: "Certificate generation failed"

**Solution**:
- Ensure OpenSSL is installed and in your PATH:
  ```bash
  openssl version
  ```
  
- Check if `bin/cert_generator` exists:
  ```bash
  ls -l bin/cert_generator
  ```
  
  



#### Issue: "Python files not found"

**Solution**:
- Verify `Receiver.py` exists in `client/receiver_1/`:
  ```bash
  ls -l client/receiver_1/Receiver.py
  ```
- Verify `Sender.py` exists in `client/sender_1/`:
  ```bash
  ls -l client/sender_1/Sender.py
  ```
- Verify `config.json` files exist in each client directory:
  ```bash
  ls -l client/receiver_1/config.json
  ls -l client/sender_1/config.json
  ```



#### Issue: "Server won't start"

**Solution**:
- Verify PostgreSQL is running:
  ```bash
  pg_isready -h localhost -p 5432
  ```
- Check database credentials in `server/config.toml`:
  ```bash
  cat server/config.toml
  ```
- Ensure port 5672 is not already in use:
  ```bash
  netstat -tuln | grep 5672
  ```
- Verify certificates were copied to `certs/`:
  ```bash
  ls -l certs/
  ```



#### Issue: "Client can't connect to server"

**Solution**:
- Ensure the server is running (Step 4) before starting clients.
- Wait 5-10 seconds after starting the server for initialization.
- Check that certificates were copied correctly (Step 3):
  ```bash
  ls -l client/receiver_1/certs/
  ls -l client/sender_1/certs/
  ```
- Verify server address in client `config.json` files:
  ```bash
  cat client/receiver_1/config.json
  cat client/sender_1/config.json
  ```



#### Issue: "Receiver doesn't get messages"

**Solution**:
- Ensure both server and receiver are running:
  ```bash
  ps aux | grep -E "ciphermq|Receiver.py"
  ```
- Check that encryption keys were copied correctly to `client/receiver_1/keys/`:
  ```bash
  ls -l client/receiver_1/keys/
  ```
- Verify the sender is connected and sending messages:
  ```bash
  ps aux | grep Sender.py
  ```
- Check client logs for error messages:
  ```bash
  cat logs/receiver.log
  cat logs/sender.log
  ```



#### Issue: "Terminal emulator not found"

**Solution**:
- Ensure a supported terminal emulator is installed:
  ```bash
  gnome-terminal --version || konsole --version || xterm -version
  ```
- Install `gnome-terminal` if missing:
  ```bash
  sudo apt install gnome-terminal
  ```

---

## Learn More

For detailed information about CipherMQ’s architecture, features, and future improvements, refer to the [main project](https://github.com/CipherSecurityLab/CipherMQ).