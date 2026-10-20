#!/bin/bash
# 把 src/ 下的目录重新打包到 dist/（改完源码后跑这个）
# 用法：
#   ./pack.sh              # 全部重打
#   ./pack.sh php-5.6.12   # 只打一个
set -e
cd "$(dirname "$0")"

mkdir -p dist

zip_dir() {   # $1=src 下的目录名  $2=输出的 zip 文件
    python3 - "$1" "$2" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
if os.path.exists(out):
    os.remove(out)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for root, dirs, files in os.walk(os.path.join("src", src)):
        dirs.sort()
        for name in sorted(files):
            full = os.path.join(root, name)
            # 包内不带顶层目录：conf.zip 里应该是 BRftp、my.cnf 这一级
            z.write(full, os.path.relpath(full, os.path.join("src", src)))
PY
}

pack_one() {
    name="$1"

    # 直接放在 src/ 下的源码包（体积大的新版本，不展开，原样带过去）
    if [ -f "src/$name.tar.gz" ]; then
        echo "  复制 src/$name.tar.gz → dist/$name.tar.gz"
        cp -f "src/$name.tar.gz" "dist/$name.tar.gz"
        return
    fi

    [ -d "src/$name" ] || { echo "  跳过（无此目录）: $name"; return; }

    case "$name" in
        conf.bf)
            echo "  打包 src/$name → dist/conf.zip.bf"
            zip_dir "$name" "dist/conf.zip.bf"
            ;;
        conf)
            echo "  打包 src/$name → dist/conf.zip"
            zip_dir "$name" "dist/conf.zip"
            ;;
        *)
            echo "  打包 src/$name → dist/$name.tar.gz"
            rm -f "dist/$name.tar.gz"
            tar -czf "dist/$name.tar.gz" -C src "$name"
            ;;
    esac
}

if [ $# -gt 0 ]; then
    for one in "$@"; do pack_one "$one"; done
else
    for d in src/*/; do
        [ -d "$d" ] || continue
        pack_one "$(basename "$d")"
    done
    for f in src/*.tar.gz; do
        [ -f "$f" ] || continue
        b=$(basename "$f" .tar.gz)
        [ -d "src/$b" ] && continue
        pack_one "$b"
    done
fi

# 校验和
cd dist
sha256sum *.tar.gz *.zip *.zip.bf 2>/dev/null > SHA256SUMS
cd ..

echo
echo "  产物："
ls -lh dist | tail -n +2 | awk '{printf "    %-32s %s\n", $9, $5}'
