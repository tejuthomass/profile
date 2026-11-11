#!/bin/bash
# Commits the exp1 logs and pushes them to GitHub
cd $HOME/oss_lab
git add exp1
git commit -m "Auto commit: logs updated at $(date)"
git push
