# fio cmd for checking whether the storage is fast enough for etcd

```command
# fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
```
