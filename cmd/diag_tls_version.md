# How to check the current availble TLS version ?

## nmap
```console
$ nmap --script ssl-enum-ciphers -p PORT HOSTNAME
|   TLSv1.0: 
:
|   TLSv1.2: 
```

## curl
```
curl -k --tlsv1.0 https://HOSTNAME:PORT
:
curl -k --tlsv1.2 https://HOSTNAME:PORT
```
