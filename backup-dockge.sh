#!/bin/bash

# Load the .env file. ex.
if [ -f "$(dirname "$0")/.env" ]; then
    export $(grep -v '^#' "$(dirname "$0")/.env" | xargs)
fi

# Check for required env variables
if [[ -z "$BACKUP_API_TOKEN" || -z "$USER" || -z "$HOST" || -z "$BACKUP_DIR" || -z "$NAS_DIRECTORY" ]]; then
    echo "Error: One or more required variables are not set."
    exit 1
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

        # If the directory is "fireshare", exclude the "videos" folder from the archive
        if [ "$dir_name" == "fireshare" ]; then
            tar --exclude="$STACKS_DIR/$dir_name/videos" -czf "$BACKUP_DIR/${dir_name}_${TIMESTAMP}.tar.gz" -C "$STACKS_DIR" "$dir_name"
        else
            # Create tar.gz archive for each directory normally
            tar -czf "$BACKUP_DIR/${dir_name}_${TIMESTAMP}.tar.gz" -C "$STACKS_DIR" "$dir_name"
        fi
    fi
done


# Archive /opt/dockge directory
if [ -d "$DOCKGE_DIR" ]; then
    tar -czf "$BACKUP_DIR/dockge_${TIMESTAMP}.tar.gz" -C "$(dirname "$DOCKGE_DIR")" "$(basename "$DOCKGE_DIR")"
fi

# Change ownership of local-stack and its contents
chown -R "$USER:$USER" "$BACKUP_DIR"

echo "Backup complete. Archives moved to $BACKUP_DIR, and ownership changed to $USER:$USER."

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