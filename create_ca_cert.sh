#!/usr/bin/env bash

set -euo pipefail

echo "Certificate details"

read -p "Domain name (example.com): " DOMAIN
read -p "Organization: " ORG
read -p "Country (2 letters): " COUNTRY
read -p "State: " STATE
read -p "City: " CITY


VALIDITY_DAYS=1825

BASE_DIR="certs"

# CA files
CA_DIR="$BASE_DIR/ca"
CA_KEY="$CA_DIR/ca.key"
CA_CERT="$CA_DIR/ca.crt"

# Domain files
DOMAIN_DIR="$BASE_DIR/$DOMAIN"

SERVER_KEY="$DOMAIN_DIR/$DOMAIN.key"
SERVER_CSR="$DOMAIN_DIR/$DOMAIN.csr"
SERVER_CERT="$DOMAIN_DIR/$DOMAIN.crt"


mkdir -p "$CA_DIR"
mkdir -p "$DOMAIN_DIR"


echo "[1/5] Creating Root CA private key..."

openssl genrsa \
    -out "$CA_KEY" \
    4096


echo "[2/5] Creating Root CA certificate..."

openssl req \
    -x509 \
    -new \
    -nodes \
    -key "$CA_KEY" \
    -sha256 \
    -days "$VALIDITY_DAYS" \
    -out "$CA_CERT" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/CN=$ORG Root CA"



echo "[3/5] Creating server private key..."

openssl genrsa \
    -out "$SERVER_KEY" \
    2048



echo "[4/5] Creating CSR..."

openssl req \
    -new \
    -key "$SERVER_KEY" \
    -out "$SERVER_CSR" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/CN=$DOMAIN"



echo "[5/5] Signing server certificate with Root CA..."

openssl x509 \
    -req \
    -in "$SERVER_CSR" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$SERVER_CERT" \
    -days "$VALIDITY_DAYS" \
    -sha256 \
    -extfile <(cat <<EOF
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:$DOMAIN,IP:127.0.0.1
EOF
)


echo
echo "================================="
echo "Certificate created successfully"
echo "================================="
echo


echo "Generated files:"
find "$BASE_DIR" -type f


echo
echo "Root CA certificate:"
openssl x509 \
    -in "$CA_CERT" \
    -noout \
    -subject \
    -issuer


echo
echo "Server certificate:"
openssl x509 \
    -in "$SERVER_CERT" \
    -noout \
    -subject \
    -issuer
