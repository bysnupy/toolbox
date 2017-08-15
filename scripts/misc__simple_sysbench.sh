#!/bin/sh

# sysbench package required
# 
# usage: shell [cpu|mem|io]
#        non-option executes all tests(cpu,mem,io)
# 
##################################################################

# test time (seconds)
sample_num=10

# cpu test
function cpu(){
  sysbench --threads=8 --time=$sample_num cpu run  | awk -F: '/total number of events:/{print $NF}' | sed -e 's/[[:space:]]//g'
}

# memory test
function memory(){
  sysbench --time=$sample_num memory run  | awk -F: '/total number of events:/{print $NF}' | sed -e 's/[[:space:]]//g'
}

# file io test random write -> random read
function fileio(){
  sysbench --time=$sample_num --file-test-mode=rndwr fileio prepare &> /dev/null
  sleep 1
  sysbench --time=$sample_num --file-test-mode=rndwr fileio run  | awk -F: '/total number of events:/{print $NF}' | sed -e 's/[[:space:]]//g' && echo -n ","
  sysbench --time=$sample_num --file-test-mode=rndwr fileio cleanup &> /dev/null
  sleep 1
  sysbench --time=$sample_num --file-test-mode=rndrd fileio prepare &> /dev/null
  sleep 1
  sysbench --time=$sample_num --file-test-mode=rndrd fileio run  | awk -F: '/total number of events:/{print $NF}' | sed -e 's/[[:space:]]//g'
  sysbench --time=$sample_num --file-test-mode=rndrd fileio cleanup &> /dev/null
}

# cpu test wrapper
function cpu_test(){
  echo "cpu"

  for cnt in $(seq $sample_num)
  do
    echo ${cnt},$(cpu)
    sleep 1
  done
}

# memory test wrapper
function mem_test(){
  echo "memory"

  for cnt in $(seq $sample_num)
  do
    echo ${cnt},$(memory)
    sleep 1
  done
}

# io test wrapper
function io_test(){
  echo "fileio"

  for cnt in $(seq $sample_num)
  do
    echo ${cnt},$(fileio)
  done
}

# main processes

case "$1" in
  cpu) cpu_test ;;
  mem) mem_test ;;
  io)  io_test ;;
  *)   cpu_test
       mem_test
       io_test ;;
esac

exit 0
