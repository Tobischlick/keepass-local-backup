![Tests](https://github.com/Tobischlick/keepass-local-backup/actions/workflows/tests.yml/badge.svg)
![ShellCheck](https://github.com/Tobischlick/keepass-local-backup/actions/workflows/lint.yml/badge.svg)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/Tobischlick/keepass-local-backup)
![GitHub](https://img.shields.io/github/license/Tobischlick/keepass-local-backup)
![GitHub top language](https://img.shields.io/github/languages/top/Tobischlick/keepass-local-backup)

# KeePass Local Backup Tool 🛡️

A robust, privacy-conscious shell script designed to create timestamped local backups of your KeePass (`.kdbx`) database. This tool is specifically optimized for users who sync their database via OneDrive (using `onedriver`), Dropbox, or other cloud services and want an automated local "failsafe" copy.

## ✨ Features
- **Smart Variable Loading**: Uses `.env` files to keep your private folder structure and file names out of version control.
- **Visual Status Reporting**: Provides real-time feedback with clear terminal feedback, progress bars, and path verification.
- **Idempotency (Smart Skipping) 💡**: Automatically skips creation if a backup already exists for the current day and the checksum matches your source file, saving disk space.
- **Execution Modes**:
    - **Startup Mode**: Includes a configurable safety delay with an interactive terminal countdown to allow cloud services to mount.
    - **Manual Mode**: Skip the delay using flags (`--now` or `-n`) for immediate backups.
    - **Force Mode**: Override daily smart-skipping logic entirely using flags (`--force` or `-f`).
- **Configurable Delay**: Fine-tune your mount-wait time directly in the configuration.
- **Auto-Cleanup**: Automatically purges old backups based on a custom retention period.
- **Desktop Notifications**: Sends native system alerts for successful backups and critical errors using `notify-send`.
- **Checksum Verification**: Calculates and verifies SHA-256 hashes to guarantee backup integrity.
- **File Type Verification**: Validates the MIME-type to ensure the file is an authentic KeePass database before copying.

---

## 🚀 Setup & Installation

### 1. Clone the Repository

#### HTTPS
```bash
git clone https://github.com/Tobischlick/keepass-local-backup.git
cd keepass-local-backup
```
#### SSH
```bash
git clone git@github.com:Tobischlick/keepass-local-backup.git
cd keepass-local-backup
```

### 2. Configure Environment Variables
Adjust the configuration the way that suits your use case the best (see explanations at 4.)
```bash
cp .env.example .env
nano .env
```

### 3. Permissions
Make the script executable:
```bash
cd src
chmod +x backup_keepass.sh
```

### 4. Configuration (.env)

The tool is entirely controlled via the `.env` file. Below are the available parameters:

| Variable | Description | Example Value                               |
| :--- | :--- |:--------------------------------------------|
| `SOURCE_DB` | **Absolute path** to your cloud-synced `.kdbx` file. | `"/home/user/OneDrive/Passwords/Main.kdbx"` |
| `BACKUP_DIR` | **Absolute path** to the local folder for storing backups. | `"/home/user/Documents/KeePassBackups"`     |
| `RETENTION_DAYS` | Number of days to keep a backup before auto-deletion. | `7`                                         |
| `SLEEP_DELAY` | Seconds to wait on startup for cloud drives to mount. | `30`                                        |

### Example .env File
```text
SOURCE_DB="/home/miriam-musterfrau/OneDrive/Passwords/Database.kdbx"
BACKUP_DIR="/home/miriam-musterfrau/Documents/KeePassBackups"
RETENTION_DAYS=7
SLEEP_DELAY=30
```

### 5. Usage

#### Available Options & Flags

| Long Flag | Short Flag | Description |
| :--- | :--- | :--- |
| `--now` | `-n` | Bypasses the configured `SLEEP_DELAY` safety countdown for immediate execution. |
| `--force` | `-f` | Overrides the daily smart-skipping logic, forcing a fresh backup snapshot even if an identical duplicate already exists for today. |

---

#### Manual Backup (Immediate)
Use this mode when you are already logged in and want to trigger a backup instantly. The `--now` or `-n` flag bypasses the configured `SLEEP_DELAY`.
```bash
# Navigate to the directory
cd ~/keepass-local-backup/src

# Run with the 'now' flag
./backup_keepass.sh --now
```

#### Automatic Backup (On Startup)

To automate the backup every time you log in to your system, follow these steps to add the script to your startup sequence:

1. **Open Startup Applications**:
   Search for "Startup Applications" in your GNOME/Ubuntu dashboard.

2. **Add a New Entry**:
   Click the **Add** button to open the configuration window.

3. **Fill in the Fields**:
    * **Name**: `KeePass Auto-Backup`
    * **Command**: `/home/YOUR_USERNAME/keepass-local-backup/src/backup_keepass.sh`
      *(Ensure you use the absolute path to your script folder)*
    * **Comment**: `Creates a local backup of the cloud-synced database after the cloud drive mounts.`

4. **Verify Timing**:
   In this mode, the script will automatically wait for the duration defined by `SLEEP_DELAY` in your `.env` file (defaulting to 30 seconds) to ensure OneDrive/Cloud mounts have successfully completed.

5. **Save**:
   Click **Add** and then **Close**. The backup will now trigger automatically upon your next login.