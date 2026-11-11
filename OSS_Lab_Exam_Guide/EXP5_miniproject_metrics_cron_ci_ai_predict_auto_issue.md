# EXP 5: Mini Project — Open-Source Automation with Job Scheduling (Predictive Maintenance)

**Aim:** To combine job scheduling, Git/GitHub, an Agile board, a CI/CD pipeline and prompt automation into one system. The system collects system metrics on a schedule, predicts resource exhaustion with rule-based and AI checks, and automatically creates an Agile issue when the risk is high.

**Needs:** SETUP (with the Gemini key), EXP2 Steps 1–2, EXP3 Steps 2–3 (board) and EXP4 Step 3 (the `GEMINI_API_KEY` secret).

**System flow:**
```
cron (every minute) → collect_metrics.sh → metrics.csv
cron (every 5 min)  → push_metrics.sh → git push to GitHub
push → GitHub Actions (predictive.yml)
        → check_thresholds.sh (rule-based)
        → predict.py (AI prediction with Gemini)
        → prediction report saved as artifact
        → if risk = high → new GitHub Issue → Agile board
```

---

## Step 1: Metric collection script (CSV)
```bash
cd ~/oss_lab
mkdir -p exp5
nano exp5/collect_metrics.sh
```
```bash
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
```
```bash
chmod +x exp5/collect_metrics.sh
./exp5/collect_metrics.sh
./exp5/collect_metrics.sh
cat exp5/metrics.csv
```
✅ A header and 2 rows (time, disk %, memory %, load, processes).

## Step 2: Rule-based threshold check
```bash
nano exp5/check_thresholds.sh
```
```bash
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
```
```bash
chmod +x exp5/check_thresholds.sh
cd ~/oss_lab
./exp5/check_thresholds.sh
```
✅ `OK: within limits` (disk below 80%, memory below 90%).

## Step 3: AI prediction script
```bash
nano exp5/predict.py
```
```python
#!/usr/bin/env python3
# Predictive maintenance: asks the AI if resources will run out soon
import os, json, urllib.request

CSV = "exp5/metrics.csv"
MODELS = ["gemini-3.1-flash-lite", "gemini-3.5-flash-lite", "gemini-2.5-flash"]

# 1. Read the last 10 readings
lines = open(CSV).read().strip().split("\n")
header, rows = lines[0], lines[1:][-10:]
last = rows[-1].split(",")
disk, mem = float(last[1]), float(last[2])

# 2. Build the prompt
prompt = ("You are a Linux predictive maintenance assistant. Thresholds: disk 80%, memory 90%.\n"
          "Look at the trend in these readings and predict if resources will run out soon.\n"
          "Reply in exactly this format:\n"
          "RISK: low or medium or high\n"
          "SUMMARY: one or two sentences\n"
          "ACTIONS: two short fixes\n\n" + header + "\n" + "\n".join(rows))

# 3. Ask Gemini (try each model in turn)
key = os.environ.get("GEMINI_API_KEY", "")
answer = None
for model in MODELS:
    if key == "":
        break
    try:
        url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent"
        body = json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode()
        req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "x-goog-api-key": key})
        result = json.loads(urllib.request.urlopen(req, timeout=60).read())
        answer = result["candidates"][0]["content"]["parts"][0]["text"]
        print("Prediction by", model)
        break
    except Exception as e:
        print(model, "failed:", e)

# 4. Fallback rule if the AI is not reachable
if answer is None:
    if disk >= 95 or mem >= 90:
        risk = "high"
    elif disk >= 80:
        risk = "medium"
    else:
        risk = "low"
    answer = ("RISK: " + risk + "\nSUMMARY: Rule-based check (AI not reachable). Disk " + str(disk) +
              "%, memory " + str(mem) + "%.\nACTIONS: Clean large files (du -sh * | sort -h); stop heavy processes (top).")

# 5. Pick out the risk level and save the files
text = answer.lower().replace("*", "")
risk = "low"
if "risk: high" in text:
    risk = "high"
elif "risk: medium" in text:
    risk = "medium"
if disk >= 95 or mem >= 90:
    risk = "high"   # safety rule: a critical reading is always high risk
open("exp5/risk.txt", "w").write(risk)
open("exp5/prediction.md", "w").write("# Predictive Maintenance Report\n\n" + answer + "\n")
print(answer)
print("Risk level:", risk)
```
Test it:
```bash
cd ~/oss_lab
export GEMINI_API_KEY=$(cat ~/.gemini_key)
python3 exp5/predict.py
cat exp5/risk.txt
```
✅ It prints RISK, SUMMARY and ACTIONS, then `Risk level: low` (or medium).

