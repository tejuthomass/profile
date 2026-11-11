#!/bin/bash
# Rule-based check on the latest reading. Exit 1 = threshold crossed
CSV=exp5/metrics.csv
LAST=$(tail -n 1 $CSV)
DISK=$(echo $LAST | cut -d',' -f2)
MEM=$(echo $LAST | cut -d',' -f3 | cut -d'.' -f1)
echo "Latest reading: disk=$DISK% mem=$MEM%"
if [ $DISK -ge 80 ] || [ $MEM -ge 90 ]; then
  echo "ALERT: threshold crossed"
  exit 1
fi
echo "OK: within limits"
exit 0
