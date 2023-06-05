#!/usr/bin/env bash

FORCE_ROOT_CA_GENERATION=false

if [[ $FORCE_ROOT_CA_GENERATION == true || ! -f "ca_cert/rootCA.crt" ]]; then
  rm -rf ca_cert
  mkdir -p ca_cert

  # Remove trusted certificate if exists
  security delete-certificate -c disco.toma2.ca -t "/Library/Keychains/System.keychain"

  # Create root CA & Private key
  openssl req -x509 \
              -sha256 -days 356 \
              -nodes \
              -newkey rsa:2048 \
              -subj "/CN=disco.toma2.ca/C=IN/ST=WB/L=Kolkata/O=Disco Toma2/OU=DT2 Certificate Authority" \
              -keyout ca_cert/rootCA.key -out ca_cert/rootCA.crt

  # Add trusted certificate to mac keychain
  sudo security add-trusted-cert -d -k "/Library/Keychains/System.keychain" ca_cert/rootCA.crt
else
  echo -e "\033[0;31mSkipping root CA generation\033[0m"
fi
