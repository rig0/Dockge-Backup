#!/bin/bash

# Load the .env file. ex.
if [ -f "$(dirname "$0")/.env" ]; then
    export $(grep -v '^#' "$(dirname "$0")/.env" | xargs)
fi

# Check for required env variables
if [[ -z "$API_URL" || -z "$API_TOKEN" ||-z "$USER" || -z "$HOST" || -z "$BACKUP_DIR" || -z "$NAS_DIRECTORY" ]]; then
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
echo "Backing up $STACKS_DIR"
for dir in "$STACKS_DIR"/*; do
    if [ -d "$dir" ]; then
        # Get directory name without path
        dir_name=$(basename "$dir")
        mkdir -p "$BACKUP_DIR/$dir_name"
        # If the directory is "fireshare", exclude the "videos" folder from the archive
        if [ "$dir_name" == "fireshare" ]; then
            tar -czf "$BACKUP_DIR/$dir_name/${dir_name}_${TIMESTAMP}.tar.gz" \
                --exclude="videos" -C "$STACKS_DIR" "$dir_name"
        else
            # Create tar.gz archive for each directory normally
            tar -czf "$BACKUP_DIR/$dir_name/${dir_name}_${TIMESTAMP}.tar.gz" -C "$STACKS_DIR" "$dir_name"
        fi
    fi
done

# Archive /opt/dockge directory
if [ -d "$DOCKGE_DIR" ]; then
    mkdir -p "$BACKUP_DIR/dockge"
    tar -czf "$BACKUP_DIR/dockge/dockge_${TIMESTAMP}.tar.gz" -C "$(dirname "$DOCKGE_DIR")" "$(basename "$DOCKGE_DIR")"
fi

# Change ownership of local-stack and its contents
chown -R "$USER:$USER" "$BACKUP_DIR"

echo "Backup complete. Archives moved to $BACKUP_DIR, and ownership changed to $USER:$USER."

# Call API to pick up
ENDPOINT="/backup"
FULL_URL="${API_URL}${ENDPOINT}"

echo "Sending backup to backup server"
curl --location "$FULL_URL" \
--header "Content-Type: application/json" \
--header "Authorization: Bearer $API_TOKEN" \
--data "{
    \"remote_user\": \"$USER\",
    \"remote_host\": \"$HOST\",
    \"remote_folder\": \"$BACKUP_DIR\",
    \"local_folder\": \"$NAS_DIRECTORY\"
}"

# Check if curl succeeded
if [ $? -eq 0 ]; then
    echo "Backup succeeded. Deleting local backups at $BACKUP_DIR"
    rm -R $BACKUP_DIR
else
    echo "Backup failed. Preserving local backups"
fi