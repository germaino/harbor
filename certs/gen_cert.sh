#!/bin/bash -e

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR="$(realpath $ROOTDIR)"

HOST="${1:-localhost}"
IP="${2:-127.0.0.1}"
CACERT="${3:-$ROOTDIR/ca.crt}"

echo "[INFO] Make the CSR generation happy"
mkdir -p $HOME/.rnd

if [ "$CACERT" = "none" ] ; then
  echo "[INFO] Generate a CA certificate private key"
  openssl genrsa -out $ROOTDIR/ca.key 4096

  echo "[INFO] Generate the CA certificate"
  openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=FR/ST=Isere/L=Grenoble/O=Schneider Electric/OU=ETP/CN=Edge Harbor root CA" \
  -key $ROOTDIR/ca.key \
  -out $ROOTDIR/ca.crt \
  -config <(cat /etc/ssl/openssl.cnf | sed "s/RANDFILE\s*=\s*\$ENV::HOME\/\.rnd/#/")

  echo "[INFO] trusting the Certificate for host"
  sudo cp $ROOTDIR/ca.crt /usr/local/share/ca-certificates/harbor_ca.crt
  sudo update-ca-certificates -f

else

  echo "[INFO] Using existing $ROOTDIR/ca.crt"

  if [ ! -f "$ROOTDIR/ca.key" ] ; then
    echo "[ERROR] Cannot find $ROOTDIR/ca.key"
    exit 1
  fi

fi

echo "[INFO] Generate a private key for the server"
openssl genrsa -out $ROOTDIR/harbor.key 4096

echo "[INFO] Generate a Certificate Signing Request"
openssl req -sha512 -new \
    -subj "/C=FR/ST=ISere/L=Grenoble/O=Schneider Electric/OU=ETP/CN=harbor" \
    -key $ROOTDIR/harbor.key \
    -out $ROOTDIR/harbor.csr \
    -config <(cat /etc/ssl/openssl.cnf | sed "s/RANDFILE\s*=\s*\$ENV::HOME\/\.rnd/#/")

echo "[INFO] Generate an x509 v3 extension file"
cat > $ROOTDIR/v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1=$IP
DNS.1=$HOST
EOF

echo "[INFO] Generate a certificate for Harbor host"
openssl x509 -req -sha512 -days 3650 \
    -extfile $ROOTDIR/v3.ext \
    -CA $ROOTDIR/ca.crt -CAkey $ROOTDIR/ca.key -CAcreateserial \
    -in $ROOTDIR/harbor.csr \
    -out $ROOTDIR/harbor.crt

echo "[INFO] Convert .crt to .cert for docker"
openssl x509 -inform PEM -in $ROOTDIR/harbor.crt -out $ROOTDIR/harbor.cert

echo "[INFO] Copy the server certificate for ngnix"
sudo mkdir -p /data/certs
sudo cp $ROOTDIR/harbor.crt /data/certs
sudo cp $ROOTDIR/harbor.key /data/certs
sudo cp $ROOTDIR/ca.crt /data/certs

if [ -d "/data/secret/cert" ] ; then
  sudo cp $ROOTDIR/harbor.crt /data/secret/cert/server.crt
  sudo cp $ROOTDIR/harbor.key /data/secret/cert/server.key
  sudo cp $ROOTDIR/ca.crt /data/secret/cert/ca.crt
fi
