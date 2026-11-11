# SETUP: do this first (10 minutes)

Run every command in a terminal (**Ctrl+Alt+T**).

## Step 1: Install the tools
```bash
sudo apt update
sudo apt install -y git gh cron curl python3 nano
```
Check that they work:
```bash
git --version
gh --version
python3 --version
systemctl status cron
```
(Press **q** to leave `systemctl status`. It must say **active (running)**. If it doesn't, run `sudo systemctl enable --now cron`.)

> **Only if `apt install gh` says "Unable to locate package gh"**, install gh from GitHub's official repo:
> ```bash
> sudo mkdir -p -m 755 /etc/apt/keyrings
> wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
> sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
> echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
> sudo apt update && sudo apt install -y gh
> ```

## Step 2: Set your Git identity
```bash
git config --global user.name "Teju Thomas"
git config --global user.email "89849221+tejuthomass@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global credential.helper store
```
(`credential.helper store` makes Git remember the token after the first push, so the cron jobs can push without asking.)

## Step 3: Create a GitHub token (PAT)
In the browser, log in to github.com, then:
1. Click your **profile photo**, then **Settings**.
2. In the left menu, at the bottom, click **Developer settings**.
3. Click **Personal access tokens**, then **Tokens (classic)**.
4. Click **Generate new token**, then **Generate new token (classic)**.
5. Note: `oss-lab-exam`. Expiration: **7 days**.
6. Tick these scopes: **repo**, **workflow** and **read:org**.
7. Click **Generate token** and **copy** it (it starts with `ghp_`).

Save the token in a file (paste your token in place of `ghp_...`):
```bash
echo "ghp_PASTE_YOUR_TOKEN_HERE" > ~/.github_token
chmod 600 ~/.github_token
```
Log in the GitHub CLI with it:
```bash
gh auth login --with-token < ~/.github_token
gh auth status
```
`gh auth status` must say **Logged in to github.com**.

## Step 4: Create the empty GitHub repository
1. On github.com, click **+** (top right), then **New repository**.
2. Repository name: **oss-lab-exam**
3. Choose **Public**.
4. Do **NOT** tick "Add a README" (leave everything empty).
5. Click **Create repository**.

> If `oss-lab-exam` already exists, delete the old one (Settings, then Delete this repository at the bottom) or use another name and change it everywhere you see `oss-lab-exam`.

## Step 5: Create the project folder
```bash
mkdir -p ~/oss_lab/exp1 ~/oss_lab/exp2 ~/oss_lab/exp3 ~/oss_lab/exp4 ~/oss_lab/exp5 ~/oss_lab/.github/workflows
cd ~/oss_lab
```

## Step 6: Gemini API key (needed for EXP4 and EXP5 only)
1. Open **https://aistudio.google.com/apikey** and log in with Google.
2. Click **Create API key** and copy it.
3. Save it:
```bash
echo "PASTE_YOUR_GEMINI_KEY_HERE" > ~/.gemini_key
chmod 600 ~/.gemini_key
```
4. Check that the key works (it should print model names):
```bash
curl -s -H "x-goog-api-key: $(cat ~/.gemini_key)" https://generativelanguage.googleapis.com/v1beta/models | grep '"name"' | head -5
```
> If there's no internet or the key doesn't work, the Python scripts still produce a rule-based report, so the experiment won't fail.

Setup is done. Go to **EXP1**.
