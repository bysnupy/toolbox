# python one-liner cmd to convert from yaml to json

```consonle
python -c 'import sys,yaml,json; tmp_json=json.loads(sys.stdin.read()); print yaml.safe_dump(tmp_json)'
```
