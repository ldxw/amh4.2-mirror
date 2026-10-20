#!/bin/bash
# 容器启动脚本：把失效的 Debian 源换成 archive 源，装好安装脚本需要的基础工具，然后挂住
set -u

echo "[setup] 换用 archive.debian.org 源（jessie）"
cat > /etc/apt/sources.list <<'EOF'
deb http://archive.debian.org/debian jessie main contrib non-free
deb http://archive.debian.org/debian jessie-updates main contrib non-free
deb http://archive.debian.org/debian-security jessie/updates main contrib non-free
EOF

# 老源签名/有效期检查统统跳过
echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-valid-until
echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/99retries

echo "[setup] apt-get update"
apt-get update || echo "[setup] update 有报错，继续"

echo "[setup] 安装基础工具"
DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes \
    net-tools wget curl unzip bzip2 ca-certificates vim-tiny less procps \
    || echo "[setup] 部分包安装失败，继续（安装脚本自己还会装一遍）"

chmod +x /root/amh.sh 2>/dev/null || true

echo
echo "[setup] 容器的系统信息："
cat /etc/issue 2>/dev/null
uname -m

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

# 挂住不退出
exec tail -f /dev/null
