#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
ROOTDIR="$(realpath $ROOTDIR)"


#if [[ `id -u` != 0 ]]; then
#    #https://unix.stackexchange.com/a/23962
#    echo "Must be root to run script"
#    exit
#fi

USERNAME=$1
HOST=${2:-localhost}

if [ -z "$USERNAME" ] ; then
  echo "Missing user name"
  exit 1
fi

CA_ROOT="$ROOTDIR"
CERT_DUR=365
KEY_LEN=4096

mkdir -p $HOME/.rnd
mkdir -p $CA_ROOT/certs/users

echo "Generate a private key for the server"
openssl genrsa -out $CA_ROOT/certs/users/$USERNAME.key $KEY_LEN


echo "Generate a Certificate Signing Request"
openssl req -sha512 -new \
    -subj "/C=FR/ST=Grenoble/L=Grenbole/O=Schneider Electric/OU=ETP/CN=$USERNAME" \
    -key $CA_ROOT/certs/users/$USERNAME.key \
    -out $CA_ROOT/certs/users/$USERNAME.csr \
    -config <(cat /etc/ssl/openssl.cnf | sed "s/RANDFILE\s*=\s*\$ENV::HOME\/\.rnd/#/")

echo "Generate a certificate for user $USERNAME"
openssl x509 -req -sha512 -days $CERT_DUR \
    -CA $CA_ROOT/certs/ca.crt \
    -CAkey $CA_ROOT/certs/ca.key \
    -CAcreateserial \
    -in $CA_ROOT/certs/users/$USERNAME.csr \
    -out $CA_ROOT/certs/users/$USERNAME.crt

echo "Convert .crt to .cert for docker"
openssl x509 -inform PEM -in $CA_ROOT/certs/users/$USERNAME.crt -out $CA_ROOT/certs/users/$USERNAME.cert

echo "Generate certificate fingerprint for user $USERNAME"
openssl x509 -noout -fingerprint -sha1 -inform pem -in $CA_ROOT/certs/users/$USERNAME.crt | cut -d '=' -f 2 | sed -e 's/://g' > $CA_ROOT/certs/users/$USERNAME.cert.fingerprint

echo "Copy the server certificate, key and CA files into the Docker certificates folder"
sudo mkdir -p /etc/docker/certs.d/$HOST
sudo cp $CA_ROOT/certs/users/$USERNAME.cert /etc/docker/certs.d/$HOST
sudo cp $CA_ROOT/certs/users/$USERNAME.key /etc/docker/certs.d/$HOST
sudo cp $CA_ROOT/certs/ca.crt /etc/docker/certs.d/$HOST
