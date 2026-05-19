# My Skills

Personal collection of AI skills for workflow automation.

## Skills

| Skill | Description |
|-------|-------------|
| [rfp](rfp/) | Structured workflow for answering RFP questions using documentation repos and web research. Covers scope confirmation, parallel research, drafting, review, URL validation, and customer-facing output generation. |
| [install-rhoai-34](install-rhoai-34/) | Install Red Hat OpenShift AI (RHOAI) 3.4 on a fresh OpenShift 4.20+ cluster using the ai-accelerator GitOps repo. Use this skill when the user asks to install, deploy, or set up RHOAI 3.4 on an OpenShift cluster. Trigger on: 'install RHOAI', 'deploy RHOAI 3.4', 'set up OpenShift AI', '安装RHOAI', '部署RHOAI 3.4', '搭建AI平台'.|

## Usage

Invoke a skill by typing `/<skill-name>` (e.g., `/rfp`).

## Installing skills to Claude Code

Skills in this repo need to be symlinked to `~/.claude/skills/` to be globally available. Run:

```bash
./sync-skills.sh
```

This scans all subdirectories containing a `SKILL.md`, and creates symlinks in `~/.claude/skills/`. Already-linked skills are skipped. Run this once after adding a new skill.
