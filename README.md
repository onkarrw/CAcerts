# CA-The-Signing-Authority-
Understanding certificates, CAs, digital signatures, and the trust chain behind HTTPS.


# TLS Certificates Explained From Scratch

A detailed explanation of how HTTPS certificates, public/private keys, Certificate Authorities (CAs), signing, and verification work.

---

# 1. The Problem TLS Certificates Solve

When you open:

```
https://bank.com
```

your browser needs to answer:

1. Am I really communicating with `bank.com`?
2. Is the public key I received actually owned by `bank.com`?

Without certificates, anyone could create:

```
Website:
bank.com

Public Key:
hacker_public_key
```

and pretend to be the real website.

TLS certificates solve this problem by using **Certificate Authorities (CAs)**.

---

# 2. Public Key Cryptography Basics

TLS uses asymmetric cryptography.

A key pair contains two mathematically related keys:

```
             Key Pair

      +----------------+
      |                |
      v                v

 Private Key       Public Key
    🔒                🔓
```

---

## Private Key

The private key:

- stays secret
- is never shared
- creates digital signatures
- proves ownership

Example:

```
server_private.key
```

---

## Public Key

The public key:

- can be shared with everyone
- verifies signatures

Example:

```
server_public.key
```

Important:

```
Public Key  ---> cannot generate ---> Private Key
```

Knowing someone's public key does not allow you to recreate their private key.

---

# 3. What Is a Certificate?

A certificate is NOT a key.

A certificate is a digital document containing:

```
Certificate

|
+-- Owner information
|
+-- Public key
|
+-- Issuer (who signed it)
|
+-- Expiry date
|
+-- Digital Signature
```

Example:

```
Certificate:

Subject:
    bank.com

Public Key:
    RSA Public Key ABC123

Issuer:
    Example CA

Valid:
    2026 - 2027

Signature:
    XYZ987
```

A certificate says:

> "This public key belongs to this identity, and a trusted authority confirms it."

---

# 4. The Two Key Pairs in TLS

TLS uses two separate key pairs.

Many people confuse them.

---

# Server Key Pair

Owned by the website.

```
bank_private.key 🔒
        |
        |
        v
bank_public.key  🔓
```

Purpose:

- prove the server owns the certificate
- sign TLS handshake messages

---

# Certificate Authority Key Pair

Owned by the CA.

```
CA_private.key 🔒
        |
        |
        v
CA_public.key 🔓
```

Purpose:

- sign certificates
- allow browsers to verify certificates

---

# 5. Creating a Certificate

## Step 1: Server Creates Keys

The server generates:

```
bank_private.key
bank_public.key
```

The private key stays on the server.

The public key can be shared.

---

# 6. Creating a CSR

The server creates a Certificate Signing Request:

```
bank.csr
```

The CSR contains:

```
Certificate Request:

Organization:
    ABC Bank

Country:
    India

Domain:
    bank.com

Public Key:
    bank_public.key
```

Important:

The CSR contains:

```
YES:
bank_public.key

NO:
bank_private.key
```

The private key never leaves the server.

---

# 7. Sending CSR to Certificate Authority

The server sends:

```
bank.csr
```

to the CA.

The request means:

> "Please create a certificate saying this public key belongs to bank.com."

---

# 8. How CA Creates the Certificate

The CA has:

```
CA_private.key 🔒
CA_public.key  🔓
```

The CA creates certificate data:

```
Certificate Data:

Subject:
    bank.com

Public Key:
    bank_public.key

Issuer:
    Example CA

Expiry:
    2027
```

Important:

The CA does NOT use the bank public key for signing.

The bank public key is only included inside the certificate.

---

# 9. Certificate Signing Process

The CA signs the certificate data.

First:

```
Certificate Data

(bank.com
 bank_public.key
 expiry
 issuer)
```

is hashed:

```
Certificate Data
        |
        |
        v

     SHA-256

        |
        |
        v

     Hash Value
```

Then:

```
Hash Value
     |
     |
     v

CA_private.key

     |
     |
     v

Digital Signature
```

The final certificate becomes:

```
bank.crt
```

Containing:

```
Certificate:

Subject:
    bank.com

Public Key:
    bank_public.key

Issuer:
    Example CA

Signature:
    CA Signature
```

---

# 10. What Does "Signed Certificate" Mean?

A signed certificate means:

```
Certificate Information
+
Digital Signature
=
Signed Certificate
```

