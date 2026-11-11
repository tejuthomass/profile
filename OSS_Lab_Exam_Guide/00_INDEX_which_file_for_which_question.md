# OSS, Agile Tools and Prompt Engineering Lab: Exam Guide Index

Open the file that matches the question.

| If the question asks about... | Open this file |
|---|---|
| Installing tools, GitHub token, creating the repo, Gemini key (do this FIRST) | `01_SETUP_tools_github_token_repo_gemini_key.md` |
| cron job, crontab, systemd timer, scheduling, log rotation, backup, job dependency, failed job | `EXP1_cron_systemd_timer_monitor_backup_logs.md` |
| git init, auto commit with cron, push to GitHub, branches, pre-commit / post-commit hooks | `EXP2_git_github_auto_commit_push_branch_hooks.md` |
| Agile board, GitHub Projects, issues / user stories, Backlog to Done, link commit to issue, gh CLI | `EXP3_agile_board_issues_commit_link_gh_status.md` |
| CI/CD, GitHub Actions, pipeline test, pass/fail status, prompt / LLM / AI report | `EXP4_cicd_github_actions_test_ai_prompt_report.md` |
| Mini project, integrated system, predictive maintenance, error detection, auto-created issue | `EXP5_miniproject_metrics_cron_ci_ai_predict_auto_issue.md` |
| After the exam: stop jobs, remove token and keys | `99_CLEANUP_after_exam_remove_jobs_tokens.md` |

**Order:** SETUP, then EXP1, then EXP2, and so on. Each experiment uses the folder `~/oss_lab` and the GitHub repo `tejuthomass/oss-lab-exam`.

**Folder layout you will end up with:**
```
~/oss_lab/
├── exp1/   monitor.sh, backup.sh, system_monitor.log
├── exp2/   auto_commit.sh, pre-commit, post-commit
├── exp3/   update_issue.sh, task_mapping.md
├── exp4/   ai_report.py, report.md
├── exp5/   collect_metrics.sh, check_thresholds.sh, push_metrics.sh, predict.py, metrics.csv
└── .github/workflows/   ci.yml, predictive.yml
```

**Nano editor keys:** type or paste the code, then **Ctrl+O**, **Enter** to save and **Ctrl+X** to exit. Paste into the terminal with **Ctrl+Shift+V**.
