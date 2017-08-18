#!/bin/bash			
			
#> filename:    rsync_wrapper.sh			
#- description: keeping the same contents with the target servers.			
#
#####################################################################################################################
			
#> variables			
#- target directory root path                              *** depend on environments ***			
srcdirroot="$HOME/source/path"			
dstdirroot="/home/destination/path"		
	
#- target server lists (name and ip mapping)               *** depend on environments ***			
declare -A tgtservers=( [hostname1]="xxx.xxx.xxx.xxx" [hostname2]="yyy.yyy.yyy.yyy" [hostname3]="zzz.zzz.zzz.zzz" )			

#- target directory lists                                  *** depend on environments ***			
declare -a tgtsuffixlists=( "css" "html" "images" "include_html" "js" )			

#- lockfile name			
lockfile="/tmp/${0##*/}.lock"			

#- rsync options                                           *** depend on environments ***			
export RSYNC_RSH="ssh -i $HOME/.ssh/prikey_nopass.pem"			
options=" -rptDLz --delete "			
#--DEBUG--#options=" -rptDLznv --delete "			

#- rsync command path			
rsynccmd="/usr/bin/rsync"			

#- default exit signal			
exitsig=1			
			
#> trap action			
trap "test -f $lockfile && rm -f $lockfile ; echo [ error ]: $(date '+%Y%m%d %H:%M:%S'): interrupted the process $$ >&2 ; exit 1" SIGINT			
			
#> check the lock file			
[ -f $lockfile ] && echo "[ error ]: $(date '+%Y%m%d %H:%M:%S'): existing $lockfile" >&2 && exit 1			
			
#> create the lock file			
echo $$ > $lockfile			
exitsig=$?			
			
#> predefine the function			
function rsyncerr() {			
  (( exitsig++ ))			
  echo "[ error ]: $(date '+%Y%m%d %H:%M:%S'): rsync failed $srcdirroot/$tgtdir/" >&2			
}			
			
#> main process			
for tgtsv in "${!tgtservers[@]}"			
do			
  echo "[ info ]: $(date '+%Y%m%d %H:%M:%S'): rsync is executing on $tgtsv ..."			
  for tgtdir in "${tgtsuffixlists[@]}"			
  do			
    rsync $options $srcdirroot/$tgtdir/ ${tgtservers[$tgtsv]}:$dstdirroot/$tgtdir &&			
    echo "[ info ]: $(date '+%Y%m%d %H:%M:%S'): succeed $dstdirroot/$tgtdir on ${tgtservers[$tgtsv]}" ||			
    rsyncerr			
  done			
done			
			
#> remove the lock file			
rm -f $lockfile			
			
#> end of the process			
if [ "$exitsig" != "0" ]; then			
  exit 1			
fi			
			
exit 0			
