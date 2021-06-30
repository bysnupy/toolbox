# All ascii color and not priting chacters

```console
$ sed 's/\x1b\[[0-9;]*m//g' success.log | sed 's/[^[:print:]\t]//g'
```
