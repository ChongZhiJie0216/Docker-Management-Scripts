#!/bin/bash

# Docker Compose Files Directory
dir_path="/root/Docker/"

# Backup Settings
backup_source="/root/Docker/"
backup_target="/mnt/Backup/Alpine-Docker/"
num_cores=24

# Whitelist folders
declare -a whitelist_folders=("FileBrowser" "MariaDB" "Redis" "Nextcloud" "Gitea" "Alist")

# Function to check if a folder is whitelisted
is_whitelisted() {
    local folder_name="$1"
    for whitelisted in "${whitelist_folders[@]}"; do
        if [[ "$folder_name" == "$whitelisted" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to find Docker Compose folders based on whitelist
find_compose_folders() {
    local ordered_folders=()
    for folder_name in "${whitelist_folders[@]}"; do
        local folder_path="$dir_path$folder_name"
        if [[ -d "$folder_path" && ( -f "$folder_path/compose.yml" || -f "$folder_path/compose.yaml" ) ]]; then
            ordered_folders+=("$folder_path")
        fi
    done
    echo "${ordered_folders[@]}"
}

# Function to start containers in whitelist order
start_containers() {
    echo "Starting containers in order..."
    for folder in $(find_compose_folders); do
        compose_file="$folder/compose.yaml"
        [[ -f "$folder/compose.yml" ]] && compose_file="$folder/compose.yml"
        docker compose -f "$compose_file" up -d
        echo "Started: $folder"
    done
    echo "All containers are running."
}

# Function to stop containers in reverse whitelist order
stop_containers() {
    echo "Stopping containers in reverse order..."
    for (( idx=${#whitelist_folders[@]}-1 ; idx>=0 ; idx-- )); do
        folder_name="${whitelist_folders[idx]}"
        folder="$dir_path$folder_name"
        if [[ -d "$folder" && ( -f "$folder/compose.yml" || -f "$folder/compose.yaml" ) ]]; then
            compose_file="$folder/compose.yaml"
            [[ -f "$folder/compose.yml" ]] && compose_file="$folder/compose.yml"
            docker compose -f "$compose_file" down
            echo "Stopped: $folder"
        fi
    done
    echo "All containers have been stopped."
}

# Function to update containers
update_containers() {
    echo "Updating containers..."
    for folder in $(find_compose_folders); do
        compose_file="$folder/compose.yaml"
        [[ -f "$folder/compose.yml" ]] && compose_file="$folder/compose.yml"
        docker compose -f "$compose_file" pull
        docker compose -f "$compose_file" up -d
        echo "Updated: $folder"
    done
    echo "All containers are up to date."
}

# Function to backup Docker files
backup_containers() {
    timestamp=$(date "+%Y-%m-%d@%H.%M")
    backup_dir="$backup_target/$timestamp"
    mkdir -p "$backup_dir"
    log_file="$backup_dir/Logs.txt"

    echo "Stopping containers for backup..." | tee -a "$log_file"
    stop_containers

    echo "Starting backup..." | tee -a "$log_file"

    for folder_name in "${whitelist_folders[@]}"; do
        subdir="$backup_source$folder_name"
        [ -d "$subdir" ] || continue
        
        start_time=$(date +%s)
        echo "Backing up: $folder_name" | tee -a "$log_file"
        uncompressed_size=$(du -sh "$subdir" | awk '{print $1}')
        tar -cf - -C "$backup_source" "$folder_name" | pigz -p "$num_cores" > "$backup_dir/$folder_name.tar.gz"
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        compressed_size=$(du -sh "$backup_dir/$folder_name.tar.gz" | awk '{print $1}')
        echo "Backup complete: $folder_name in $duration sec (Before: $uncompressed_size, After: $compressed_size)" | tee -a "$log_file"
    done

    find "$backup_target" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
    echo "Backup complete." | tee -a "$log_file"

    echo "Restarting containers after backup..." | tee -a "$log_file"
    start_containers
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
