#!/bin/bash

#+ Usage: 
#- debug.sh [--debug]

debug_opt=""

[ "$1" == "--debug" ] && debug_opt=$1

# initiate as removed temporary files
rm -rf /var/lib/cloud/* 

echo "INIT Local phase"
cloud-init $debug_opt init --local

echo "INIT phase"
cloud-init $debug_opt init

echo "CONFIG phase"
cloud-init $debug_opt modules --mode config

echo "FINAL phase"
cloud-init $debug_opt modules --mode final

exit 0
