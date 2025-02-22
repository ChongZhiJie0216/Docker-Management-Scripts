# 使用 Alpine 作为基础镜像
FROM alpine:latest

# 安装必要工具
RUN apk add --no-cache docker-cli pigz bash tar

# 设置默认环境变量
ENV DOCKER_DIR=""
ENV BACKUP_SOURCE=""
ENV BACKUP_TARGET=""
ENV NUM_CORES=24
ENV WHITELIST_FOLDERS=""

# 复制脚本
WORKDIR /app
COPY DockerCompose_Script2_Docker.bash /app/DockerCompose_Script2_Docker.bash
RUN chmod +x /app/DockerCompose_Script2_Docker.bash

# 运行时挂载 Docker 套接字
VOLUME /var/run/docker.sock

# 入口点
ENTRYPOINT ["/app/DockerCompose_Script2_Docker.bash"]
