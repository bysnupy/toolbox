# How to create a cert with SAN

## with CA:FALSE
```console
DOMAIN=foo.example.com
openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout ssl.key \
    -new \
    -out ssl.crt \
    -subj /CN=$DOMAIN \
    -reqexts SAN \
    -extensions SAN \
    -config <(cat /etc/pki/tls/openssl.cnf; printf "[SAN]\nsubjectAltName=DNS:$DOMAIN\n") \
    -sha256 \
    -days 3650
```
## with CA:TRUE
```console
DOMAIN=foo.example.com
openssl req \
    -newkey rsa:2048 -x509 -nodes -keyout ssl.key \
    -new -out ssl.crt -subj /CN=$DOMAIN -reqexts SAN -extensions SAN \
    -config <(cat /etc/pki/tls/openssl.cnf; printf "[SAN]\nsubjectAltName=DNS:$DOMAIN\n\nbasicConstraints=CA:TRUE\n") \
    -sha256 -days 3650
```