## Step 4: Push script (sends the metrics to GitHub)
```bash
nano exp5/push_metrics.sh
```
```bash
#!/bin/bash
# Commits and pushes the latest metrics to GitHub
cd $HOME/oss_lab
git add exp5/metrics.csv
git commit -m "Metrics update at $(date)"
git push
```
```bash
chmod +x exp5/push_metrics.sh
```

## Step 5: Schedule with cron
```bash
crontab -e
```
Add these two lines at the end:
```
* * * * * $HOME/oss_lab/exp5/collect_metrics.sh
*/5 * * * * $HOME/oss_lab/exp5/push_metrics.sh >> $HOME/oss_lab/exp5/push.log 2>&1
```
(Put **#** in front of any older EXP2 auto_commit line, so only one job pushes.)

## Step 6: Predictive pipeline (GitHub Actions)
```bash
nano .github/workflows/predictive.yml
```
```yaml
name: Predictive Maintenance

on:
  push:
    branches: [main]
    paths: ['exp5/**']
  schedule:
    - cron: '30 2 * * *'
  workflow_dispatch:

permissions:
  contents: read
  issues: write

jobs:
  predict:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Rule-based threshold check
        continue-on-error: true
        run: bash exp5/check_thresholds.sh
      - name: AI prediction
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: python3 exp5/predict.py
      - name: Save prediction as artifact
        uses: actions/upload-artifact@v4
        with:
          name: prediction-report
          path: exp5/prediction.md
      - name: Create Agile issue if risk is high
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          RISK=$(cat exp5/risk.txt)
          echo "Risk is $RISK"
          if [ "$RISK" = "high" ]; then
            gh issue create --repo ${{ github.repository }} --title "Predicted resource exhaustion risk" --body-file exp5/prediction.md
          fi
```
- `push` with `paths` runs only when exp5 files change.
- `schedule` runs daily at 02:30 UTC (08:00 IST).
- `workflow_dispatch` adds a **Run workflow** button.

## Step 7: Push everything
```bash
git add exp5 .github/workflows/predictive.yml
git commit -m "Add predictive maintenance mini project"
git push
```
On GitHub, open **Actions**, then **Predictive Maintenance**, then the latest run.
✅ All steps are green. The **Risk is low** (or medium) line is in the last step, and **prediction-report** is under **Artifacts**. No issue is created.

## Step 8: Test the HIGH-risk path (simulate a critical spike)
First stop the two exp5 cron lines, so they don't add rows during the test:
```bash
crontab -e        # put # in front of both exp5 lines, then save
```
Add a fake critical reading (disk 97%, memory 92%):
```bash
cd ~/oss_lab
echo "$(date +%Y-%m-%dT%H:%M:%S),97,92.0,3.50,250" >> exp5/metrics.csv
./exp5/check_thresholds.sh
git add exp5/metrics.csv
git commit -m "Simulate critical resource spike"
git push
```
✅ Locally: `ALERT: threshold crossed`.
✅ In **Actions**, the run shows **Risk is high**.
✅ In **Issues**, a new issue **"Predicted resource exhaustion risk"** (author: github-actions) contains the AI prediction and actions.
✅ Add it to the board: on **OSS Lab Board**, click **+ Add item** in **Backlog**, type **#** and pick the new issue.

## Step 9: Back to normal (remove the fake row)
```bash
sed -i '$d' exp5/metrics.csv
tail -3 exp5/metrics.csv
git add exp5/metrics.csv
git commit -m "Remove simulated spike"
git push
```
✅ The new run shows **Risk is low** (or medium) and **no** new issue is created. The alert fires only when it should.

(Optional) Turn the two exp5 cron lines back on with `crontab -e` (remove the #).

---
**If the real disk on the lab PC is already above 80%:** the risk may show **medium** even on real data. That is correct; explain that the threshold is 80%.

**If the "Create Agile issue" step fails with "Resource not accessible":** the `permissions:` block (`issues: write`) must be in `predictive.yml`.

---
**Result (write in exam):** An integrated system was built. cron collects metrics and pushes them to GitHub, and GitHub Actions runs a rule-based threshold check and a Gemini-based prediction, then publishes the report. When a simulated spike was pushed, the pipeline automatically created a high-risk issue for the Agile board; on normal data it created no issue.
