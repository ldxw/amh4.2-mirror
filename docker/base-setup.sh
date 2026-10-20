#!/bin/bash
# 容器启动脚本：准备好 apt 源和基础工具，然后挂住等你去装 AMH
# 现代 Debian/Ubuntu 用官方源；Debian 7/8 这种已下线的自动切 archive 源
set -u

. /etc/os-release 2>/dev/null || true

echo "[setup] 系统: ${PRETTY_NAME:-unknown} (${ID:-?} ${VERSION_ID:-?})"

# ---------- apt 源 ----------
if [ "${ID:-}" = "debian" ]; then
    case "${VERSION_ID:-}" in
        7|7.*|8|8.*)
            echo "[setup] 老版本 Debian，切换到 archive.debian.org（签名已过期，用 trusted=yes）"
            cat > /etc/apt/sources.list <<EOF
deb [trusted=yes] http://archive.debian.org/debian ${VERSION_ID%%.*} main contrib non-free
deb [trusted=yes] http://archive.debian.org/debian-security ${VERSION_ID%%.*}/updates main contrib non-free
EOF
            cat > /etc/apt/apt.conf.d/99archive <<'EOF'
Acquire::Check-Valid-Until "false";
Acquire::AllowInsecureRepositories "true";
Acquire::Retries "3";
EOF
            ;;
        *)
            echo "[setup] 使用官方源（deb.debian.org）"
            cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian ${VERSION_CODENAME:-bookworm} main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${VERSION_CODENAME:-bookworm}-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${VERSION_CODENAME:-bookworm}-security main contrib non-free non-free-firmware
EOF
            ;;
    esac
elif [ "${ID:-}" = "ubuntu" ]; then
    echo "[setup] 使用官方源（archive.ubuntu.com）"
    cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME:-jammy} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${VERSION_CODENAME:-jammy}-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu ${VERSION_CODENAME:-jammy}-security main restricted universe multiverse
EOF
fi

echo "[setup] apt-get update"
apt-get update || echo "[setup] update 有报错，继续"

echo "[setup] 安装基础工具"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --allow-unauthenticated \
    net-tools wget curl unzip bzip2 ca-certificates vim-tiny less procps \
    || echo "[setup] 部分包安装失败，继续（amh.sh 里还会再装一遍）"

if apt-cache policy gcc 2>/dev/null | grep -q 'Candidate: [0-9]'; then
    echo "[setup] 软件源可用，gcc 候选版本: $(apt-cache policy gcc | awk '/Candidate/{print $2}')"
else
    echo "[setup][错误] 软件源不可用（查不到 gcc 候选版本），请把上面的 apt 输出发出来"
fi

chmod +x /root/amh.sh 2>/dev/null || true

cat <<'EOF'

================ 使用说明 ================
进入容器：
  docker exec -it amh-test bash

安装 AMH：
  cd /root
  bash amh.sh

安装时会先让你选包版本（回车 = 最新构建）。
面板端口 8888，站点 80。
=========================================

EOF

exec tail -f /dev/null
