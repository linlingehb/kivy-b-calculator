#!/bin/bash
# Buildozer APK 打包脚本（WSL 环境）
# 使用方式：在 WSL 终端中 cd 到项目目录后执行：
#   chmod +x build_apk_wsl.sh
#   ./build_apk_wsl.sh

set -e  # 遇到错误立即退出

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 项目路径（Windows 项目通过 WSL 挂载路径访问）
WINDOWS_PROJECT_DIR="/mnt/c/Users/Lenovo/PycharmProjects/PythonProject"
# WSL 内部构建目录（推荐在 Linux 文件系统中构建，避免 /mnt/c 权限问题）
BUILD_DIR="$HOME/.buildozer_builds/python_project"
# APK 输出目录
APK_OUTPUT_DIR="$WINDOWS_PROJECT_DIR/bin"

# 检查是否在 WSL 中运行
if [[ -z "$WSL_DISTRO_NAME" ]] && [[ -z "$WSL_INTEROP" ]]; then
    echo -e "${RED}错误：此脚本必须在 WSL (Windows Subsystem for Linux) 中运行。${NC}"
    echo "请打开 WSL 终端，然后重新执行本脚本。"
    exit 1
fi

# 代理检测与自动修复（WSL2 中 127.0.0.1 指向 WSL 自身，不是 Windows 主机）
# 使用 curl 实际测试代理能否访问 GitHub，而不是只测试 TCP 端口

check_proxy_working() {
    local proxy_url="$1"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" -x "$proxy_url" --max-time 8 https://github.com 2>/dev/null || echo "000")
    [[ "$status" == "200" || "$status" == "301" || "$status" == "302" ]]
}

# 获取可能的 Windows 主机 IP 列表（按可靠性排序）
get_windows_host_ips() {
    local ips=""

    # 1. 用户显式指定
    if [[ -n "$WSL_HOST_IP" ]]; then
        ips="$WSL_HOST_IP"
    fi

    # 2. 默认网关（最可靠，WSL2 默认路由指向 Windows 主机）
    local gateway
    gateway=$(ip route 2>/dev/null | awk '/^default/ {print $3; exit}')
    if [[ -n "$gateway" ]] && [[ "$gateway" != "$ips" ]]; then
        [[ -n "$ips" ]] && ips="$ips $gateway" || ips="$gateway"
    fi

    # 3. /etc/resolv.conf 里的 nameserver
    local ns
    ns=$(grep -m1 nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}')
    if [[ -n "$ns" ]] && [[ "$ns" != "$ips" ]]; then
        [[ -n "$ips" ]] && ips="$ips $ns" || ips="$ns"
    fi

    echo "$ips"
}

