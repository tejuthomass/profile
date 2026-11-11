# EXP 3: Agile Project Management with Git (GitHub Projects board)

**Aim:** To create an Agile board on GitHub Projects, map the cron/systemd tasks to user stories (issues), move them through Backlog, To Do, In Progress and Done, link commits to issues for traceability, and update task status automatically from a script.

**Needs:** SETUP and EXP2 Steps 1–2 done (repo pushed to GitHub).

---

## Step 1: Create the user stories (issues)
```bash
cd ~/oss_lab
gh issue create --repo tejuthomass/oss-lab-exam --title "Automate system monitoring with cron (monitor.sh)" --body "Run monitor.sh every minute and log disk and memory usage."
gh issue create --repo tejuthomass/oss-lab-exam --title "Automate log backup with systemd timer (backup.sh)" --body "Compress and rotate the monitoring log every 2 minutes."
gh issue create --repo tejuthomass/oss-lab-exam --title "Auto-commit and push logs with cron (auto_commit.sh)" --body "Commit job output to Git and push to GitHub."
gh issue create --repo tejuthomass/oss-lab-exam --title "Validate scripts with Git hooks" --body "pre-commit blocks syntax errors, post-commit confirms commits."
gh issue create --repo tejuthomass/oss-lab-exam --title "Set up Agile board and link automation tasks" --body "Create the project board and map tasks to issues."
gh issue list --repo tejuthomass/oss-lab-exam
```
✅ The list shows issues **#1 to #5**.

## Step 2: Create the project board (in the browser)
1. On github.com, click your **profile photo**, then **Your projects** (or go to **github.com/tejuthomass?tab=projects**).
2. Click **New project**, choose the **Board** template, name it **OSS Lab Board**, and click **Create project**.
3. The board has **Todo**, **In Progress** and **Done**. Add **Backlog**:
   - Click the **+** at the right end of the columns, choose **New column** (or "Add option"), type **Backlog** and save.
   - Drag the **Backlog** column to the **first** position.
4. Rename **Todo** to **To Do**: click **⋯** on the Todo column, then **Edit details**, and rename it.

Final columns: **Backlog, To Do, In Progress, Done**.

## Step 3: Link the board to the repository
1. Open the repository **tejuthomass/oss-lab-exam**.
2. Click the **Projects** tab, then **Link a project**, and choose **OSS Lab Board**.

## Step 4: Add the issues to the board
1. On the board, under the **Backlog** column, click **+ Add item**.
2. Type **#**, choose **oss-lab-exam**, then pick issue **#1**.
3. Repeat for **#2, #3, #4 and #5**.

✅ All 5 cards are in **Backlog**.

## Step 5: Track the status (drag the cards)
- Drag **#1, #2, #3 and #4** through **Backlog, To Do, In Progress and Done** (these tasks already work from EXP1 and EXP2).
- Drag **#5** to **In Progress** (you are working on it now).

## Step 6: Map tasks to issues in a file
```bash
nano exp3/task_mapping.md
```
```markdown
# Task to Issue Mapping

| Automated task | Scheduler | Issue |
|---|---|---|
| monitor.sh | cron (every minute) | #1 |
| backup.sh | systemd timer (every 2 min) | #2 |
| auto_commit.sh | cron (every 2 min) | #3 |
| pre-commit / post-commit hooks | Git | #4 |
| Agile board setup | GitHub Projects | #5 |
```

## Step 7: Link a commit to an issue (traceability)
Put **Closes #5** in the commit message:
```bash
git add exp3/task_mapping.md
git commit -m "Add task to issue mapping. Closes #5"
git push
```
✅ On GitHub, open **Issue #5**. The commit is linked in the timeline, the issue is **Closed**, and on the board card **#5** moves to **Done** automatically.

(Any commit message with `#1`, `#2` and so on also links that commit to the issue without closing it.)

## Step 8: Update the Agile task status from a script
```bash
nano exp3/update_issue.sh
```
```bash
#!/bin/bash
# Posts a status comment on Issue #1 after monitor.sh runs
export GH_TOKEN=$(cat $HOME/.github_token)
gh issue comment 1 --repo tejuthomass/oss-lab-exam --body "Automated update: monitor.sh ran successfully at $(date)"
```
```bash
chmod +x exp3/update_issue.sh
./exp3/update_issue.sh
```
✅ Open **Issue #1** on GitHub: a new comment "Automated update: monitor.sh ran successfully at ..." is there.

## Step 9: Run it automatically after monitor.sh (cron + dependency)
```bash
crontab -e
```
Add at the last line:
```
*/2 * * * * $HOME/oss_lab/exp1/monitor.sh && $HOME/oss_lab/exp3/update_issue.sh
```
`&&` means the issue is updated **only if monitor.sh succeeds**.

Wait 2–4 minutes and refresh **Issue #1**.
✅ A new automatic comment arrives every 2 minutes.

Check that cron ran it:
```bash
crontab -l
grep CRON /var/log/syslog | tail -5
```
**Stop it after showing** (so the issue does not fill with comments):
```bash
crontab -e        # put # in front of the update_issue.sh line, then save
```

---
**If `gh` says "authentication" or "HTTP 401":** run `gh auth login --with-token < ~/.github_token`.

**If `gh issue create` asks "What repository?":** you forgot `--repo tejuthomass/oss-lab-exam`.

---
**Result (write in exam):** A GitHub Projects board with Backlog, To Do, In Progress and Done was created. All automated tasks were mapped to issues #1–#5 and moved across the board, the commit "Closes #5" linked to and closed its issue, and a cron-driven gh CLI script posted status updates on Issue #1 after every successful monitor run.
