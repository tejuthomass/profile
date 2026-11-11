# EXP 2: Git and GitHub Integration (auto commit, push, branch, hooks)

**Aim:** To track automated scripts and logs with Git, commit job outputs automatically using cron, push to GitHub, manage a branch for scheduled tasks, and validate scripts with pre-commit and post-commit hooks.

**Needs:** SETUP done, and EXP1 Steps 1–2 done (`exp1/monitor.sh` exists).

---

## Step 1: Start the Git repository
```bash
cd ~/oss_lab
git init
echo ".env" > .gitignore
git add .
git commit -m "Initial commit: scheduling scripts"
git log --oneline
```

## Step 2: Connect to GitHub and push
```bash
git remote add origin https://github.com/tejuthomass/oss-lab-exam.git
git branch -M main
git push -u origin main
```
When it asks:
- **Username:** `tejuthomass`
- **Password:** paste your **token** (`ghp_...`), **not** your GitHub password. Nothing shows while you paste; that is normal. Press Enter.

✅ Refresh the repository page on GitHub: your files are there. (Git now remembers the token.)

## Step 3: Git hooks (pre-commit and post-commit)
**pre-commit** runs **before** every commit and blocks it if a `.sh` file has a syntax error.
```bash
nano .git/hooks/pre-commit
```
```bash
#!/bin/bash
# Blocks the commit if any staged .sh file has a syntax error
echo "pre-commit: checking shell scripts..."
for file in $(git diff --cached --name-only | grep '\.sh$'); do
  if [ -f "$file" ]; then
    if ! bash -n "$file"; then
      echo "ERROR: syntax error in $file. Commit blocked."
      exit 1
    fi
  fi
done
echo "pre-commit: all scripts OK"
exit 0
```
**post-commit** runs **after** a commit is saved and prints a confirmation.
```bash
nano .git/hooks/post-commit
```
```bash
#!/bin/bash
# Confirms the commit after it is saved
echo "post-commit: commit saved -> $(git log -1 --oneline)"
```
Make both executable:
```bash
chmod +x .git/hooks/pre-commit .git/hooks/post-commit
```
Keep a copy in the repo (hooks inside `.git/` are not pushed):
```bash
cp .git/hooks/pre-commit .git/hooks/post-commit exp2/
```

## Step 4: Auto-commit script (commits job output and pushes)
```bash
nano exp2/auto_commit.sh
```
```bash
#!/bin/bash
# Commits the exp1 logs and pushes them to GitHub
cd $HOME/oss_lab
git add exp1
git commit -m "Auto commit: logs updated at $(date)"
git push
```
```bash
chmod +x exp2/auto_commit.sh
./exp2/auto_commit.sh
```
✅ You see the pre-commit and post-commit messages, then the push to GitHub.

## Step 5: Run the auto-commit from cron (every 2 minutes)
```bash
crontab -e
```
Add at the last line:
```
*/2 * * * * $HOME/oss_lab/exp2/auto_commit.sh >> $HOME/oss_lab/exp2/auto_commit.log 2>&1
```
Save. (The monitor.sh cron line from EXP1 must still be active so that new log data appears.)

Wait 2–4 minutes, then check:
```bash
git log --oneline | head
cat exp2/auto_commit.log
```
✅ Commits named "Auto commit: logs updated at ..." appear, and they also appear on GitHub (**Commits** link on the repository page).

**Stop the auto-commit before the branch step** (otherwise cron and you change the same files at the same time):
```bash
crontab -e        # put # in front of the auto_commit.sh line, then save
```

## Step 6: Branch for scheduled-task changes
```bash
git checkout -b feature/scheduled-tasks
echo "Branch for changes to the scheduled tasks" > exp2/branch_notes.md
git add exp2/branch_notes.md
git commit -m "Add branch notes for scheduled tasks"
git push -u origin feature/scheduled-tasks
git branch -a
```
✅ On GitHub the branch dropdown shows **feature/scheduled-tasks**.

Merge it back into main:
```bash
git checkout main
git merge feature/scheduled-tasks
git push
git log --oneline | head -5
```

## Step 7: Test the hooks
**Bad script: the commit must be BLOCKED**
```bash
printf 'if [ 1 -eq 1 ]; then\n  echo hello\n' > exp2/bad_script.sh
git add exp2/bad_script.sh
git commit -m "Add bad script"
```
❌ Output: `syntax error ... ERROR: syntax error in exp2/bad_script.sh. Commit blocked.`

**Fix the script: the commit must PASS**
```bash
printf 'if [ 1 -eq 1 ]; then\n  echo hello\nfi\n' > exp2/bad_script.sh
git add exp2/bad_script.sh
git commit -m "Fix bad script"
git push
```
✅ Output: `pre-commit: all scripts OK`, then `post-commit: commit saved -> <id> Fix bad script`.

---
**If push asks for a password again or says "Authentication failed":** run the push again and paste the token (from `cat ~/.github_token`) as the password.

**If push says "rejected (fetch first)":** run `git pull --rebase` and then `git push`.

---
**Result (write in exam):** The repository was created and pushed to GitHub with token authentication. cron committed and pushed the job logs automatically, a feature branch was created and merged, and the pre-commit hook blocked a script with a syntax error while the post-commit hook confirmed each commit.
