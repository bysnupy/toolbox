#!/usr/bin/env python

from __future__ import print_function
from subprocess import Popen,PIPE,STDOUT
import sys,os,time,re

"""
Purpose: counting a specific tcp connection.
Usage: arg1 - ip:port
Return value: H24:mm:ss connection counts(num)
"""

# variables
netstat_cmd="/usr/sbin/ss"
if not os.path.isfile(netstat_cmd):
  netstat_cmd="/usr/bin/env netstat"

command_tuple=(netstat_cmd,'-tna')

if not sys.argv[1]:
  print("error: required argument with formatting 'ip:port'", file=sys.stderr)
  sys.exit(1)
target=sys.argv[1]

result_signal="0"
time_fmt='%H:%M:%S'
interval=1
count=0

# main
print("time\tcounts")
try:
  while result_signal:
    count=0
    time.sleep(int(interval))
    result = Popen(command_tuple, stderr=STDOUT, stdout=PIPE)
    result_output = result.stdout.readlines()
    result_signal = [ result.communicate()[0], result.returncode]
    for line in result_output:
      if re.search(r'{target}'.format(target=target),line):
        count+=1

    print("{time}\t{count}".format(time=time.strftime(time_fmt), count=count))
except KeyboardInterrupt:
  print("Done...")

exit(result_signal[1])
