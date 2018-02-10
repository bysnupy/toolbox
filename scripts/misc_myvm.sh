#!/bin/bash

#######################################################
#
# Add the listname and list pair to "myvm_list".
#
#######################################################
#
#declare -A myvm_list
#
#myvm_list=(
# [GROUP_NAME]="
#   GUEST_VM1,
#   GUEST_VM2,
#   GUEST_VM3"
#)


# variables
myvm_home=/usr/local/bin
vm_list_file=${myvm_home}/myvm.list
usage_txt="Usage: ${0##*/} [list|start|stop] <vm group name>"


# functions
function list_vm {
  cnt=0
  for list_name in "${!myvm_list[@]}"; do
    echo -e "No.\tvm group name"
    python -c "print('-'*60)"
    echo -e "$(( cnt=${cnt} + 1)).\t${list_name}"
  done
}

function start_vm {
  cnt=0
  for vm in $(echo ${myvm_list[$1]} | tr ',' ' '); do
    echo -e "$(( cnt = ${cnt} + 1 )).\tvirsh start ${vm}"
    virsh start ${vm}
  done
}

function stop_vm {
  cnt=0
  for vm in $(echo ${myvm_list[$1]} | tr ',' ' '); do
    echo -e "$(( cnt = ${cnt} + 1 )).\tvirsh shutdown ${vm}"
    virsh shutdown ${vm}
  done
}

function show_ip {
  cnt=0
  for vm in $(virsh list --state-running --name); do
    echo -e " $(( cnt = ${cnt} + 1 )).\tVM name:\t${vm}"
    virsh domifaddr ${vm} | sed -e '1,2d'
  done
}

# main
test -e ${vm_list_file} && source ${vm_list_file} || exit 1

case $1 in
  list) list_vm
  ;;
  start) start_vm $2
  ;;
  stop) stop_vm $2  ;;
  ip) show_ip
  ;;
  *) echo "${usage_txt}"
  ;;
esac

exit $?


