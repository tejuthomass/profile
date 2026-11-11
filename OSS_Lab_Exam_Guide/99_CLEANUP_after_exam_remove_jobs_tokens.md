# CLEANUP: after the exam (college PC is shared)

```bash
crontab -r
sudo systemctl disable --now log-backup.timer
sudo rm -f /etc/systemd/system/log-backup.service /etc/systemd/system/log-backup.timer
sudo systemctl daemon-reload
gh auth logout --hostname github.com
rm -f ~/.github_token ~/.gemini_key ~/.git-credentials
git config --global --unset credential.helper
```
Then on github.com: **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Delete** the `oss-lab-exam` token.

(Optional) Delete the project folder: `rm -rf ~/oss_lab`
