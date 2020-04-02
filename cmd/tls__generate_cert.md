# Generat TLS certificates

```cmd
openssl genrsa -out tls.key 2048

openssl req -new -subj "/C=JP/ST=Tokyo/L=Shibuya/O=Test/CN=test.example.com" -key tls.key -out tls.csr

openssl x509 -req -in tls.csr -passin file:passphrase.txt -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out tls.crt -days 3650 -sha256 -extfile subject-alternative-names.txt
```
