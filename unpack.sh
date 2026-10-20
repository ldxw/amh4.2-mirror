#!/bin/bash
# 把 dist/ 里的原始包解成 src/<目录名>/，之后改完用 pack.sh 重新打包
set -e
cd "$(dirname "$0")"

mkdir -p src dist

# 已经在根目录的原始包先挪进 dist/
for f in *.tar.gz *.zip *.zip.bf sha256sums SHA256SUMS; do
    [ -e "$f" ] || continue
    [ "$f" = "SHA256SUMS" ] && continue
    mv -f "$f" dist/ 2>/dev/null || true
done

for f in dist/*.tar.gz; do
    [ -e "$f" ] || continue
    name=$(basename "$f" .tar.gz)
    if [ -d "src/$name" ]; then
        echo "  跳过（已解压）: $name"
        continue
    fi
    echo "  解压 $f → src/$name"
    mkdir -p "src/$name"
    tar -xzf "$f" -C "src/$name" --strip-components=1
done

for f in dist/*.zip dist/*.zip.bf; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    name=${base%.zip.bf}
    name=${name%.zip}
    [ "${base%.bf}" != "$base" ] && name="$name.bf"
    if [ -d "src/$name" ]; then
        echo "  跳过（已解压）: $name"
        continue
    fi
    echo "  解压 $f → src/$name"
    mkdir -p "src/$name"
    python3 - "$f" "src/$name" <<'PY'
import sys, zipfile
zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])
PY
done

echo
echo "  解压完成："
du -sh src | sed 's/^/    src 合计: /'
ls -1 src | sed 's/^/    /'
