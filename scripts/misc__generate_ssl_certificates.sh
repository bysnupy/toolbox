#!/bin/bash

#
# This script generates the CA and certificates signed the CA.
#
# Argument(optional): common name, e.g) www.example.com 


# variables
_root_path=./
_prefix=custom-

test -n "$1" && _prefix=${1}-

_ca_key=${_root_path}${_prefix}ca-key.pem
_ca_cert=${_root_path}${_prefix}ca-cert.pem

_signed_cert=${_root_path}${_prefix}cert.pem
_signed_cert_key=${_root_path}${_prefix}key.pem
_signed_cert_csr=${_root_path}${_prefix}cert.csr

# functions
function mk_ca() {
  openssl genrsa -out ${_ca_key} 2048
  openssl req -new -x509 -days 3650 -key ${_ca_key} -out ${_ca_cert} -subj "/CN=${_prefix} CA"
}

function mk_signed_cert() {
  openssl genrsa -out ${_signed_cert_key} 2048
  openssl req -new -key ${_signed_cert_key} -out ${_signed_cert_csr} -subj "/CN=${_prefix}"
  openssl x509 -req -days 3650 -CA ${_ca_cert} -CAkey ${_ca_key} -CAcreateserial -in ${_signed_cert_csr} -out ${_signed_cert}
}

# main

mk_ca
mk_signed_cert

exit $?
