# tcpdump
* option 1
```
tcpdump -ni eth0 -vvvnn -l -A "udp port 53 and dst host 10.0.1.10 or dst host 10.0.1.20"
```
