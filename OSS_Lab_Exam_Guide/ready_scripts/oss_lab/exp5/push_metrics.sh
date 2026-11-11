#!/bin/bash
# Commits and pushes the latest metrics to GitHub
cd $HOME/oss_lab
git add exp5/metrics.csv
git commit -m "Metrics update at $(date)"
git push
