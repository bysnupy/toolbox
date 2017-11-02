#! /usr/bin/env python

"""
 Author:  Daein
 Purpose: Current VM status which should be up or down save to file and load from it and then start.
 Usage:   arg1: <pickle mode, empty is dump mode>    [ dump (default) | load ]
          arg2: <action mode, empty is just listing> [ start | stop ]
          e.g. script arg1 arg2

"""

from __future__   import print_function
from ovirtsdk.api import API
from ovirtsdk.xml import params
from time         import sleep
import pickle,sys

# variables for authentication
webconsole_url  = 'https://HOSTNAME/ovirt-engine/api'
user_and_domain = 'USERNAME@DOMAIN'
user_password   = 'PASSWORD'

api = API(url=webconsole_url, username=user_and_domain, password=user_password, insecure=True)

# variables for the tasks
up_vm_list = []
up_vm_pickle_file = 'up_vm.dump'
pickle_mode = 'dump'
restart_vm_list = []
action = ''

# arguments checking
if len(sys.argv) == 2 and sys.argv[1] == 'load':
  pickle_mode = 'load'
elif len(sys.argv) == 3 and sys.argv[1] == 'load' and sys.argv[2] in ['start', 'stop']:
  pickle_mode = 'load'
  action = sys.argv[2]

# generage vm list
for vm in api.vms.list():
  if vm.status.state == "up":
    up_vm_list.append(vm.name)

try:
  # save to the external file as pickle format
  if pickle_mode == 'dump':
    with open(up_vm_pickle_file, 'wb') as dump_file:
      if len(up_vm_list) > 0:
        pickle.dump(up_vm_list, dump_file)
        print ("Dump the vm list to %s ..." % up_vm_pickle_file)
  # load from the external file and allocate to the list variable
  elif pickle_mode == 'load':
    with open(up_vm_pickle_file, 'rb') as dump_file:
      restart_vm_list = pickle.load(dump_file)
except:
  print ("Unexpected error: ", sys.exc_info()[0])
  raise

# if pickle mode is load, the below lines process
if pickle_mode == 'load':
  cnt = 0
  print ("Total VM counts: %s" % len(restart_vm_list))

  # loop of VMs list
  for vm in restart_vm_list:
    cnt += 1
    # if the action mode is start
    if action == 'start':
      api.vms.get(vm).start()
      print ("%s Starting %s VM" % (str(cnt), vm))
      while api.vms.get(vm).status.state != 'up':
        sleep(1)
    # if the action mode is stop
    elif action == 'stop':
      api.vms.get(vm).stop()
      print ("%s Stopping %s VM" % (str(cnt), vm))
      while api.vms.get(vm).status.state != 'down':
        sleep(1)
    # just list the vm names
    else:
      print ("%s\t%s" % (str(cnt), vm))
