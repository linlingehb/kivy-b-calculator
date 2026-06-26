# Kivy Android APK 打包指南（Buildozer + WSL）

## 项目说明

本项目是一个基于 Kivy 开发的手机计算器，使用 Buildozer 打包为 Android APK。

- 项目路径：`C:\Users\Lenovo\PycharmProjects\PythonProject`
- 主程序文件：`main.py`
- Buildozer 配置：`buildozer.spec`
- WSL 打包脚本：`build_apk_wsl.sh`

---

## 为什么必须用 WSL / Linux？

Buildozer 依赖 Android SDK、NDK、python-for-android 等工具链，**官方仅支持在 Linux 环境运行**。
在 Windows 上需要通过 **WSL（Windows Subsystem for Linux）** 来构建 APK。

> 如果你尚未安装 WSL，请在 PowerShell（管理员）中运行：
> ```powershell
> wsl --install -d Ubuntu
> ```
> 安装完成后重启电脑，并按照提示设置 Ubuntu 用户名和密码。

---

## 快速打包步骤

### 1. 打开 WSL 终端

在 Windows 中按 `Win + R`，输入：

```
wsl
```

然后按回车，进入 WSL 的 Ubuntu 终端。

### 2. 进入项目目录

在 WSL 中，Windows 的 `C:\` 盘挂载到 `/mnt/c/`，所以项目路径为：

```bash
cd /mnt/c/Users/Lenovo/PycharmProjects/PythonProject
```

### 3. 赋予脚本执行权限并运行

```bash
chmod +x build_apk_wsl.sh
./build_apk_wsl.sh
```

### 4. 等待构建完成

- **首次打包**会下载 Android SDK、NDK、python-for-android 等依赖，
  根据网络情况可能需要 **30 分钟到数小时**，请耐心等待。
- 构建完成后，APK 文件会出现在 Windows 项目目录的 `bin/` 文件夹中：
  ```
  C:\Users\Lenovo\PycharmProjects\PythonProject\bin\*.apk
  ```

### 5. 安装 APK 到手机

将生成的 APK 传输到 Android 手机，点击安装即可。
如果系统提示“未知来源应用”，请在设置中允许安装。

---

## 手动打包（不使用脚本）

如果你希望手动执行，而不是使用脚本，可以按以下步骤操作：

```bash
# 进入项目目录
cd /mnt/c/Users/Lenovo/PycharmProjects/PythonProject

# 安装系统依赖
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv build-essential git zip unzip \
    openjdk-17-jdk autoconf automake libtool libtool-bin pkg-config zlib1g-dev \
    libncurses-dev libtinfo6 libffi-dev libssl-dev libsqlite3-dev libbz2-dev \
    libreadline-dev libgdbm-dev libgdbm-compat-dev llvm liblzma-dev xclip \
    python3-virtualenv

# 安装 buildozer 和 cython
pip3 install --user --upgrade buildozer cython
export PATH="$HOME/.local/bin:$PATH"

