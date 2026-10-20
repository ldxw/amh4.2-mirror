#!/bin/bash
# 下载 PHP 7.1~8.5 / nginx 1.24~1.28 / MySQL 5.6~8.0 / OpenSSL 1.1.1w 源码到 src/
set -u
cd /opt/data/projects/amh4.5 || exit 1
mkdir -p src

dl() {   # $1=url  $2=目标文件名
	local url="$1" out="src/$2"
	if [ -s "$out" ] && tar -tzf "$out" >/dev/null 2>&1; then
		echo "[skip] $2"
		return 0
	fi
	echo "[get ] $2"
	curl -sL --max-time 900 --retry 3 --retry-delay 3 "$url" -o "$out.part" || { echo "[fail] $2"; rm -f "$out.part"; return 1; }
	tar -tzf "$out.part" >/dev/null 2>&1 || { echo "[bad ] $2"; rm -f "$out.part"; return 1; }
	mv "$out.part" "$out"
}

if [ "${1:-}" = "large" ]; then
	# 超过 GitHub 单文件 100MB 限制的源码包不入库，构建时现拉
	dl "https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.43.tar.gz" "mysql-8.0.43.tar.gz"
	echo "=== 完成 ==="
	exit 0
fi

for v in 7.1.33 7.2.34 7.3.33 7.4.33 8.0.30 8.1.34 8.2.34 8.3.35 8.4.26 8.5.11; do
	dl "https://www.php.net/distributions/php-$v.tar.gz" "php-$v.tar.gz"
done

for v in 1.24.0 1.26.3 1.28.3; do
	dl "https://nginx.org/download/nginx-$v.tar.gz" "nginx-$v.tar.gz"
done

dl "https://www.openssl.org/source/openssl-1.1.1w.tar.gz" "openssl-1.1.1w.tar.gz"

dl "https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.51.tar.gz" "mysql-5.6.51.tar.gz"
dl "https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.44.tar.gz" "mysql-5.7.44.tar.gz"
dl "https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.43.tar.gz" "mysql-8.0.43.tar.gz"

echo "=== 完成 ==="
ls -lh src/*.tar.gz | awk '{print $5, $9}'
