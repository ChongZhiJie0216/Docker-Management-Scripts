#!/bin/bash

# Docker Compose Files Directory
dir_path="/root/Docker-Compose/02-ComposeFile/"
files=(
  "docker-compose-npm.yml"
  "docker-compose-fastapi.yml"
  "docker-compose-portainer.yml"
  "docker-compose-cloudflare_tunnel.yml"
  "docker-compose-uptime_kuma.yml"
  "docker-compose-flare.yml"
  "docker-compose-Vaultwarden.yml"
  "docker-compose-discordautodelete.yml"
  "docker-compose-discordmusicbot.yml"
  "docker-compose-discordrss.yml"
)

# Backup Settings
backup_source="/root/Docker-Compose/"
backup_target="/mnt/Backup/PVE-Docker-LXC/"
num_cores=24

# Function to start containers
start_containers() {
    echo "Starting containers..."
    for file in "${files[@]}"; do
        docker compose -f "$dir_path$file" up -d
        echo "Started: $file"
    done
    echo "All containers are running."
}

# Function to stop containers
stop_containers() {
    echo "Stopping containers..."
    for file in "${files[@]}"; do
        docker compose -f "$dir_path$file" down
        echo "Stopped: $file"
    done
    echo "All containers have been stopped."
}

# Function to update containers
update_containers() {
    echo "Updating containers..."
    for file in "${files[@]}"; do
        docker compose -f "$dir_path$file" pull
        docker compose -f "$dir_path$file" up -d
        echo "Updated: $file"
    done
    echo "All containers are up to date."
}

# Function to backup Docker files
backup_containers() {
    timestamp=$(date "+%Y-%m-%d@%H.%M")
    backup_dir="$backup_target/$timestamp"
    mkdir -p "$backup_dir"
    log_file="$backup_dir/Logs.txt"

    echo "[$(date)] Stopping containers for backup..." | tee -a "$log_file"
    stop_containers >> "$log_file" 2>&1

    echo "[$(date)] Starting backup..." | tee -a "$log_file"

    for subdir in "$backup_source"/*/; do
        [ -d "$subdir" ] || continue
        subdir_name=$(basename "$subdir")
        start_time=$(date +%s)
        echo "[$(date)] Backing up: $subdir_name" | tee -a "$log_file"
        uncompressed_size=$(du -sh "$subdir" | awk '{print $1}')
        tar -cf - -C "$backup_source" "$subdir_name" | pigz -p "$num_cores" > "$backup_dir/$subdir_name.tar.gz"
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        compressed_size=$(du -sh "$backup_dir/$subdir_name.tar.gz" | awk '{print $1}')
        echo "[$(date)] Backup complete: $subdir_name in $duration sec (Before: $uncompressed_size, After: $compressed_size)" | tee -a "$log_file"
    done
    
    find "$backup_target" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
    echo "[$(date)] Backup complete." | tee -a "$log_file"

    echo "[$(date)] Restarting containers after backup..." | tee -a "$log_file"
    start_containers >> "$log_file" 2>&1
}

# Auto execution for crontab
if [[ "$1" == "backup" ]]; then
    backup_containers
    exit 0
fi
if [[ "$1" == "restart" ]]; then
    stop_containers
    start_containers
    exit 0
fi
if [[ "$1" == "update" ]]; then
    stop_containers
    update_containers
    exit 0
fi

# Display menu options if no arguments are provided
echo "Select an option:"
echo "1) Start Docker Containers"
echo "2) Stop Docker Containers"
echo "3) Update Docker Containers"
echo "4) Backup and Restart Containers"
echo "5) Exit"
read -p "Enter your choice: " choice

case $choice in
    1) start_containers ;;
    2) stop_containers ;;
    3) update_containers ;;
    4) backup_containers ;;
    5) exit 0 ;;
    *) echo "Invalid option" ;;
esac
