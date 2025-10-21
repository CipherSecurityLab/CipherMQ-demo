# CipherMQ Demo

## Overview

The `ciphermq-demo` repository provides two demo versions of CipherMQ, a secure, high-performance message broker designed for encrypted message transmission. CipherMQ uses a push-based architecture to facilitate communication between senders and receivers, ensuring **zero message loss** and **exactly-once delivery** through robust acknowledgment mechanisms. Messages are temporarily held in memory and routed via exchanges and queues.

CipherMQ employs **hybrid encryption** (X25519 for key exchange and AES-GCM-256 for message encryption) to ensure message confidentiality and authenticity. **Mutual TLS (mTLS)** secures client-server communication, protecting against man-in-the-middle attacks. Metadata and public keys are stored in a **PostgreSQL database**, with public keys encrypted using **ChaCha20-Poly1305** for secure storage. Receivers register their public keys with the server, which are securely distributed to senders for encryption.

This repository contains two demo setups:

1. **CipherMQ-Demo_SingleClient_windows-x86_64**: A simplified setup with one sender and one receiver, ideal for testing basic secure message passing.
2. **CipherMQ-Demo_MultiClient_windows-x86_64**: An advanced setup with one sender and two independent receivers, demonstrating simultaneous message relaying to multiple clients.

Each demo includes a pre-configured server, client scripts, and a batch launcher to automate setup and execution. The demos are tailored for Windows x86_64 systems and require Python 3.8+, PostgreSQL, and OpenSSL.

**Note**: A Linux version of the demos is currently in development and will be uploaded soon.



## Key Exchange Animation

To understand the key exchange process in CipherMQ, check out the interactive animation below. It visualizes how the sender, receiver, server controller, key manager, and database interact during the secure key exchange.



<p align="center">
<img src="./.assets/full-key-exchange.gif">
</p>



**Note**: For the full interactive experience, visit the [CipherMQ Key Exchange Animation](https://ciphermq.com/docs/index.php/ciphermq-full-key-exchange-process/) on our website.




## Getting Started

Each demo directory contains its own `README.md` with detailed setup instructions, prerequisites, and troubleshooting guides specific to that version. To get started:

- Navigate to the `CipherMQ-Demo_SingleClient_windows-x86_64` directory for the single-client demo.
- Navigate to the `CipherMQ-Demo_MultiClient_windows-x86_64` directory for the multi-client demo.

Refer to the respective `README.md` files within these directories for step-by-step instructions on setting up and running the demos.

## Learn More

For a comprehensive understanding of CipherMQ's architecture and features, visit the [main project repository](https://github.com/CipherSecurityLab/CipherMQ).