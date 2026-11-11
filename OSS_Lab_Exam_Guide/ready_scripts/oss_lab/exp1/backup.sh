#!/bin/bash
# Compresses the log, empties it, deletes backups older than 60 minutes
DIR=$HOME/oss_lab/exp1
cd $DIR
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz system_monitor.log
> system_monitor.log
find $DIR -name "backup_*.tar.gz" -mmin +60 -delete
echo "Backup done at $(date)"
