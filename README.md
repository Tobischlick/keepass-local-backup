# KeePass Local Backup
Automated local backups for cloud-synced KeePass databases.

## Setup
1. Clone this repo.
2. `cp .env.example .env` and edit the paths.
3. Make the script executable: `chmod +x backup_keepass.sh`.

## Automation (Ubuntu)
1. Open **Startup Applications**.
2. Click **Add**.
3. Command: `/home/YOUR_USER/keepass-local-backup/backup_keepass.sh`