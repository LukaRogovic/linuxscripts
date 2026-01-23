# Cron Wizard

Visual cron job builder with natural language support.

![Cron Wizard Screenshot](cronwizard.png)

## What it does

Create and manage cron jobs:
- Natural language input ("every day at 5pm", "weekdays at 9am")
- Visual step-by-step builder
- Manual cron expression entry
- Common job templates
- Edit and delete existing jobs
- View cron execution logs
- Detect scheduling conflicts
- Explain any cron expression
- Backup and restore crontabs

## Usage

Give it permission to run
```bash
chmod +x cron-wizard.sh
```
Run the script
```bash
./cron-wizard.sh
```

## Natural Language Examples

- "every day at 5pm"
- "every monday at 9:30 am"
- "every 15 minutes"
- "weekdays at 8am"
- "every weekend at 10am"
- "midnight"
- "on reboot"
- "monthly"

## Navigation

| Key | Action |
|-----|--------|
| 1-9 | Select category |
| B | Backup crontab |
| R | Restore crontab |
| Q | Quit |

## Requirements

- Bash 4.0+
- Linux distribution
- cron service running
