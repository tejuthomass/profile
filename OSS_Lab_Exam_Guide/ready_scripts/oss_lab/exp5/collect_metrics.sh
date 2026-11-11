#!/bin/bash
# Appends one CSV row: time, disk %, memory %, load, process count
CSV=$HOME/oss_lab/exp5/metrics.csv
if [ ! -f $CSV ]; then
  echo "time,disk,mem,load,procs" > $CSV
fi
TIME=$(date +%Y-%m-%dT%H:%M:%S)
DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
MEM=$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')
LOAD=$(cut -d' ' -f1 /proc/loadavg)
PROCS=$(ps -e --no-headers | wc -l)
echo "$TIME,$DISK,$MEM,$LOAD,$PROCS" >> $CSV
