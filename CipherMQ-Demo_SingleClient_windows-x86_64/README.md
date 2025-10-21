# CipherMQ Demo Setup Guide


## About the Demo

This demo version of CipherMQ provides a simplified setup to experience secure message passing using Mutual TLS (mTLS) and hybrid encryption. It includes a pre-configured server, sender, and receiver, with a batch script (Launcher-CipherMQ.bat) to automate setup and execution. This demo is ideal for users who want to quickly test CipherMQ's core functionality without the complexity of the full project setup.


---

## System Overview

- **Server**: Manages message queues and relays encrypted messages to subscribed clients
- **Sender**: Encrypts and sends messages to the server for distribution
- **Receiver**: Receives and decrypts messages from the server.

This guide walks you through running the demo using the provided launcher script. For a comprehensive understanding of CipherMQ, refer to the [main project](https://github.com/CipherSecurityLab/CipherMQ).

---
## Architecture Overview

### Security Layers

1. **Transport Security (mTLS)**:
   - All connections use Mutual TLS authentication
   - Both client and server verify each other's certificates
   - Protects against man-in-the-middle attacks

2. **Message Encryption (Hybrid Cryptography)**:
   - X25519 key exchange for secure key agreement
   - ChaCha20-Poly1305 for fast authenticated encryption
   - End-to-end encryption ensures server cannot read messages

3. **Key Distribution**:
   - Receiver client has its own key pair
   - Public key are exchanged securely
   - Private key never leave the client machine


---

## Prerequisites
To run the CipherMQ demo, ensure the following are installed:
- **Python 3.8 or Higher**
  - Verify: `python --version`
  - Install from [python.org](https://www.python.org/downloads/) if needed.
- **Python Libraries**
  - Install: `pip install cryptography PyNaCl`
- **PostgreSQL 10 or Higher**
  - Install from [postgresql.org](https://www.postgresql.org/download/).
  - Create the `ciphermq` database (see Database Setup).
- **OpenSSL**
  - Required for generating encryption keys.
  - Verify: `openssl version`
  - Install from [openssl.org](https://www.openssl.org/) or your package manager.
### Database Setup

1. Start PostgreSQL:
   ```bash
   psql -U postgres
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
   python -c "import cryptography; import nacl; print('Python libraries OK')"
   ```

2. **Verify PostgreSQL:**
   ```bash
   pg_isready -h localhost -p 5432
   ```

3. **Verify database :**
   
   ```bash
   psql -U postgres -c "CREATE DATABASE ciphermq;"
   ```

---

## Clone the Repository

Clone the project repository from GitHub:
```bash
git clone https://github.com/CipherSecurityLab/CipherMQ-demo
cd CipherMQ-Demo_SingleClient_windows-x86_64
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
cert_path = "/certs/server.crt"
key_path = "/certs/server.key"
ca_cert_path = "/certs/ca.crt"

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


> **Note**: Ensure the `[database]` section matches the PostgreSQL database setup (mq_user, mq_pass, ciphermq). Update these values if you used different credentials or database name during the Database Setup step.

---
## Setup Steps

### Quick Start with Launcher

Run the launcher script from the project root directory:
```bash
.\Launcher-CipherMQ.bat
```

Then follow these steps in order:

### Step 1: Generate TLS Certificates

1. In the launcher menu, select option `1`: **Generate Certificates**
2. The system will generate certificates for server and clients.

**What happens**: Creates TLS certificates for mutual authentication between server and all clients.



### Step 2: Generate Encryption Keys

1. Select option `2`: **Generate Keys**.
2. Wait for the encryption keys to be generated.

**What happens**: Create X25519 public/private key pairs for end-to-end encryption.



### Step 3: Copy Files to Destinations

1. Select option `3`: **Copy Files**.

2. This operation:
   - Copies TLS certificates to the appropriate directories.
   - Distributes encryption keys to the required paths.
   

**What happens**: Distributes all certificates and keys to their proper locations.



### Step 4: Start the Server

1. Select option `4`: **Run Server**.
2. A new terminal window will open running the server
3. **Wait 5-10 seconds** for the server to fully initialize before starting clients
4. You should see server logs indicating it's ready to accept connections

**What happens**: Starts the message broker that will relay messages between sender and receiver.



### Step 5: Start the Receiver

1. Select option `5`: **Run Receiver **.
   - A new terminal window will open for Receiver 
   - Receiver are now independently listening for messages

**What happens**: Receiver connect to the server with mTLS and wait for encrypted messages.



### Step 6: Start the Sender and Send Messages

1. Select option `6`: **Run Sender**.
2. A new terminal window will open for the sender
3. Messages sent via the sender will be relayed by the server to the receiver.

**What happens**: 
- Sender encrypts the message

- Sends it to the server



### Reset Progress

To reset all steps and start from scratch:
1. Select option `7`: **Reset Progress**.
2. Confirm (Y/N).
3. The launcher will close after reset
4. Run the launcher again to start fresh

> **Note**: This only resets progress indicators, not the generated files. To completely start over, you should manually delete.

---



## Important Notes & Troubleshooting



### Administrator Privileges

- **Run as Administrator**: To avoid permission errors, right-click the launcher and select "Run as administrator"
- This is especially important for certificate generation and file operations



### Step Dependencies

- **Follow the order**: Steps must be performed sequentially (1 → 2 → 3 → 4 → 5 → 6 )
- Each step depends on the previous one completing successfully
- The launcher will warn you if you skip steps, but it's best to follow the order



### Common Issues and Solutions

#### Issue: "Not running as administrator"
**Solution**: Close the launcher, right-click it, and select "Run as administrator"



#### Issue: "Certificate generation failed"

**Solution**: 
- Ensure OpenSSL is installed and in your PATH
- Check if `cert_generator.exe` exists in `cert-and-key-maker/cert/`
- Verify file permissions



#### Issue: "Key generation failed"

**Solution**:
- Ensure `key_generator.exe` exists in `cert-and-key-maker/key/`
- Check if Step 1 (Certificate generation) was completed
- Verify you have write permissions in the directory



#### Issue: "Python files not found"

**Solution**:
- Verify `Receiver.py` exists in `client/receiver_1/`
- Verify `Sender.py` exists in `client/sender_1/`
- Verify `config.json` files exist in each client directory



#### Issue: "Server won't start"

**Solution**:
- Verify PostgreSQL is running: `pg_isready -h localhost -p 5432`
- Check database credentials in `server/config.toml`
- Ensure port 5672 is not already in use
- Verify certificates were copied to `server/certs/`



#### Issue: "Client can't connect to server"

**Solution**:
- Ensure server is running (Step 4) before starting clients
- Wait 5-10 seconds after starting server for initialization
- Check that certificates were copied correctly (Step 3)
- Verify server address in client `config.json` files



#### Issue: "Receiver doesn't get messages"

**Solution**:
- Ensure both server and receiver are running
- Check that encryption keys were copied correctly to `client/receiver_1/keys/`
- Verify sender is connected and sending messages
- Check client logs for error messages

---

## Learn More
For detailed information about CipherMQ’s architecture, features, and future improvements, refer to the [main project](https://github.com/CipherSecurityLab/CipherMQ).

---
