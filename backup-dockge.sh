#!/bin/bash

# Load the .env file. ex.
#BACKUP_API_TOKEN=
#NAS_DIRECTORY=
#BACKUP_DIR=
#HOST=
#USER=

if [ -f "$(dirname "$0")/.env" ]; then
    export $(grep -v '^#' "$(dirname "$0")/.env" | xargs)
fi

# Set variables
STACKS_DIR="/opt/stacks"
DOCKGE_DIR="/opt/dockge"
TIMESTAMP=$(date +"%Y_%j_%H%M%S") # Year_DayOfYear_Time

# Create destination directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Archive each directory in /opt/stacks/*
for dir in "$STACKS_DIR"/*; do
    if [ -d "$dir" ]; then
        # Get directory name without path
        dir_name=$(basename "$dir")

        # Create tar.gz archive for each directory
        tar -czf "$BACKUP_DIR/${dir_name}_${TIMESTAMP}.tar.gz" -C "$STACKS_DIR" "$dir_name"
    fi
done

# Archive /opt/dockge directory
if [ -d "$DOCKGE_DIR" ]; then
    tar -czf "$BACKUP_DIR/dockge_${TIMESTAMP}.tar.gz" -C "$(dirname "$DOCKGE_DIR")" "$(basename "$DOCKGE_DIR")"
fi

# Change ownership of local-stack and its contents
chown -R "$USER:$USER" "$BACKUP_DIR"

echo "Backup complete. Archives moved to $BACKUP_DIR, and ownership changed to $USER:$USER."

# Get the IP address of the default interface
ip_address=$(hostname -I | awk '{print $1}')

# Call API to pick up
curl --location 'https://backups.rigslab.com/backup' \
--header "Content-Type: application/json" \
--header "Authorization: Bearer $BACKUP_API_TOKEN" \
--data "{
    \"remote_user\": \"$USER\",
    \"remote_host\": \"$HOST\",
    \"remote_folder\": \"$BACKUP_DIR\",
    \"local_folder\": \"$NAS_DIRECTORY\"
}"