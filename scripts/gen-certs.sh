#!/bin/bash

# Directory for certificates
CERT_DIR="../certs"
mkdir -p $CERT_DIR

# 1. Generate Root CA
echo "Generating Root CA..."
openssl genrsa -out $CERT_DIR/ca.key 4096
openssl req -new -x509 -days 3650 -key $CERT_DIR/ca.key -out $CERT_DIR/ca.crt -subj "/C=VN/ST=HCM/L=HCM/O=VHVPlatform/OU=Infrastructure/CN=VHV Root CA"

# Function to generate service certs
generate_cert() {
    SERVICE=$1
    echo "Generating cert for $SERVICE..."
    
    # Generate private key
    openssl genrsa -out $CERT_DIR/$SERVICE.key 2048
    
    # Generate CSR
    openssl req -new -key $CERT_DIR/$SERVICE.key -out $CERT_DIR/$SERVICE.csr -subj "/C=VN/ST=HCM/L=HCM/O=VHVPlatform/OU=Backend/CN=$SERVICE"
    
    # Generate Config for SAN (Subject Alternative Names)
    cat > $CERT_DIR/$SERVICE.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $SERVICE
DNS.2 = localhost
DNS.3 = 127.0.0.1
IP.1 = 127.0.0.1
EOF

    # Sign the certificate
    openssl x509 -req -in $CERT_DIR/$SERVICE.csr -CA $CERT_DIR/ca.crt -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CERT_DIR/$SERVICE.crt -days 365 -sha256 -extfile $CERT_DIR/$SERVICE.ext
    
    # Cleanup
    rm $CERT_DIR/$SERVICE.csr $CERT_DIR/$SERVICE.ext
}

# 2. Generate Certs for Services
generate_cert "go-api-gateway"
generate_cert "go-user-service"
generate_cert "go-tenant-service"
generate_cert "go-auth-service"
generate_cert "go-system-config-service"

echo "Certificates generated in $CERT_DIR"
