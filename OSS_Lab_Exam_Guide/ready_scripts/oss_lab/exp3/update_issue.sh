#!/bin/bash
# Posts a status comment on Issue #1 after monitor.sh runs
export GH_TOKEN=$(cat $HOME/.github_token)
gh issue comment 1 --repo tejuthomass/oss-lab-exam --body "Automated update: monitor.sh ran successfully at $(date)"
