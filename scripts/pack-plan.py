#!/usr/bin/env python3
"""比较 src/ 每个目录的内容哈希，判断哪些包需要重新打包。

输出 JSON：
  {"dirs": [...], "files": [...], "amh_sh": true/false}

同时把最新的哈希表写回 manifest.json（只含本次算出的，上传到 Release 作为下次比较的基线）。
"""

import hashlib
import json
import os
import sys


def tree_hash(path):
    h = hashlib.sha256()
    for root, dirs, files in os.walk(path):
        dirs.sort()
        for name in sorted(files):
            full = os.path.join(root, name)
            h.update(os.path.relpath(full, path).encode())
            h.update(b"\0")
            with open(full, "rb") as fh:
                for chunk in iter(lambda: fh.read(1 << 20), b""):
                    h.update(chunk)
            h.update(b"\0")
    return h.hexdigest()


def output_name(name):
    if name == "conf":
        return "conf.zip"
    if name == "conf.bf":
        return "conf.zip.bf"
    return name + ".tar.gz"


manifest = {}
if os.path.exists("manifest.json"):
    try:
        manifest = json.load(open("manifest.json", encoding="utf-8"))
    except Exception:
        manifest = {}

current, changed_dirs, files = {}, [], []

for name in sorted(os.listdir("src")):
    path = os.path.join("src", name)

    if os.path.isdir(path):
        h = tree_hash(path)
    elif name.endswith(".tar.gz") and os.path.isfile(path):
        # 直接存放的源码包（大版本源码不展开）
        digest = hashlib.sha256()
        with open(path, "rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b""):
                digest.update(chunk)
        name = name[:-len(".tar.gz")]
        h = digest.hexdigest()
    else:
        continue

    current[name] = h
    if manifest.get(name) != h:
        changed_dirs.append(name)
        files.append("dist/" + output_name(name))

amh_hash = ""
if os.path.exists("amh.sh"):
    with open("amh.sh", "rb") as fh:
        amh_hash = hashlib.sha256(fh.read()).hexdigest()
current["__amh.sh__"] = amh_hash

# 打包逻辑（pack.sh / 本脚本）变了，说明产出格式可能变，全部重打
packer = hashlib.sha256()
for one in ("pack.sh", "scripts/pack-plan.py"):
    if os.path.exists(one):
        with open(one, "rb") as fh:
            packer.update(fh.read())
current["__packer__"] = packer.hexdigest()

if manifest.get("__packer__") not in (None, current["__packer__"]):
    # 第一次运行没有基线，不算变更；有基线且不同则全部重打
    changed_dirs = [n for n in sorted(current) if not n.startswith("__")]
    files = ["dist/" + output_name(n) for n in changed_dirs]

amh_changed = manifest.get("__amh.sh__") != amh_hash
if amh_changed:
    files.append("amh.sh")

json.dump(current, open("manifest.json", "w", encoding="utf-8"), indent=2, sort_keys=True)

json.dump({"dirs": changed_dirs, "files": files, "amh_sh": amh_changed}, sys.stdout)
print()
