#!/bin/bash

# parse command line args
if [[ $# -lt 1 ]]; then
  (>&2 echo "usage: $0 svdq.log")
  exit 1
fi
filename=$1

# output params
ver="NULL"  # SVDQ version used
cpu="-1"  # CPU time
iq="-1"   # incompatible quartets
cq="-1"   # compatible quartets

# extract SVDQ version
ver=$(cat $filename | awk '/P A U P \*/{x=1;next}x{print;x=0}' | tail -1 | perl -ne '/Version (.+) for/&&print "$1\n"')
ver=${ver:-"NULL"}

# extract CPU time
cpu=$(grep "SVDQ.*CPU" $filename | tail -1 | perl -ne '/CPU time = ([^)]+)/&&print "$1\n"' \
      | awk '{split($0,a," ");if(length(a)>1)printf "00:00:%s\n",a[1];else printf "%s",a[1]}')
if [ ! -z "$cpu" ]; then
  cpu=$(echo "$cpu" | awk '{split($1,a,":");s=a[1]*60+a[2]+a[3]/60;print s}')
else
  cpu="-1"
fi

# extract proportion of incompatible quartets
iq=$(grep " incompatible quartets" $filename | tail -1 | perl -ne '/\((.+)\)/&&print "$1\n"')
if [ ! -z "$iq" ]; then
  iq=$(echo "${iq%\%}" | awk '{printf "%.2f",$1}')
else
  iq="-1"
fi

# extract proportion of compatible quartets
cq=$(grep " compatible quartets" $filename | tail -1 | perl -ne '/\((.+)\)/&&print "$1\n"')
if [ ! -z "$cq" ]; then
  cq=$(echo "${cq%\%}" | awk '{printf "%.2f",$1}')
else
  cq="-1"
fi

# print output params, separated by ','
echo "${ver},${cpu},${iq},${cq}"