detect_and_fix_proxy() {
    local common_port="${PROXY_PORT:-7890}"
    local proxy_set=""
    local original_proxy="${https_proxy:-${http_proxy:-}}"

    # 如果用户强制指定了代理，直接使用
    if [[ -n "$FORCE_PROXY" ]]; then
        echo -e "${YELLOW}>>> 使用用户强制指定的代理: $FORCE_PROXY${NC}"
        proxy_set="$FORCE_PROXY"
    fi

    # 如果用户有当前代理设置，先检查是否可用
    if [[ -z "$proxy_set" ]] && [[ -n "$original_proxy" ]]; then
        echo -e "${YELLOW}>>> 检测到代理设置: $original_proxy${NC}"
        echo -e "${YELLOW}>>> 测试代理能否访问 GitHub...${NC}"
        if check_proxy_working "$original_proxy"; then
            echo -e "${GREEN}>>> 当前代理可用。${NC}"
            proxy_set="$original_proxy"
        else
            echo -e "${RED}警告：当前代理 $original_proxy 无法正确访问 GitHub。${NC}"
            echo "    常见原因：WSL2 里 127.0.0.1/localhost 指向的是 WSL 本身，而非 Windows 主机。"
        fi
    fi

    # 尝试自动发现 Windows 主机上的代理
    if [[ -z "$proxy_set" ]]; then
        echo -e "${YELLOW}>>> 尝试自动发现 Windows 主机代理（端口 $common_port）...${NC}"
        local windows_ip
        for windows_ip in $(get_windows_host_ips); do
            echo -e "${YELLOW}    测试 http://$windows_ip:$common_port${NC}"
            if check_proxy_working "http://$windows_ip:$common_port"; then
                echo -e "${GREEN}>>> 发现可用代理: http://$windows_ip:$common_port${NC}"
                proxy_set="http://$windows_ip:$common_port"
                break
            fi
        done
    fi

    # 应用代理
    if [[ -n "$proxy_set" ]]; then
        export http_proxy="$proxy_set"
        export https_proxy="$proxy_set"
        export HTTP_PROXY="$proxy_set"
        export HTTPS_PROXY="$proxy_set"
        # 同时设置 git 全局代理，因为 Buildozer 内部调用的 git 可能只读 git 配置
        git config --global http.proxy "$proxy_set" 2>/dev/null || true
        git config --global https.proxy "$proxy_set" 2>/dev/null || true
        return 0
    fi

    # 没有找到可用代理
    echo -e "${YELLOW}>>> 未找到可用代理。${NC}"
    echo "    如果你在中国大陆，后续下载 GitHub/Android 资源大概率会失败。"
    echo "    请手动设置 Windows 主机 IP 后再运行脚本："
    echo ""
    echo "      # 查看 Windows 主机 IP（推荐方法）"
    echo "      ip route | grep default"
    echo ""
    echo "      # 然后执行"
    echo "      export WSL_HOST_IP=<Windows_IP>"
    echo "      ./build_apk_wsl.sh"
    echo ""
    echo "    或者显式指定代理："
    echo "      export https_proxy=http://<Windows_IP>:7890"
    echo "      export http_proxy=http://<Windows_IP>:7890"
    echo "      ./build_apk_wsl.sh"
    echo ""
    echo "    也可以强制使用某个代理（跳过测试）："
    echo "      FORCE_PROXY=http://<IP>:7890 ./build_apk_wsl.sh"
    echo ""
    echo "    注意：Windows 代理软件必须开启「允许局域网连接」或「Allow LAN」。"
}

echo -e "${GREEN}=== Kivy Buildozer APK 打包脚本 ===${NC}"
echo "Windows 项目目录: $WINDOWS_PROJECT_DIR"
echo "WSL 构建目录:     $BUILD_DIR"

# 0. 自动检测/修复代理
detect_and_fix_proxy

# 1. 清理并创建 WSL 内部构建目录
echo -e "${YELLOW}>>> 准备 WSL 构建目录...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 2. 复制项目文件到 WSL 内部目录（避免在 /mnt/c 下构建）
echo -e "${YELLOW}>>> 复制项目到 WSL 构建目录...${NC}"
# 使用 cp -a 保留权限，但排除 Python 虚拟环境和 .buildozer 目录
cp -a "$WINDOWS_PROJECT_DIR/"*.py "$BUILD_DIR/" 2>/dev/null || true
cp -a "$WINDOWS_PROJECT_DIR/buildozer.spec" "$BUILD_DIR/"
cp -a "$WINDOWS_PROJECT_DIR/"*.kv "$BUILD_DIR/" 2>/dev/null || true
cp -a "$WINDOWS_PROJECT_DIR/"*.png "$BUILD_DIR/" 2>/dev/null || true
cp -a "$WINDOWS_PROJECT_DIR/"*.jpg "$BUILD_DIR/" 2>/dev/null || true
cp -a "$WINDOWS_PROJECT_DIR/"data "$BUILD_DIR/" 2>/dev/null || true

# 3. 进入构建目录
cd "$BUILD_DIR"