The signature proves:

1. The CA created this certificate
2. The certificate was not modified

---

# 11. What Happens to the CA Certificate?

The CA also has a certificate:

```
CA Certificate

Subject:
    Example CA

Public Key:
    CA_public.key

Signature:
    CA signature
```

Browsers and operating systems already trust many CA certificates.

Example:

```
Browser Trust Store

|
+-- CA Certificate 1
|
+-- CA Certificate 2
|
+-- CA Certificate 3
```

The browser already knows trusted CA public keys.

The browser does NOT contact the CA when verifying a certificate.

---

# 12. Browser Receives Server Certificate

Browser connects:

```
Browser
    |
    |
    v

bank.com
```

Server sends:

```
bank.crt
```

Browser sees:

```
Subject:
    bank.com

Public Key:
    bank_public.key

Issuer:
    Example CA

Signature:
    CA Signature
```

---

# 13. How Browser Verifies the Certificate

The browser does two things.

---

## Step 1: Hash Certificate Data

Browser takes:

```
bank.com
bank_public.key
expiry
issuer
```

and calculates:

```
SHA-256
```

Result:

```
Hash A
```

---

## Step 2: Verify CA Signature

Browser takes:

```
CA Signature
```

and uses:

```
CA_public.key
```

to recover:

```
Hash B
```

---

## Step 3: Compare

Browser checks:

```
Hash A == Hash B
```

If equal:

```
✓ CA signed this certificate
✓ Certificate was not changed
```

---

# 14. Why Can't a Hacker Copy the Certificate?

Suppose attacker copies:

```
bank.crt
```

They get:

```
bank_public.key
```

But they do not have:

```
bank_private.key
```

The certificate alone is useless.

The attacker cannot prove ownership.

---

# 15. Proving Server Owns Private Key

After certificate verification, the browser asks:

> "Prove you have the matching private key."

The browser sends random data:

```
Challenge:

83947291
```

The real server does:

```
Random Data

      |
      |
      v

bank_private.key

      |
      |
      v

Signature
```

Server sends:

```
Signature
```

Browser checks:

```
Signature

      |
      |
      v

bank_public.key
```

If valid:

```
✓ Server owns the private key
```

---

# 16. Complete TLS Flow

```
                    Certificate Authority


                    CA_private.key
                          |
                          |
                          | signs
                          |
                          v


                  Bank Certificate

                  +----------------+
                  | bank.com       |
                  |                |
                  | bank_public.key|
                  |                |
                  | CA Signature   |
                  +----------------+



Bank Server:

        bank_private.key
              |
              |
              | proves ownership
              |
              v

        bank_public.key



Browser:

        CA_public.key

        verifies CA signature
```

---

# 17. Self-Signed Certificate vs CA Certificate

## Self-Signed Certificate

Example:

```
server_private.key
        |
        |
        v

server.crt
```

The certificate signs itself.

Example:

```
Issuer:
server.com

Subject:
server.com
```

Used for:

- testing
- development
- internal systems

---

## CA-Signed Certificate

Flow:

```
Server

server_private.key
        |
        |
        v

server_public.key


        |
        |
        v


CSR


        |
        |
        v


Certificate Authority


        |
        |
        v


server.crt
```

Used for:

- public websites
- production HTTPS

---

# 18. Root CA

A Root CA is a trusted CA.

Example:

```
Root CA

CA_private.key
        |
        |
        v

CA Certificate
```

Browsers already trust root CA certificates.

A Root CA can issue:

```
Root CA

 |
 +---- Website certificate
 |
 +---- Client certificate
 |
 +---- Device certificate
```

---

# 19. Final Summary

## Server Keys

```
server_private.key
server_public.key
```

Purpose:

```
Prove server ownership
```

---

## CA Keys

```
CA_private.key
CA_public.key
```

Purpose:

```
Sign certificates
```

---

## Certificate Contains

```
Identity
+
Public Key
+
CA Signature
```

---

# Complete Trust Chain

```
1. Server creates private/public key pair

2. Server sends public key in CSR

3. CA verifies identity

4. CA signs certificate using CA private key

5. Browser verifies CA signature using CA public key

6. Server proves ownership using private key

7. Secure TLS connection starts
```

---

# Core Idea

A Certificate Authority proves:

> "This public key belongs to this identity."

The server proves:

> "I actually own the private key matching that public key."

Together, they create trust in HTTPS.