# 构建 debug APK
buildozer -v android debug
```

---

## GitHub Actions 云端打包（无需本机 WSL）

如果你不想在本地配置 WSL，或者 WSL 构建遇到问题，可以使用 GitHub Actions 在云端自动打包。
项目已配置好工作流文件：`.github/workflows/build-apk.yml`。

### 使用步骤

1. **将项目上传到 GitHub 仓库**

   在 GitHub 上新建一个仓库（例如 `my-kivy-calculator`），然后把项目代码推送到仓库：

   ```bash
   # 在项目目录中执行（PowerShell 或 Git Bash）
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/你的用户名/my-kivy-calculator.git
   git push -u origin main
   ```

2. **触发构建**

   - 推送代码到 `main` 或 `master` 分支会自动触发构建。
   - 也可以手动触发：进入 GitHub 仓库 → `Actions` → `Build Kivy APK with Buildozer` → `Run workflow`。

3. **下载 APK**

   构建完成后，进入 GitHub 仓库的 `Actions` 页面，点击最近的运行记录，在页面底部找到 `Artifacts` 区域，下载 `kivy-calculator-apk` 压缩包，解压后即可得到 `.apk` 文件。

### 注意事项

- GitHub Actions 免费账户的 Linux 运行器最长运行 **6 小时**，首次构建通常会下载 Android SDK/NDK/python-for-android，可能需要 **30 分钟到 2 小时**。
- 工作流已配置缓存 `.buildozer` 目录，后续构建会更快。
- 如果构建失败，可以在 GitHub Actions 日志中查看详细错误信息。

---

## 常见问题

### 1. 在 /mnt/c 下构建很慢或出错

**原因**：在 Windows 文件系统（`/mnt/c`）上运行 Buildozer 可能遇到权限、符号链接等问题，导致构建失败或极慢。

**建议**：本脚本会自动将项目复制到 WSL 的 Linux 文件系统（`~/.buildozer_builds/`）中构建，完成后再复制回 Windows。如果你手动打包，也建议这样做。

### 2. 首次下载依赖失败或中断

**原因**：Buildozer 需要下载 Android SDK、NDK、python-for-android 等，网络不稳定会中断。

**建议**：
- 确保网络稳定，必要时使用代理或加速器。
- 如果中断，重新运行 `./build_apk_wsl.sh` 即可，脚本会重新下载。

### 3. `buildozer` 命令找不到

在 WSL 中执行：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

或者将以下命令添加到 `~/.bashrc`：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 4. Java 版本问题

Buildozer 需要 Java 17（OpenJDK 17）。如果系统安装了其他版本，建议安装 OpenJDK 17：

```bash
sudo apt-get install -y openjdk-17-jdk
sudo update-alternatives --config java
```

然后选择 `java-17-openjdk` 对应的编号。

### 5. 应用图标 / 启动图

当前项目未配置图标和启动图。Buildozer 会使用默认图标。
如需自定义，可在 `buildozer.spec` 中配置：

```ini
icon.filename = %(source.dir)s/data/icon.png
presplash.filename = %(source.dir)s/data/presplash.png
```

### 6. 安装 APK 后崩溃或黑屏

- 检查 `main.py` 是否有仅在桌面运行时才支持的代码。
- 在 Kivy 中，可以通过 `from kivy.utils import platform` 判断当前平台：

```python
from kivy.utils import platform
if platform != 'android':
    Window.size = (360, 640)
```

本项目的 `main.py` 已按此方式处理，确保在手机和电脑上都能正常运行。

### 7. WSL 中提示 `E: Unable to locate package python3-jnius`

**原因**：Ubuntu 24.04（Noble）默认软件源中没有 `python3-jnius` 这个包，且 `libncurses5-dev` / `libncursesw5-dev` 已被 `libncurses-dev` 取代。

**建议**：请确保使用的是最新版的 `build_apk_wsl.sh`。新版脚本已替换为 Ubuntu 24.04 可用的依赖包：
- 删除 `python3-jnius`
- 将 `libncurses5-dev` 和 `libncursesw5-dev` 替换为 `libncurses-dev`
- 增加 `automake`、`libtool-bin`、`libtinfo6`、`libgdbm-dev`、`libgdbm-compat-dev`、`xclip`

如果你使用旧版脚本，直接重新下载/覆盖即可。

### 8. WSL 中提示 `error: externally-managed-environment`

**原因**：Ubuntu 24.04+ 启用了 PEP 668 保护，禁止直接向系统 Python 安装 pip 包。

**建议**：新版 `build_apk_wsl.sh` 已改用 Python 虚拟环境安装 Buildozer，可自动绕过此限制。请使用最新版脚本重新运行即可。

如果你手动打包，需要先创建虚拟环境：

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install buildozer cython
buildozer -v android debug
```

### 9. 下载/克隆时提示 `GnuTLS recv error (-110)`、`Connection reset by peer` 或 `Remote end closed connection`

