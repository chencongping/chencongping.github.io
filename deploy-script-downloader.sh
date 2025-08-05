#!/bin/bash

# 定义要下载的文件URL
FILE1="http://localhost/script/run-app-dev.sh"
FILE2="http://localhost/script/network.conf"
FILE3="http://localhost/script/Dockerfile"

# 定义本地文件名（从URL提取）
NAME1=$(basename "$FILE1")
NAME2=$(basename "$FILE2")
NAME3=$(basename "$FILE3")

# 下载函数
download_file() {
    local url=$1
    local filename=$2
    local overwrite=$3

    echo "准备下载: $url"

    # 检查文件是否存在且不需要覆盖
    if [ -f "$filename" ] && [ "$overwrite" = false ]; then
        echo "文件 $filename 已存在，跳过下载"
        return 0
    fi

    # 使用curl或wget下载
    if command -v curl &> /dev/null; then
        if curl -fL "$url" -o "$filename"; then
            echo "成功下载: $filename"
            # 为脚本添加执行权限
            if [[ "$filename" == *.sh ]]; then
                chmod +x "$filename"
                echo "已为 $filename 添加执行权限"
            fi
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget -q "$url" -O "$filename"; then
            echo "成功下载: $filename"
            # 为脚本添加执行权限
            if [[ "$filename" == *.sh ]]; then
                chmod +x "$filename"
                echo "已为 $filename 添加执行权限"
            fi
            return 0
        fi
    else
        echo "错误: 未找到curl或wget，请安装其中一个工具后重试"
        return 1
    fi

    echo "错误: 下载 $filename 失败"
    return 1
}

# 下载文件，第三个参数为true表示覆盖，false表示不覆盖
download_file "$FILE1" "$NAME1" true
download_file "$FILE2" "$NAME2" false
download_file "$FILE3" "$NAME3" true

echo "所有下载操作已完成"
exit 0