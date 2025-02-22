#!/bin/bash

# 读取环境变量（如果未提供，则使用默认值）
dir_path="${DOCKER_DIR:-/root/Docker/}"                   # Docker Compose 文件目录
backup_source="${BACKUP_SOURCE:-/root/Docker/}"           # 备份源目录
backup_target="${BACKUP_TARGET:-/mnt/Backup/Alpine-Docker/}" # 备份目标目录
num_cores="${NUM_CORES:-24}"                              # 压缩时使用的 CPU 核心数

# 定义白名单（可通过环境变量自定义）
IFS=',' read -r -a whitelist_folders <<< "${WHITELIST_FOLDERS:-FileBrowser,MariaDB,Redis,Nextcloud,Gitea,Alist}"

# 查找白名单中的 Docker Compose 文件夹
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

# 启动容器
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

# 停止容器（按照白名单的**逆序**）
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

# 更新容器
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

# 备份容器数据
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

# 解析参数
if [[ "$1" == "backup" ]]; then
    backup_containers
    exit 0
elif [[ "$1" == "restart" ]]; then
    stop_containers
    start_containers
    exit 0
elif [[ "$1" == "update" ]]; then
    stop_containers
    update_containers
    exit 0
fi

# 显示菜单
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
