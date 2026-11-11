#!/bin/bash
# Logs date, disk usage and memory usage
LOG=$HOME/oss_lab/exp1/system_monitor.log
echo "===== $(date) =====" >> $LOG
echo "Disk usage:" >> $LOG
df -h / >> $LOG
echo "Memory usage:" >> $LOG
free -h >> $LOG
echo "" >> $LOG
