#!/bin/bash
set -e
version=run-app-dev.1.0.7

echo "---------------------------------------------------------"
echo "开始获取网络信息"
echo "---------------------------------------------------------"
# 配置文件路径（内容格式：IP:端口，如192.168.100.202:10003）
CONFIG_FILE="network.conf"
# 检查配置文件有效性
check_config() {
    # 检查配置文件是否存在
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "错误：配置文件 '$CONFIG_FILE' 不存在" >&2
        return 1
    fi

    # 检查配置文件是否为空
    if [ ! -s "$CONFIG_FILE" ]; then
        echo "错误：配置文件 '$CONFIG_FILE' 为空" >&2
        return 1
    fi

    # 获取第一行有效配置（排除注释和空行）
    local config_line=$(grep -vE '^#|^$' "$CONFIG_FILE" | head -n 1)

    # 检查是否有有效配置行
    if [ -z "$config_line" ]; then
        echo "错误：配置文件 '$CONFIG_FILE' 中没有有效的配置内容（非注释、非空行）" >&2
        return 1
    fi

    # 检查配置行格式是否正确（至少包含一个冒号分隔符）
    if [[ "$config_line" != *":"* ]]; then
        echo "错误：配置文件格式不正确。有效配置行应使用冒号 ':' 分隔字段" >&2
        echo "示例格式：字段1:字段2:字段3（如：2025_ai_agent_infrastructure_network:192.168.100.201:10002）" >&2
        return 1
    fi

    # 所有检查通过
    return 0
}

get_config_field() {
    local field_num="$1"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "错误：配置文件 $CONFIG_FILE 不存在" >&2
        return 1
    fi
    # 检查参数是否为正整数
    if ! [[ "$field_num" =~ ^[1-9][0-9]*$ ]]; then
        echo "错误：参数必须是正整数" >&2
        return 1
    fi

    # 检查配置文件有效性
    if ! check_config; then
        return 1
    fi

    # 获取第一行有效配置
    local config_line=$(grep -vE '^#|^$' "$CONFIG_FILE" | head -n 1)

    # 计算字段数量
    local field_count=$(echo "$config_line" | tr ':' '\n' | wc -l)

    # 检查字段数量是否足够
    if [ "$field_count" -lt "$field_num" ]; then
        echo "错误：配置文件中字段数量（$field_count）小于请求的字段编号（$field_num）" >&2
        return 1
    fi

    # 提取并返回对应字段的值
    local result=$(echo "$config_line" | cut -d':' -f"$field_num")
    echo "$result"
    return 0
}

NETWORK_NAME=$(get_config_field 1)
APP_IP=$(get_config_field 2)
HOST_APP_PORT=$(get_config_field 3)

echo "---------------------------------------------------------"
echo "获取网络信息"
echo "NETWORK_NAME: ${NETWORK_NAME}"
echo "APP_IP: ${APP_IP}"
echo "HOST_APP_PORT: ${HOST_APP_PORT}"
echo "---------------------------------------------------------"
mvn clean package -DskipTests

env=$(echo "$(basename "$0")" | cut -d '-' -f 3 | sed 's/\.sh$//')
echo "run app script version:${version}"
echo "---------------------------------------------------------"
echo "开始应用和版本信息"
echo "---------------------------------------------------------"
# 从pom.xml中读取属性（使用mvn命令，无需依赖xmllint）
get_pom_property() {
    # 调用maven帮助命令获取指定属性值
    mvn help:evaluate -Dexpression="$1" -q -DforceStdout
}

# 读取应用名称（artifactId）
APP_NAME=$(get_pom_property "project.artifactId")
if [ -z "$APP_NAME" ]; then
    echo "错误：无法从pom.xml中读取artifactId"
    exit 1
fi

# 读取版本号（version）
APP_VERSION=$(get_pom_property "project.version")
if [ -z "$APP_VERSION" ]; then
    echo "错误：无法从pom.xml中读取version"
    exit 1
fi
IMAGE_TAG="${APP_NAME}:${APP_VERSION}"

echo "---------------------------------------------------------"
echo "应用和版本信息"
echo "应用名称: $APP_NAME"
echo "版本号: $APP_VERSION"
echo "镜像标签: $IMAGE_TAG"
echo "---------------------------------------------------------"

echo "---------------------------------------------------------"
echo "开始获取应用端口"
echo "---------------------------------------------------------"

