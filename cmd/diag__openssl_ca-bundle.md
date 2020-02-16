# openssl CLI
```
$ openssl crl2pkcs7 -nocrl -certfile ca-bundle.crt | openssl pkcs7 -print_certs -text -noout
```
