# Dockge-Backup

A script to backup [Dockge](https://github.com/louislam/dockge) stacks. 

#### *Intended to use with [Backup-API](https://rigslab.com/Rambo/Backup-API) to backup to a remote server. Comment out API call if not using Backup-API.*

### Prerequisites
```bash
sudo apt install rsync curl
```

### Copy script locally
```bash
curl -O https://rigslab.com/Rambo/Dockge-Backup/raw/branch/main/backup-dockge.sh && chmod +x backup-dockge.sh
```

### Create a .env file in the same directory as the backup script and store the following
```bash
API_URL=https://api.yourserver.com
API_TOKEN=API-Token
NAS_DIRECTORY=/backup/server/directory # where the remote backups will be stored
BACKUP_DIR=/local/server/directory # where the local backups are stored
HOST=IP-Address # IP address of local system where the API will fetch the backups
USER=user # this user will have permission to the backup archives
```

### Use `backup-dockge.sh` to back up Dockge data and Stacks data
```bash
sudo ./backup-dockge.sh
```