# 从application.yml读取服务端口（兼容空格和注释）
get_application_port() {
    local yml_path="src/main/resources/application-${env}.yml"
    if [ ! -f "$yml_path" ]; then
        echo "警告：未找到配置文件 $yml_path" >&2
        echo "8080"
        return 0
    fi

    # 优化匹配逻辑：忽略注释、兼容不同缩进和空格
    local port=$(awk '
        # 跳过注释行
        /^[[:space:]]*#/ { next }
        # 找到server节点
        /^[[:space:]]*server:[[:space:]]*$/ { in_server=1; next }
        # 离开server节点（遇到下一个顶级节点）
        in_server && /^[^[:space:]]/ { in_server=0; next }
        # 在server节点内查找port
        in_server && /^[[:space:]]*port:[[:space:]]*[0-9]+/ {
            gsub(/[^0-9]/, "", $0)  # 只保留数字
            print $0
            exit
        }
    ' "$yml_path")

    if [ -z "$port" ] || ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "警告：无法从 $yml_path 中读取有效的server.port" >&2
        echo 8080
        return 0
    fi
    echo "$port"
}

# 从Dockerfile读取暴露的端口（兼容多种格式）
get_docker_expose_port() {
    if [ ! -f "Dockerfile" ]; then
        echo "错误：未找到Dockerfile" >&2
        exit 1
    fi

    # 提取EXPOSE后的端口（忽略注释和多余空格）
    local port=$(awk '
        # 跳过注释行
        /^[[:space:]]*#/ { next }
        # 匹配EXPOSE指令，提取数字
        /^[[:space:]]*EXPOSE[[:space:]]+[0-9]+/ {
            gsub(/[^0-9]/, "", $0)  # 只保留数字
            print $0
            exit
        }
    ' Dockerfile)

    if [ -z "$port" ] || ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "错误：无法从Dockerfile中读取有效的EXPOSE端口" >&2
        exit 1
    fi
    echo "$port"
}

# 获取并验证端口
echo -e "\n正在读取端口配置..."
APP_PORT=$(get_application_port)
echo "从application.yml读取到端口：$APP_PORT"

DOCKER_EXPOSE_PORT=$(get_docker_expose_port)
echo "从Dockerfile读取到端口：$DOCKER_EXPOSE_PORT"

if [ "$APP_PORT" != "$DOCKER_EXPOSE_PORT" ]; then
    echo "错误：application.yml的端口($APP_PORT)与Dockerfile的EXPOSE端口($DOCKER_EXPOSE_PORT)不一致" >&2
    exit 1
else
    echo "端口配置一致：$APP_PORT"
fi

echo "---------------------------------------------------------"
echo "获取端口:"
echo "最终应用端口：${APP_PORT}"
echo "最终暴露端口：${DOCKER_EXPOSE_PORT}"
echo "---------------------------------------------------------"

# 检查本地target目录是否存在JAR文件
check_build_artifact() {
    if [ ! -d "./target" ]; then
        echo "错误：未找到target目录，请先在本地执行 'mvn package -DskipTests' 打包"
        exit 1
    fi

    JAR_FILES=$(ls ./target/*.jar 2>/dev/null | wc -l)
    if [ $JAR_FILES -eq 0 ]; then
        echo "错误：target目录下未找到JAR文件，请先在本地执行 'mvn package -DskipTests' 打包"
        exit 1
    fi
}

# 检查构建产物
check_build_artifact

# 打印构建命令
echo -e "---------------------------------------------------------"
echo "构建命令:"
echo "docker build -t ${IMAGE_TAG} ."
echo "---------------------------------------------------------"

# 直接构建镜像（不使用任何挂载）
docker build -t "${IMAGE_TAG}" .
echo -e "\n镜像构建成功: ${IMAGE_TAG}"
docker ps -a | grep ${APP_NAME} | awk '{print $1}' | xargs docker stop || true
docker ps -a | grep ${APP_NAME} | awk '{print $1}' | xargs docker rm || true
docker run -d -p ${HOST_APP_PORT}:${DOCKER_EXPOSE_PORT} --name ${APP_NAME} \
  --network "$NETWORK_NAME" \
  --restart=always \
  -e "SPRING_PROFILES_ACTIVE=dev" ${IMAGE_TAG}
echo -e "\n应用运行成功: ${IMAGE_TAG}"
