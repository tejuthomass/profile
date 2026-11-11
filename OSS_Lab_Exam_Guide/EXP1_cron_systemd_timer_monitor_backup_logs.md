# EXP 1: Job Scheduling and Automation in Linux (cron + systemd timer)

**Aim:** To automate recurring tasks with cron jobs and systemd timers, log their output, handle job dependencies and troubleshoot failed jobs.

**What you build:**
- `monitor.sh` logs the date, disk and memory usage. It runs from **cron** every minute.
- `backup.sh` compresses the log, empties it and deletes old backups. It runs from a **systemd timer** every 2 minutes.

---

## Step 1: Go to the folder
```bash
mkdir -p ~/oss_lab/exp1
cd ~/oss_lab
```

## Step 2: Monitoring script
```bash
nano exp1/monitor.sh
```
```bash
#!/bin/bash
# Logs date, disk usage and memory usage
LOG=$HOME/oss_lab/exp1/system_monitor.log
echo "===== $(date) =====" >> $LOG
echo "Disk usage:" >> $LOG
df -h / >> $LOG
echo "Memory usage:" >> $LOG
free -h >> $LOG
echo "" >> $LOG
```
Save, make it executable and test it:
```bash
chmod +x exp1/monitor.sh
./exp1/monitor.sh
cat exp1/system_monitor.log
```
✅ You should see the date, disk usage and memory usage.

## Step 3: Schedule monitor.sh with cron (every minute)
```bash
crontab -e
```
(The first time only, it asks for an editor: type **1** for nano and press Enter.)

Go to the **last line** and add this one line:
```
* * * * * $HOME/oss_lab/exp1/monitor.sh && echo "monitor.sh OK at $(date)" >> $HOME/oss_lab/exp1/job_status.log
```
Save (**Ctrl+O**, **Enter**, **Ctrl+X**). Check it:
```bash
crontab -l
```
- **cron format:** `minute hour day-of-month month day-of-week command`. `* * * * *` means every minute; `0 * * * *` means every hour; `*/5 * * * *` means every 5 minutes.
- **Job dependency:** `A && B` means B runs **only if A succeeds**, so the "OK" line is written only when monitor.sh worked.

Wait 1–2 minutes, then check:
```bash
cat exp1/system_monitor.log
cat exp1/job_status.log
```
✅ A new entry appears every minute.

Proof that cron ran the job:
```bash
grep CRON /var/log/syslog | tail -5
```
(If that prints nothing, use `journalctl -u cron -n 10 --no-pager`.)

## Step 4: Backup (log rotation) script
```bash
nano exp1/backup.sh
```
```bash
#!/bin/bash
# Compresses the log, empties it, deletes backups older than 60 minutes
DIR=$HOME/oss_lab/exp1
cd $DIR
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz system_monitor.log
> system_monitor.log
find $DIR -name "backup_*.tar.gz" -mmin +60 -delete
echo "Backup done at $(date)"
```
```bash
chmod +x exp1/backup.sh
./exp1/backup.sh
ls exp1
```
✅ You should see a `backup_YYYYMMDD_HHMMSS.tar.gz` file.

## Step 5: systemd service file
Copy and run this **whole block** at once. It writes the file with your username and home folder filled in automatically:
```bash
sudo tee /etc/systemd/system/log-backup.service > /dev/null <<EOF
[Unit]
Description=Backup the system monitor log

[Service]
Type=oneshot
User=$USER
Environment=HOME=$HOME
ExecStartPre=$HOME/oss_lab/exp1/monitor.sh
ExecStart=$HOME/oss_lab/exp1/backup.sh
EOF
```
- `ExecStartPre` is the **dependency**: monitor.sh runs first, and if it fails, backup.sh does **not** run.

## Step 6: systemd timer file (every 2 minutes)
Run this **whole block**:
```bash
sudo tee /etc/systemd/system/log-backup.timer > /dev/null <<'EOF'
[Unit]
Description=Run the log backup every 2 minutes

[Timer]
OnCalendar=*:0/2
AccuracySec=1s
Unit=log-backup.service

[Install]
WantedBy=timers.target
EOF
```
Check both files:
```bash
cat /etc/systemd/system/log-backup.service
cat /etc/systemd/system/log-backup.timer
```

## Step 7: Start the timer
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now log-backup.timer
systemctl list-timers | grep log-backup
systemctl status log-backup.timer
```
✅ `active (waiting)`, with the next trigger time shown. Press **q** to exit.

Run the service once by hand and see its output:
```bash
sudo systemctl start log-backup.service
journalctl -u log-backup.service -n 10 --no-pager
ls exp1
```
✅ The journal shows "Backup done at ...", and a new `.tar.gz` file appears.

## Step 8: Troubleshoot a failed job (show this to the examiner)
Break the job on purpose by removing execute permission:
```bash
chmod -x exp1/backup.sh
sudo systemctl start log-backup.service
systemctl status log-backup.service --no-pager
journalctl -u log-backup.service -n 5 --no-pager
```
❌ It shows **failed** and **Permission denied**.

Fix it:
```bash
chmod +x exp1/backup.sh
sudo systemctl start log-backup.service
systemctl status log-backup.service --no-pager
```
✅ It works again.

**Troubleshooting checklist (write this in the exam):**
1. Check the schedule: `crontab -l`, `systemctl list-timers`
2. Check that cron ran: `grep CRON /var/log/syslog`
3. Check the error: `systemctl status <name>`, `journalctl -u <name>`
4. Common causes: no execute permission (`chmod +x`), relative paths (always use full paths, because cron and systemd do not start in your folder), missing `#!/bin/bash` line.

## Step 9: Scheduling a script that updates Git
cron can also run a script that commits to Git. That is EXP2 Step 4 (`auto_commit.sh`).

## Step 10: Stop the jobs (when done)
```bash
crontab -e        # put # in front of the monitor.sh line, then save
sudo systemctl disable --now log-backup.timer
```

---

### Only if sudo is NOT allowed on the lab PC: user timer
Same idea, no sudo. Run these lines one by one:
```bash
mkdir -p ~/.config/systemd/user
printf "[Unit]\nDescription=Backup log\n\n[Service]\nType=oneshot\nExecStartPre=$HOME/oss_lab/exp1/monitor.sh\nExecStart=$HOME/oss_lab/exp1/backup.sh\n" > ~/.config/systemd/user/log-backup.service
printf "[Unit]\nDescription=Backup every 2 min\n\n[Timer]\nOnCalendar=*:0/2\nAccuracySec=1s\n\n[Install]\nWantedBy=timers.target\n" > ~/.config/systemd/user/log-backup.timer
systemctl --user daemon-reload
systemctl --user enable --now log-backup.timer
systemctl --user list-timers
journalctl --user -u log-backup.service -n 10 --no-pager
```

---
**Result (write in exam):** cron ran monitor.sh every minute and a systemd timer ran backup.sh every 2 minutes. The logs, backups and job dependencies (`&&` in cron, `ExecStartPre` in systemd) were verified, and a failed job was diagnosed with `journalctl` and fixed.