**原因**：Buildozer 需要从 GitHub 克隆 `python-for-android`，并下载 Android SDK/NDK 等。如果 WSL 中配置了指向 `127.0.0.1:7890` 之类的代理，在 WSL2 里 `127.0.0.1` 指向的是 WSL 自身，而不是 Windows 主机，导致代理无法正常工作。

**建议**：新版 `build_apk_wsl.sh` 已内置代理自动检测，会用 `curl` 实际测试代理能否访问 GitHub，而不是只测试端口：
- 如果当前代理可用，继续使用；
- 如果当前代理不可用，会尝试自动发现 Windows 主机 IP 上的常见代理端口（如 `7890`）。发现逻辑依次为：
  1. 你通过 `WSL_HOST_IP` 环境变量指定的 IP
  2. `ip route | grep default` 拿到的默认网关（通常最可靠）
  3. `/etc/resolv.conf` 里的第一个 `nameserver`
- 如果仍不可用，会提示你手动设置，不再盲目取消代理。

**手动排查步骤**：

1. 先确认 Windows 主机在 WSL 中的 IP。推荐用默认网关：

```bash
ip route | grep default
# 输出示例：default via 172.21.224.1 dev eth0
# 那么 Windows 主机 IP 就是 172.21.224.1
```

也可以用 `/etc/resolv.conf`：

```bash
cat /etc/resolv.conf | grep nameserver
```

2. 验证代理是否真的能访问 GitHub：

```bash
# 把 <Windows_IP> 换成上一步拿到的 IP
curl -I -x http://<Windows_IP>:7890 https://github.com
```

正常应返回 `HTTP/2 200` 或 `HTTP/1.1 200`。如果返回 `Connection refused`、`Connection reset` 或超时，说明：
- Windows 代理软件没有开启「允许局域网连接」/「Allow LAN」；
- 或者 Windows 防火墙阻止了 WSL 访问该端口；
- 或者端口号不是 `7890`（常见代理端口还有 `1080`、`10808`、`7897` 等）。

3. 设置代理并运行脚本：

```bash
export WSL_HOST_IP=<Windows_IP>
# 如果你的代理端口不是 7890，可以设置 PROXY_PORT
export PROXY_PORT=7890
./build_apk_wsl.sh
```

或者显式指定代理：

```bash
export https_proxy=http://<Windows_IP>:7890
export http_proxy=http://<Windows_IP>:7890
./build_apk_wsl.sh
```

或者用更直接的方式强制指定代理（跳过测试）：

```bash
FORCE_PROXY=http://<Windows_IP>:7890 ./build_apk_wsl.sh
```

注意：你的代理软件需要开启「允许局域网连接」或「Allow LAN」，WSL 才能访问到它。

---

## 配置说明

`buildozer.spec` 中的关键配置：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `title` | 手机计算器 | 应用名称 |
| `package.name` | calculator | 应用包名（短名） |
| `package.domain` | com.example | 包域名 |
| `requirements` | python3,kivy | 依赖库 |
| `orientation` | portrait | 竖屏 |
| `android.api` | 33 | 目标 Android API |
| `android.minapi` | 24 | 最低 Android API（Android 7.0） |
| `android.archs` | arm64-v8a, armeabi-v7a | 构建的 CPU 架构 |

---

## 参考文档

- [Buildozer 官方文档](https://buildozer.readthedocs.io/)
- [python-for-android 文档](https://python-for-android.readthedocs.io/)
- [Kivy 官方文档](https://kivy.org/doc/stable/)

---

## 文件清单

```
PythonProject/
├── main.py                 # 主程序（手机计算器）
├── buildozer.spec          # Buildozer 配置文件
├── build_apk_wsl.sh        # WSL 一键打包脚本
├── BUILD_APK_README.md     # 本说明文档
├── .github/
│   └── workflows/
│       └── build-apk.yml     # GitHub Actions 云端打包工作流
├── bin/                    # 生成的 APK 输出目录
└── ...
```