# 临时保存并取消 git 全局代理（Buildozer 内部会调用 git，避免错误代理干扰）
ORIG_GIT_HTTP_PROXY=$(git config --global http.proxy 2>/dev/null || true)
ORIG_GIT_HTTPS_PROXY=$(git config --global https.proxy 2>/dev/null || true)
restore_git_proxy() {
    [[ -n "$ORIG_GIT_HTTP_PROXY" ]] && git config --global http.proxy "$ORIG_GIT_HTTP_PROXY"
    [[ -n "$ORIG_GIT_HTTPS_PROXY" ]] && git config --global https.proxy "$ORIG_GIT_HTTPS_PROXY"
}
trap restore_git_proxy EXIT
git config --global --unset http.proxy 2>/dev/null || true
git config --global --unset https.proxy 2>/dev/null || true

# 4. 更新系统包并安装必要依赖
echo -e "${YELLOW}>>> 检查并安装系统依赖...${NC}"
sudo apt-get update -y
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    build-essential \
    git \
    zip \
    unzip \
    openjdk-17-jdk \
    autoconf \
    automake \
    libtool \
    libtool-bin \
    pkg-config \
    zlib1g-dev \
    libncurses-dev \
    libtinfo6 \
    libffi-dev \
    libssl-dev \
    libsqlite3-dev \
    libbz2-dev \
    libreadline-dev \
    libgdbm-dev \
    libgdbm-compat-dev \
    llvm \
    liblzma-dev \
    xclip \
    python3-virtualenv

# 5. 检查 Python 版本
echo -e "${YELLOW}>>> Python 版本: ${NC}"
python3 --version

# 6. 创建 Python 虚拟环境（避免 Ubuntu 24.04 的 PEP 668 externally-managed-environment 限制）
VENV_DIR="$BUILD_DIR/.venv"
echo -e "${YELLOW}>>> 创建 Python 虚拟环境: $VENV_DIR${NC}"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# 7. 在虚拟环境中安装/升级 buildozer 和 cython
echo -e "${YELLOW}>>> 在虚拟环境中安装 buildozer...${NC}"
pip install --upgrade pip setuptools wheel
pip install --upgrade buildozer cython

# 8. 确保 buildozer 可用
if ! command -v buildozer &> /dev/null; then
    echo -e "${RED}错误：buildozer 命令未找到，请检查虚拟环境安装路径。${NC}"
    exit 1
fi

echo -e "${YELLOW}>>> Buildozer 版本: ${NC}"
buildozer --version

# 9. 清理旧构建（可选）
echo -e "${YELLOW}>>> 清理旧构建文件...${NC}"
rm -rf .buildozer bin

# 10. 运行 Buildozer 打包（debug APK）
echo -e "${GREEN}>>> 开始构建 APK...${NC}"
echo -e "${YELLOW}注意：首次构建会下载 Android SDK/NDK/python-for-android，可能需要 30 分钟到数小时，请耐心等待。${NC}"
buildozer -v android debug

# 11. 检查 APK 是否生成
APK_FILE=$(find "$BUILD_DIR/bin" -name '*.apk' -print -quit)
if [[ -z "$APK_FILE" ]]; then
    echo -e "${RED}错误：未找到生成的 APK 文件。${NC}"
    exit 1
fi

echo -e "${GREEN}>>> APK 生成成功: $APK_FILE${NC}"

# 12. 复制 APK 回 Windows 项目目录
mkdir -p "$APK_OUTPUT_DIR"
cp -a "$APK_FILE" "$APK_OUTPUT_DIR/"
echo -e "${GREEN}>>> APK 已复制到: $APK_OUTPUT_DIR${NC}"
ls -lh "$APK_OUTPUT_DIR/"*.apk

echo -e "${GREEN}=== 打包完成 ===${NC}"
echo "生成的 APK 文件位于: $APK_OUTPUT_DIR"
echo "你可以直接在 Android 手机上安装该 APK 进行测试。"
