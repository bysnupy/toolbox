# tshark usage

## How to filter the packet using CloudFront request ID
```console
$ TZ=UTC tshark -n -t ud  -r tcpdump.pcap \
  -Y 'http.request and http contains "x-amz-cf-id: XXXXX"' -V | \
  grep "Stream index:"
      [Stream index: AAAA]
      
$ TZ=UTC tshark -n -t ud  -r tcpdump.pcap \
  -Y "tcp.stream eq AAAA"
```

## How to filter the specific time range
```console
$ TZ=UTC tshark -n -t ud -r tcpdump.pcap \
  -Y '(frame.time >= "YYYY-MM-DD HH:MM:SS.SSSSSS")  &&  (frame.time <= "YYYY-MM-DD HH:MM:SS.SSSSSS")'
```
