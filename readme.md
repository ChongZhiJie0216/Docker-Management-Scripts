# Docker Management Scripts

## Introduction

This project includes two Bash scripts for managing Docker Compose containers. It provides functionalities for starting, stopping, updating, and backing up containers, suitable for different Docker directory structures.

## Directory Structure

- **Script 1**: Manages specific `docker-compose.yml` files located in `/root/Docker-Compose/`.
- **Script 2**: Manages the `/mnt/SSD/Docker/` directory and supports a whitelist mechanism, only managing specific Docker services.

## Dependencies

Ensure the following tools are installed:

- `docker`
- `docker-compose`
- `pigz` (for multi-threaded backup compression)
- `tar` (for archiving backups)
- `cron` (for scheduling automated tasks)

Install the required dependencies using the following command (for Debian/Ubuntu):

```sh
sudo apt update && sudo apt install -y docker.io docker-compose pigz tar cron
```

## Usage

### 1. Running the Scripts

Run the script using the following command:

```sh
bash DockerCompose_Script1.bash
```

or

```sh
bash DockerCompose_Script1.bash
```

If no parameters are provided, an interactive menu will appear, allowing the user to choose an operation.

### 2. Command-Line Parameters

Both scripts support the same command-line parameters:

- `backup` - Backup Docker configuration and restart containers
- `restart` - Restart all Docker containers
- `update` - Update all Docker containers

Example:

```sh
bash DockerCompose_Script1.bash backup
bash DockerCompose_Script1.bash update
```

### 3. Automated Backups (Optional)

You can set up a `cron` job to run backups periodically, for example, every day at 2 AM:

```sh
crontab -e
```

Add the following line:

```sh
0 2 * * * /path/to/DockerCompose_Script1.bash backup
0 2 * * * /path/to/DockerCompose_Script2.bash backup
```

## Main Features

### 1. Start Containers

```sh
bash DockerCompose_Script1.bash
# Select "1) Start Docker Containers"
```

The script iterates through predefined Docker Compose files and starts them using `docker-compose up -d`.

### 2. Stop Containers

```sh
bash DockerCompose_Script1.bash
# Select "2) Stop Docker Containers"
```

The script stops all defined containers using `docker-compose down`.

### 3. Update Containers

```sh
bash DockerCompose_Script1.bash update
```

Pulls the latest images and restarts all Docker Compose services.

### 4. Backup Container Data

```sh
bash DockerCompose_Script1.bash backup
```

The script:

- Stops all containers
- Backs up `docker-compose.yml` and related data
- Restarts all containers
- Retains backups for only the last 7 days

### 5. Filter Specific Services (Only for `script2.sh`)

`script2.sh` allows specifying a **whitelist**, managing only certain services (e.g., `Cloudflare` and `ollama`).

Modify the `whitelist_folders` variable to customize managed services:

```sh
whitelist_folders=("Cloudflare" "ollama" "new_service")
```

## Conclusion

This project provides an efficient way to manage multiple Docker Compose containers, supporting automated updates and backups, making it suitable for server environments.
