#!/bin/bash

# Debian 系统配置自动化脚本
# 需要 root 权限运行

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 询问函数
ask_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -p "$(echo -e ${YELLOW}${prompt}${NC}) [y/n]: " response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo -e "${RED}请输入 y 或 n${NC}" ;;
        esac
    done
}

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then 
    log_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 获取实际用户名
REAL_USER=${SUDO_USER:-$USER}

log_info "开始 Debian 系统配置..."

# ========== 2.1 软件源 ==========
log_info "配置软件源..."
apt install -y nala
nala fetch
nala update

# ========== 2.2 桌面环境与常用软件 ==========
log_info "安装桌面环境与常用软件..."
nala install -y \
  gdm3 \
  gnome-terminal \
  flatpak \
  fonts-noto-cjk \
  git \
  ibus-libpinyin \
  preload \
  adb \
  fastboot \
  thermald

log_info "清理不必要的软件包..."
nala remove -y fortune-* debian-reference-* malcontent-* || true
nala autoremove -y --purge
nala update

# ========== 2.3 Flatpak ==========
log_info "配置 Flatpak..."
sudo -u $REAL_USER flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo --user
sudo -u $REAL_USER flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub --user
sudo -u $REAL_USER flatpak update --user -y

log_info "安装 Flatpak 软件..."
sudo -u $REAL_USER flatpak install --user -y flathub \
  com.github.tchx84.Flatseal \
  io.gitlab.librewolf-community \
  org.libreoffice.LibreOffice \
  net.cozic.joplin_desktop \
  io.github.ungoogled_software.ungoogled_chromium \
  net.agalwood.Motrix \
  org.gimp.GIMP \
  com.dec05eba.gpu_screen_recorder \
  com.mattjakeman.ExtensionManager \
  org.localsend.localsend_app \
  com.cherry_ai.CherryStudio \
  com.usebottles.bottles \
  org.telegram.desktop \
  page.tesk.Refine

# ========== 2.4 内核更换 ==========
log_info "安装 XanMod 内核..."
wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list
nala update
nala install -y linux-xanmod-x64v3

# ========== 2.5 电源管理优化 (可选) ==========
if ask_yes_no "是否安装 auto-cpufreq 电源管理工具?"; then
    log_info "安装 auto-cpufreq..."
    cd /tmp
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq
    ./auto-cpufreq-installer
    auto-cpufreq --install
    cd /tmp
    rm -rf auto-cpufreq
fi

# ========== 2.6 zram ==========
log_info "配置 zram..."
nala install -y zram-tools
log_info "请手动编辑 /etc/default/zramswap 配置文件"

# ========== 3.1 Docker (可选) ==========
if ask_yes_no "是否安装 Docker?"; then
    log_info "配置 Docker 源..."
    nala update
    nala install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    tee /etc/apt/sources.list.d/docker.sources << 'EOF'
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: bookworm
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    nala update

    log_info "安装 Docker..."
    nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
    usermod -aG docker $REAL_USER

    log_info "配置 Docker 镜像源..."
    mkdir -p /etc/docker
    mkdir -p /home/docker
    tee /etc/docker/daemon.json << 'EOF'
{
  "data-root": "/home/docker",
  "registry-mirrors": [
    "https://docker.xuanyuan.me",
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com",
    "https://hub.rat.dev"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

    systemctl daemon-reload
    systemctl restart docker
    log_info "Docker 安装完成，请重新登录以使用户组生效"
fi

# ========== 4.1 systemd 优化 ==========
log_info "启用 systemd 服务..."
systemctl enable --now fstrim.timer
systemctl enable --now thermald

# ========== 4.2 内核参数优化 ==========
log_info "优化内核参数..."
tee -a /etc/sysctl.conf << 'EOF'

# Virtual Memory
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Network Core
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# TCP Optimization
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv6.conf.all.accept_ra = 2
EOF

sysctl -p

log_info "=========================================="
log_info "配置完成！"
log_info "=========================================="
log_info "建议执行以下操作："
log_info "1. 编辑 /etc/default/zramswap 配置 zram"
log_info "2. 重启系统以应用所有更改"
log_info "3. 如果安装了 Docker，重新登录以使用户组生效"
log_info "=========================================="
